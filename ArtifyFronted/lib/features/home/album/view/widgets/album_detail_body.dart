import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/artist/view/pages/artist_detail_page.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/section_card.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/song/view/widgets/queue_swipe_wrapper.dart';
import 'package:client/features/home/song/view/widgets/song_playback_actions.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final albumPlayableSongsProvider =
    FutureProvider.family<List<SongModel>, String>((ref, albumId) async {
  final album = await ref.watch(getAlbumProvider(albumId).future);
  if (album.tracks.isEmpty) return const <SongModel>[];

  final songs = <SongModel>[];
  for (final track in album.tracks) {
    try {
      final song = await ref.read(getSongProvider(track.songId).future);
      songs.add(song);
    } catch (error, stackTrace) {
      debugPrint(
        '[AlbumDetailBody] Unable to resolve song ${track.songId}: '
        '$error\n$stackTrace',
      );
    }
  }

  return songs;
});

class AlbumDetailBody extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailBody({
    super.key,
    required this.albumId,
  });

  @override
  ConsumerState<AlbumDetailBody> createState() => _AlbumDetailBodyState();
}

class _AlbumDetailBodyState extends ConsumerState<AlbumDetailBody> {
  bool _didMarkAlbumOpened = false;
  bool _isPlayingAlbum = false;

  Future<List<SongModel>> _loadPlayableSongs(AlbumModel album) async {
    final songs = await ref.read(albumPlayableSongsProvider(album.id).future);
    if (songs.isEmpty) {
      throw Exception('No playable tracks are available for this release yet.');
    }
    return songs;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAlbumOpened(AlbumModel album) {
    if (_didMarkAlbumOpened) return;
    _didMarkAlbumOpened = true;
    Future.microtask(
      () => ref.read(albumViewModelProvider.notifier).markAlbumOpened(album),
    );
  }

  Future<void> _playAlbum(
    AlbumModel album, {
    String? startSongId,
  }) async {
    if (_isPlayingAlbum) return;

    setState(() => _isPlayingAlbum = true);

    try {
      final songs = await _loadPlayableSongs(album);
      final startIndex = startSongId == null
          ? 0
          : songs.indexWhere((song) => song.id == startSongId);

      await playSongsFromSource(
        ref: ref,
        songs: songs,
        startIndex: startIndex >= 0 ? startIndex : 0,
        sourceType: PlaybackSourceType.album,
        sourceId: album.id,
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isPlayingAlbum = false);
      }
    }
  }

  Future<void> _playTrack(
    AlbumModel album,
    AlbumTrack track,
  ) async {
    try {
      final songs = await _loadPlayableSongs(album);
      final resolvedIndex = songs.indexWhere((song) => song.id == track.songId);

      if (resolvedIndex >= 0) {
        await playSongsFromSource(
          ref: ref,
          songs: songs,
          startIndex: resolvedIndex,
          sourceType: PlaybackSourceType.album,
          sourceId: album.id,
        );
        return;
      }

      final song = await ref.read(getSongProvider(track.songId).future);
      await playSingleSongNow(
        ref: ref,
        song: song,
        sourceType: PlaybackSourceType.album,
        sourceId: album.id,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openTrackActions(
    AlbumModel album,
    AlbumTrack track,
    SongModel? resolvedSong,
  ) async {
    try {
      final songs = await _loadPlayableSongs(album);
      SongModel? selectedSong = resolvedSong ??
          songs.cast<SongModel?>().firstWhere(
                (candidate) => candidate?.id == track.songId,
                orElse: () => null,
              );
      selectedSong ??= await ref.read(getSongProvider(track.songId).future);
      final song = selectedSong!;

      final startIndex =
          songs.indexWhere((candidate) => candidate.id == song.id);

      if (!mounted) return;

      await showSongPlaybackActionsSheet(
        context: context,
        ref: ref,
        song: song,
        contextSongs: songs.isNotEmpty ? songs : null,
        startIndex: startIndex >= 0 ? startIndex : null,
        sourceType: PlaybackSourceType.album,
        sourceId: album.id,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _queueTrack(
    AlbumModel album,
    AlbumTrack track,
    SongModel? resolvedSong,
  ) async {
    final SongModel song =
        resolvedSong ?? await ref.read(getSongProvider(track.songId).future);

    await ref.read(playbackQueueControllerProvider.notifier).addToQueue(
          song,
          sourceType: PlaybackSourceType.album,
          sourceId: album.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final albumAsync = ref.watch(getAlbumProvider(widget.albumId));
    final playableSongsAsync =
        ref.watch(albumPlayableSongsProvider(widget.albumId));
    final currentSongState = ref.watch(currentSongNotifierProvider);
    final currentSong = currentSongState.song;

    return albumAsync.when(
      data: (album) {
        _markAlbumOpened(album);

        final playableSongs =
            playableSongsAsync.asData?.value ?? const <SongModel>[];
        final songById = {
          for (final song in playableSongs) song.id: song,
        };

        final totalDurationSeconds = playableSongs.fold<int>(
          0,
          (sum, song) => sum + (song.durationSeconds ?? 0),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlbumHeroCard(
                album: album,
                playableSongs: playableSongs,
                playableTracksLoading: playableSongsAsync.isLoading,
                totalDurationLabel: _formatTotalDuration(totalDurationSeconds),
                onPlayAlbum: () => _playAlbum(album),
                onResumeCurrent: currentSong != null &&
                        playableSongs.any((song) => song.id == currentSong.id)
                    ? () => _playAlbum(
                          album,
                          startSongId: currentSong.id,
                        )
                    : null,
                isBusy: _isPlayingAlbum,
              ),
              const SizedBox(height: 26),
              if (album.artists.isNotEmpty) ...[
                const SectionTitle('Artists on this release'),
                const SizedBox(height: 12),
                SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: album.artists.map((artist) {
                      final label =
                          artist.artistDisplayName?.trim().isNotEmpty == true
                              ? artist.artistDisplayName!.trim()
                              : artist.artistName;

                      return _ArtistChip(
                        label: label,
                        role: artist.role.name,
                        imageUrl: artist.artistImageUrl,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArtistDetailPage(artistId: artist.artistId),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 26),
              ],
              const SectionTitle('Tracklist'),
              const SizedBox(height: 12),
              if (playableSongsAsync.isLoading && album.tracks.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _LoadingPlaybackBanner(),
                ),
              if (album.tracks.isEmpty)
                const SectionPlaceholder(
                  title: 'No tracks in this release',
                  subtitle:
                      'The album exists, but its tracklist is still empty.',
                  icon: Icons.library_music_outlined,
                )
              else
                SectionCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: album.tracks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final track = entry.value;
                      final song = songById[track.songId];
                      final isCurrent = currentSong?.id == track.songId;
                      final isLast = index == album.tracks.length - 1;

                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                        child: QueueSwipeWrapper(
                          swipeKey: ValueKey(
                            'album-${album.id}-${track.songId}-${track.trackNumber ?? index}',
                          ),
                          successMessage:
                              'Added "${song?.songName ?? track.songName ?? 'Track ${track.trackNumber ?? index + 1}'}" to queue',
                          onQueue: () => _queueTrack(album, track, song),
                          child: _AlbumTrackRow(
                            index: track.trackNumber ?? index + 1,
                            album: album,
                            track: track,
                            song: song,
                            isCurrent: isCurrent,
                            onTap: () => _playTrack(album, track),
                            onMore: () => _openTrackActions(album, track, song),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 26),
              const SectionTitle('Release details'),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaFact(
                          label: 'Type',
                          value: _albumTypeLabel(album.albumType),
                        ),
                        _MetaFact(
                          label: 'Released',
                          value: _releaseDateLabel(album.releaseDate),
                        ),
                        _MetaFact(
                          label: 'Tracks',
                          value: '${album.totalTracks}',
                        ),
                        if (totalDurationSeconds > 0)
                          _MetaFact(
                            label: 'Duration',
                            value: _formatTotalDuration(totalDurationSeconds),
                          ),
                        if ((album.genre ?? '').trim().isNotEmpty)
                          _MetaFact(
                            label: 'Genre',
                            value: album.genre!.trim(),
                          ),
                        if ((album.label ?? '').trim().isNotEmpty)
                          _MetaFact(
                            label: 'Label',
                            value: album.label!.trim(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _releaseNarrative(
                        album: album,
                        playableCount: playableSongs.length,
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SectionPlaceholder(
            title: 'Unable to load album',
            subtitle: error.toString(),
            icon: Icons.error_outline_rounded,
          ),
        ),
      ),
    );
  }
}

class _AlbumHeroCard extends StatelessWidget {
  final AlbumModel album;
  final List<SongModel> playableSongs;
  final bool playableTracksLoading;
  final String totalDurationLabel;
  final VoidCallback onPlayAlbum;
  final VoidCallback? onResumeCurrent;
  final bool isBusy;

  const _AlbumHeroCard({
    required this.album,
    required this.playableSongs,
    required this.playableTracksLoading,
    required this.totalDurationLabel,
    required this.onPlayAlbum,
    required this.onResumeCurrent,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final artistNames = album.artists
        .map(
          (artist) => artist.artistDisplayName?.trim().isNotEmpty == true
              ? artist.artistDisplayName!.trim()
              : artist.artistName,
        )
        .where((name) => name.trim().isNotEmpty)
        .toList();

    final releaseBits = <String>[
      _albumTypeLabel(album.albumType),
      if (album.releaseDate != null) '${album.releaseDate!.year}',
      '${album.totalTracks} track${album.totalTracks == 1 ? '' : 's'}',
      if (totalDurationLabel.isNotEmpty) totalDurationLabel,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF281A3B).withOpacity(0.96),
            const Color(0xFF121E33).withOpacity(0.92),
            const Color(0xFF09111C).withOpacity(0.88),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                label: _albumTypeLabel(album.albumType).toUpperCase(),
                background: const Color(0xFFFF8A70).withOpacity(0.16),
                foreground: Colors.white,
              ),
              if ((album.genre ?? '').trim().isNotEmpty)
                _HeroChip(
                  label: album.genre!.trim(),
                  background: Colors.white.withOpacity(0.08),
                  foreground: Colors.white70,
                ),
              _HeroChip(
                label: playableTracksLoading
                    ? 'Preparing playback'
                    : '${playableSongs.length} playable',
                background: const Color(0xFF56CCF2).withOpacity(0.14),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlbumCoverArt(
                coverUrl: album.coverUrl,
                size: 154,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      artistNames.isEmpty
                          ? 'Unknown artist'
                          : artistNames.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      releaseBits.join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PrimaryActionButton(
                          label: isBusy ? 'Loading...' : 'Play album',
                          icon: isBusy ? null : Icons.play_arrow_rounded,
                          onTap: isBusy ? null : onPlayAlbum,
                          filled: true,
                        ),
                        _PrimaryActionButton(
                          label: 'Resume here',
                          icon: Icons.library_music_rounded,
                          onTap: onResumeCurrent,
                          filled: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (playableTracksLoading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A70)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlbumTrackRow extends StatelessWidget {
  final int index;
  final AlbumModel album;
  final AlbumTrack track;
  final SongModel? song;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _AlbumTrackRow({
    required this.index,
    required this.album,
    required this.track,
    required this.song,
    required this.isCurrent,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final title = song?.songName ?? track.songName ?? 'Track $index';
    final subtitle = _trackSubtitle(song, album);

    return Material(
      color: isCurrent
          ? const Color(0xFF56CCF2).withOpacity(0.10)
          : Colors.white.withOpacity(0.035),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                alignment: Alignment.center,
                child: isCurrent
                    ? const Icon(
                        Icons.graphic_eq_rounded,
                        color: Color(0xFF56CCF2),
                        size: 18,
                      )
                    : Text(
                        '$index',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: song?.thumbnailUrl != null
                    ? Image.network(
                        song!.thumbnailUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF7C3AED),
                              Color(0xFF172033),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: isCurrent ? Colors.white : Colors.white,
                        fontSize: 13.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: isCurrent ? Colors.white70 : Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (song?.durationSeconds != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _formatTrackDuration(song!.durationSeconds!),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistChip extends StatelessWidget {
  final String label;
  final String role;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ArtistChip({
    required this.label,
    required this.role,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white.withOpacity(0.08),
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 15,
                        color: Colors.white70,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    role,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaybackBanner extends StatelessWidget {
  const _LoadingPlaybackBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Preparing every track so playback and queue actions work instantly.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaFact extends StatelessWidget {
  final String label;
  final String value;

  const _MetaFact({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumCoverArt extends StatelessWidget {
  final String? coverUrl;
  final double size;

  const _AlbumCoverArt({
    required this.coverUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: coverUrl != null
            ? Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AlbumCoverFallback(size: size),
              )
            : _AlbumCoverFallback(size: size),
      ),
    );
  }
}

class _AlbumCoverFallback extends StatelessWidget {
  final double size;

  const _AlbumCoverFallback({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF132033),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.album_rounded,
        color: Colors.white,
        size: 52,
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _HeroChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        filled ? const Color(0xFFFF8A70) : Colors.white.withOpacity(0.08);

    final foreground = onTap != null ? Colors.white : Colors.white38;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _trackSubtitle(SongModel? song, AlbumModel album) {
  final songArtists = song?.artists
          .map((artist) => artist.artistName)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .toList() ??
      const <String>[];

  if (songArtists.isNotEmpty) {
    return songArtists.join(', ');
  }

  final albumArtists = album.artists
      .map(
        (artist) => artist.artistDisplayName?.trim().isNotEmpty == true
            ? artist.artistDisplayName!.trim()
            : artist.artistName,
      )
      .where((name) => name.trim().isNotEmpty)
      .toList();

  if (albumArtists.isNotEmpty) {
    return albumArtists.join(', ');
  }

  return 'Unknown artist';
}

String _albumTypeLabel(String? type) {
  final clean = (type ?? 'album').trim();
  if (clean.isEmpty) return 'Album';
  return '${clean[0].toUpperCase()}${clean.substring(1)}';
}

String _releaseDateLabel(DateTime? date) {
  if (date == null) return 'Unscheduled';
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTrackDuration(int seconds) {
  final safeSeconds = seconds < 0 ? 0 : seconds;
  final minutes = safeSeconds ~/ 60;
  final remainingSeconds = safeSeconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

String _formatTotalDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '';

  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  return '$minutes min';
}

String _releaseNarrative({
  required AlbumModel album,
  required int playableCount,
}) {
  final artistNames = album.artists
      .map(
        (artist) => artist.artistDisplayName?.trim().isNotEmpty == true
            ? artist.artistDisplayName!.trim()
            : artist.artistName,
      )
      .where((name) => name.trim().isNotEmpty)
      .toList();

  final lead = artistNames.isEmpty
      ? album.title
      : '${album.title} by ${artistNames.join(', ')}';
  final type = _albumTypeLabel(album.albumType).toLowerCase();
  final release = _releaseDateLabel(album.releaseDate);
  final label = (album.label ?? '').trim();
  final genre = (album.genre ?? '').trim();

  final bits = <String>[
    '$lead is a $type released on $release.',
    'This release currently exposes ${album.totalTracks} track${album.totalTracks == 1 ? '' : 's'}, with $playableCount ready for instant playback inside Artify.',
    if (genre.isNotEmpty) 'The sonic lane points toward $genre.',
    if (label.isNotEmpty) 'Published under $label.',
  ];

  return bits.join(' ');
}
