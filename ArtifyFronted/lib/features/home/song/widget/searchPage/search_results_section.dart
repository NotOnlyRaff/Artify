import 'package:client/features/home/artist/view/pages/artist_detail_page.dart';
import 'package:client/features/home/album/view/pages/album_detail_page.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/song/view/widgets/queue_swipe_wrapper.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/song/widget/searchPage/search_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultsSection extends StatelessWidget {
  final List<SongModel> songs;
  final List<ArtistModel> artists;
  final List<AlbumModel> albums;
  final String query;
  final Future<void> Function(List<SongModel> songs, int index) onSongTap;
  final Future<void> Function(List<SongModel> songs, int index) onSongMoreTap;

  /// Filtro attivo. Quando != all, mostra solo la sezione corrispondente.
  final SearchFilter filter;

  /// Quante songs mostrare in modalità "All" prima di far apparire il
  /// bottone "Show more". Quando il filtro è songs, il limite è ignorato.
  final int songsCollapsedLimit;

  /// Se true, la sezione songs è stata espansa manualmente dall'utente.
  final bool songsExpanded;

  /// Callback per toggle dell'espansione.
  final VoidCallback onToggleSongsExpanded;

  const SearchResultsSection({
    super.key,
    required this.songs,
    required this.artists,
    required this.albums,
    required this.query,
    required this.onSongTap,
    required this.onSongMoreTap,
    this.filter = SearchFilter.all,
    this.songsCollapsedLimit = 5,
    this.songsExpanded = false,
    required this.onToggleSongsExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // SONGS: filtro locale su titolo + artisti
    final songMatches = songs.where((song) {
      final titleMatch = song.songName.toLowerCase().contains(q);
      final artistMatch = song.artists.any(
        (a) => a.artistName?.toLowerCase().contains(q) == true,
      );
      return titleMatch || artistMatch;
    }).toList();

    // ARTISTS
    final artistMatches = artists.where((artist) {
      final name = artist.name.toLowerCase();
      final display = (artist.displayName ?? '').toLowerCase();
      return name.contains(q) || display.contains(q);
    }).toList();

    // ALBUMS
    final albumMatches = albums.where((album) {
      final title = album.title.toLowerCase();
      final label = (album.label ?? '').toLowerCase();
      return title.contains(q) || label.contains(q);
    }).toList();

    // Visibilità per sezione in base al filtro.
    final showSongs =
        filter == SearchFilter.all || filter == SearchFilter.songs;
    final showArtists =
        filter == SearchFilter.all || filter == SearchFilter.artists;
    final showAlbums =
        filter == SearchFilter.all || filter == SearchFilter.albums;

    final hasAnyVisibleResult = (showSongs && songMatches.isNotEmpty) ||
        (showArtists && artistMatches.isNotEmpty) ||
        (showAlbums && albumMatches.isNotEmpty);

    if (!hasAnyVisibleResult) {
      return Center(
        child: Text(
          _noResultsMessage(),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    // Applica il limite solo quando siamo in modalità "All" e non espanso.
    // Se l'utente ha esplicitamente scelto il filtro Songs, mostriamo tutto.
    final applyLimit = filter == SearchFilter.all && !songsExpanded;
    final displayedSongs = applyLimit
        ? songMatches.take(songsCollapsedLimit).toList(growable: false)
        : songMatches;
    final hiddenSongs = (songMatches.length - displayedSongs.length)
        .clamp(0, songMatches.length);
    final canShowMoreSongs = applyLimit && hiddenSongs > 0;
    final canCollapseSongs = filter == SearchFilter.all &&
        songsExpanded &&
        songMatches.length > songsCollapsedLimit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        if (showSongs && songMatches.isNotEmpty) ...[
          _SectionTitle(
            'Songs',
            count: songMatches.length,
          ),
          const SizedBox(height: 8),
          ...displayedSongs.asMap().entries.map(
                (entry) => _SongResultTile(
                  song: entry.value,
                  index: entry.key,
                  query: query,
                  // Passo la lista INTERA (non quella tagliata) così i tap
                  // creano una queue coerente anche quando la UI è collapsed.
                  songMatches: songMatches,
                  onSongTap: onSongTap,
                  onSongMoreTap: onSongMoreTap,
                ),
              ),
          if (canShowMoreSongs)
            _ShowMoreButton(
              label:
                  'Show $hiddenSongs more song${hiddenSongs == 1 ? '' : 's'}',
              onTap: onToggleSongsExpanded,
              icon: Icons.expand_more_rounded,
            )
          else if (canCollapseSongs)
            _ShowMoreButton(
              label: 'Show less',
              onTap: onToggleSongsExpanded,
              icon: Icons.expand_less_rounded,
            ),
          const SizedBox(height: 24),
        ],
        if (showArtists && artistMatches.isNotEmpty) ...[
          _SectionTitle(
            'Artists',
            count: artistMatches.length,
          ),
          const SizedBox(height: 8),
          ...artistMatches.map((a) => _ArtistResultTile(artist: a)),
          const SizedBox(height: 24),
        ],
        if (showAlbums && albumMatches.isNotEmpty) ...[
          _SectionTitle(
            'Albums',
            count: albumMatches.length,
          ),
          const SizedBox(height: 8),
          ...albumMatches.map((a) => _AlbumResultTile(album: a)),
        ],
      ],
    );
  }

  String _noResultsMessage() {
    switch (filter) {
      case SearchFilter.songs:
        return 'No songs found for "$query".';
      case SearchFilter.artists:
        return 'No artists found for "$query".';
      case SearchFilter.albums:
        return 'No albums found for "$query".';
      case SearchFilter.all:
        return 'No results found for "$query".';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionTitle(this.label, {this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const _ShowMoreButton({
    required this.label,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SONG TILE -----------------------------------------------------------------
class _SongResultTile extends ConsumerWidget {
  final SongModel song;
  final int index;
  final String query;
  final List<SongModel> songMatches;
  final Future<void> Function(List<SongModel> songs, int index) onSongTap;
  final Future<void> Function(List<SongModel> songs, int index) onSongMoreTap;

  const _SongResultTile({
    required this.song,
    required this.index,
    required this.query,
    required this.songMatches,
    required this.onSongTap,
    required this.onSongMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = song.artists.isNotEmpty
        ? (song.artists.first.artistName ?? 'Unknown artist')
        : 'Unknown artist';

    return QueueSwipeWrapper(
      swipeKey: ValueKey('search-${song.id}-$index'),
      successMessage: 'Added "${song.songName}" to queue',
      onQueue: () =>
          ref.read(playbackQueueControllerProvider.notifier).addToQueue(
                song,
                sourceType: PlaybackSourceType.search,
                sourceId: query.trim().isEmpty ? null : query.trim(),
              ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSongTap(songMatches, index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: song.thumbnailUrl != null &&
                            song.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            song.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white10,
                              child: const Icon(
                                Icons.music_note_rounded,
                                size: 20,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 20,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white54,
                  ),
                  onPressed: () => onSongMoreTap(songMatches, index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ARTIST TILE ---------------------------------------------------------------
class _ArtistResultTile extends StatelessWidget {
  final ArtistModel artist;

  const _ArtistResultTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArtistDetailPage(artistId: artist.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white10,
                backgroundImage:
                    artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                        ? NetworkImage(artist.imageUrl!)
                        : null,
                child: (artist.imageUrl == null || artist.imageUrl!.isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white54,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.displayName ?? artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Artist',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ALBUM TILE ----------------------------------------------------------------
class _AlbumResultTile extends StatelessWidget {
  final AlbumModel album;

  const _AlbumResultTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailPage(albumId: album.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: album.coverUrl != null && album.coverUrl!.isNotEmpty
                      ? Image.network(
                          album.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.album_rounded,
                              size: 20,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.album_rounded,
                            size: 20,
                            color: Colors.white54,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.label?.isNotEmpty == true ? album.label! : 'Album',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
