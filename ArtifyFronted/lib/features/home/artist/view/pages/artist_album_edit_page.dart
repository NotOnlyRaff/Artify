import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistAlbumEditPage extends ConsumerStatefulWidget {
  final ArtistModel studioArtist;
  final String albumId;

  const ArtistAlbumEditPage({
    super.key,
    required this.studioArtist,
    required this.albumId,
  });

  @override
  ConsumerState<ArtistAlbumEditPage> createState() =>
      _ArtistAlbumEditPageState();
}

class _ArtistAlbumEditPageState extends ConsumerState<ArtistAlbumEditPage> {
  final _titleController = TextEditingController();
  final _labelController = TextEditingController();
  final _genreController = TextEditingController();
  final _artistSearchController = TextEditingController();
  final _trackSearchController = TextEditingController();

  final List<ArtistModel> _selectedAlbumArtists = [];
  final List<_EditableAlbumTrack> _tracks = [];

  final List<String> _albumTypeValues = const [
    'album',
    'single',
    'ep',
    'compilation',
  ];

  PickedMedia? _selectedCover;
  DateTime? _releaseDate;
  String? _selectedAlbumType = 'album';
  bool _seeded = false;
  bool _saving = false;

  String _artistSearchQuery = '';
  String _trackSearchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _labelController.dispose();
    _genreController.dispose();
    _artistSearchController.dispose();
    _trackSearchController.dispose();
    super.dispose();
  }

  void _seedAlbum(AlbumModel album) {
    if (_seeded) return;

    _titleController.text = album.title;
    _labelController.text = album.label ?? '';
    _genreController.text = album.genre ?? '';
    _releaseDate = album.releaseDate;
    _selectedAlbumType = album.albumType ?? 'album';

    final albumArtists = album.artists
        .map(
          (artist) => ArtistModel(
            id: artist.artistId,
            name: artist.artistName,
            displayName: artist.artistDisplayName,
            imageUrl: artist.artistImageUrl,
          ),
        )
        .toList(growable: false);

    _selectedAlbumArtists
      ..clear()
      ..addAll(albumArtists);

    if (!_selectedAlbumArtists
        .any((artist) => artist.id == widget.studioArtist.id)) {
      _selectedAlbumArtists.insert(0, widget.studioArtist);
    }

    _tracks
      ..clear()
      ..addAll(
        (album.tracks.toList(growable: false)
              ..sort(
                  (a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0)))
            .map(_EditableAlbumTrack.fromAlbumTrack),
      );

    _seeded = true;
  }

  Future<void> _pickCover() async {
    final picked = await pickImage();
    if (picked != null && mounted) {
      setState(() => _selectedCover = picked);
    }
  }

  Future<void> _pickReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() => _releaseDate = picked);
    }
  }

  void _addArtist(ArtistModel artist) {
    if (_selectedAlbumArtists.any((item) => item.id == artist.id)) return;
    setState(() => _selectedAlbumArtists.add(artist));
  }

  void _removeArtist(ArtistModel artist) {
    if (artist.id == widget.studioArtist.id) return;
    setState(() {
      _selectedAlbumArtists.removeWhere((item) => item.id == artist.id);
    });
  }

  void _addTrack(ArtistSongRef song) {
    if (_tracks.any((track) => track.songId == song.songId)) return;
    setState(() => _tracks.add(_EditableAlbumTrack.fromArtistSongRef(song)));
  }

  void _removeTrack(_EditableAlbumTrack track) {
    setState(() {
      _tracks.removeWhere((item) => item.songId == track.songId);
    });
  }

  void _moveTrack(int from, int to) {
    setState(() {
      final item = _tracks.removeAt(from);
      _tracks.insert(to, item);
    });
  }

  String _artistLabel(ArtistModel artist) {
    return artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _displayAlbumType(String value) {
    switch (value) {
      case 'album':
        return 'Album';
      case 'single':
        return 'Single';
      case 'ep':
        return 'EP';
      case 'compilation':
        return 'Compilation';
      default:
        return value;
    }
  }

  Future<void> _save(AlbumModel album) async {
    if (_titleController.text.trim().isEmpty) {
      showSnackBar(context, 'Album title is required.');
      return;
    }
    if (_releaseDate == null) {
      showSnackBar(context, 'Release date is required.');
      return;
    }
    if (_tracks.isEmpty) {
      showSnackBar(context, 'Add at least one track to the album.');
      return;
    }

    setState(() => _saving = true);

    try {
      String? coverUrl = album.coverUrl;
      if (_selectedCover != null) {
        final uploadRes =
            await ref.read(albumViewModelProvider.notifier).uploadAlbumCover(
                  cover: _selectedCover!,
                );

        switch (uploadRes) {
          case Left(value: final failure):
            if (!mounted) return;
            showSnackBar(context, failure.message);
            return;
          case Right(value: final uploadedUrl):
            coverUrl = uploadedUrl;
        }
      }

      final artistIds = <String>[
        widget.studioArtist.id,
        ..._selectedAlbumArtists
            .where((artist) => artist.id != widget.studioArtist.id)
            .map((artist) => artist.id),
      ];

      await ref.read(albumViewModelProvider.notifier).updateAlbum(
            albumId: widget.albumId,
            title: _titleController.text.trim(),
            releaseDate: _releaseDate,
            label: _emptyToNull(_labelController.text),
            albumType: _selectedAlbumType,
            genre: _emptyToNull(_genreController.text),
            coverUrl: coverUrl,
            artistIds: artistIds,
            songIds:
                _tracks.map((track) => track.songId).toList(growable: false),
          );

      final state = ref.read(albumViewModelProvider);
      if (state?.hasError == true) {
        if (!mounted) return;
        showSnackBar(context, state!.error.toString());
        return;
      }

      ref.invalidate(getArtistProvider(widget.studioArtist.id));
      ref.invalidate(getAlbumProvider(widget.albumId));
      ref.invalidate(getAllAlbumsProvider);
      ref.invalidate(getAllSongsProvider);

      if (!mounted) return;
      showSnackBar(context, 'Album updated successfully.');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumAsync = ref.watch(getAlbumProvider(widget.albumId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Edit Album',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050509),
              Color(0xFF140813),
            ],
          ),
        ),
        child: albumAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          data: (album) {
            _seedAlbum(album);

            final enableArtistSearch = _artistSearchQuery.trim().length >= 2;
            final artistResults = enableArtistSearch
                ? ref.watch(
                    getArtistsProvider(search: _artistSearchQuery.trim()))
                : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

            final filteredLibrarySongs = widget.studioArtist.songs
                .where((song) {
                  final query = _trackSearchQuery.trim().toLowerCase();
                  final matchesQuery = query.isEmpty ||
                      (song.songName?.toLowerCase().contains(query) ?? false);
                  final alreadySelected =
                      _tracks.any((track) => track.songId == song.songId);
                  return matchesQuery && !alreadySelected;
                })
                .take(10)
                .toList(growable: false);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StudioHeroCard(
                        icon: Icons.edit_rounded,
                        title: 'Shape the final album',
                        subtitle:
                            'Adjust metadata, refresh cover art and save the exact track order that should appear in the release.',
                      ),
                      const SizedBox(height: 20),
                      StudioMetricsStrip(
                        metrics: [
                          StudioMetricData(
                            label: 'Tracks in album',
                            value: '${_tracks.length}',
                            icon: Icons.queue_music_rounded,
                            accentColor: const Color(0xFF8B5CF6),
                          ),
                          StudioMetricData(
                            label: 'Album artists',
                            value: '${_selectedAlbumArtists.length}',
                            icon: Icons.group_rounded,
                            accentColor: Pallete.accentCyan,
                          ),
                          StudioMetricData(
                            label: 'Cover',
                            value: _selectedCover != null
                                ? 'Updated'
                                : (album.coverUrl?.isNotEmpty == true
                                    ? 'Live'
                                    : 'Missing'),
                            icon: Icons.image_rounded,
                            accentColor: const Color(0xFFF97316),
                          ),
                          StudioMetricData(
                            label: 'Release date',
                            value: _releaseDate == null ? 'Missing' : 'Set',
                            icon: Icons.event_available_rounded,
                            accentColor: const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StudioSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StudioSectionTitle('Album identity'),
                            const SizedBox(height: 10),
                            const StudioInfoCallout(
                              title: 'Cover changes are safe here',
                              body:
                                  'If you pick a new cover it is uploaded first, then the album metadata is patched with the new asset URL.',
                            ),
                            const SizedBox(height: 16),
                            _AlbumEditAdaptivePair(
                              left: StudioMediaPickerCard(
                                label: 'Album cover',
                                value: _selectedCover?.name ?? album.coverUrl,
                                icon: Icons.image_outlined,
                                buttonText: 'Select cover',
                                onTap: _pickCover,
                                preview: album.coverUrl?.isNotEmpty == true
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          album.coverUrl!,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : null,
                              ),
                              right: Column(
                                children: [
                                  StudioTextField(
                                    controller: _titleController,
                                    label: 'Album title',
                                    hint: 'Give this release a name',
                                    icon: Icons.album_rounded,
                                  ),
                                  const SizedBox(height: 14),
                                  StudioDateField(
                                    label: 'Release date',
                                    value: _releaseDate,
                                    onPick: _pickReleaseDate,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Album artists',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedAlbumArtists
                                  .map(
                                    (artist) => _AlbumArtistChip(
                                      label: _artistLabel(artist),
                                      locked:
                                          artist.id == widget.studioArtist.id,
                                      onRemove:
                                          artist.id == widget.studioArtist.id
                                              ? null
                                              : () => _removeArtist(artist),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 16),
                            StudioTextField(
                              controller: _artistSearchController,
                              label: 'Search album artists',
                              hint: 'Search artist by name',
                              icon: Icons.person_search_rounded,
                              onChanged: (value) {
                                setState(() => _artistSearchQuery = value);
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              enableArtistSearch
                                  ? 'Search the catalog to add more artists to the album credits.'
                                  : 'Type at least 2 characters to search artists.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            if (enableArtistSearch) ...[
                              const SizedBox(height: 10),
                              artistResults.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                error: (error, _) => Text(
                                  error.toString(),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                data: (artists) {
                                  final candidates = artists.where((artist) {
                                    return !_selectedAlbumArtists
                                        .any((item) => item.id == artist.id);
                                  }).toList(growable: false);

                                  if (candidates.isEmpty) {
                                    return Text(
                                      'No artists found for "${_artistSearchQuery.trim()}".',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white54,
                                        fontSize: 12.5,
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: candidates
                                        .map(
                                          (artist) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              backgroundImage:
                                                  artist.imageUrl != null &&
                                                          artist.imageUrl!
                                                              .isNotEmpty
                                                      ? NetworkImage(
                                                          artist.imageUrl!)
                                                      : null,
                                              child: artist.imageUrl == null ||
                                                      artist.imageUrl!.isEmpty
                                                  ? Text(
                                                      _artistLabel(artist)
                                                          .characters
                                                          .first
                                                          .toUpperCase(),
                                                    )
                                                  : null,
                                            ),
                                            title: Text(
                                              _artistLabel(artist),
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: artist.slug == null
                                                ? null
                                                : Text(
                                                    '@${artist.slug}',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                            trailing: OutlinedButton(
                                              onPressed: () =>
                                                  _addArtist(artist),
                                              child: const Text('Add'),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      StudioSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const StudioSectionTitle('Tracklist'),
                                const Spacer(),
                                Text(
                                  '${_tracks.length} track${_tracks.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const StudioInfoCallout(
                              title: 'Order is saved exactly as shown',
                              body:
                                  'Drag tracks to the right position before saving. The album update now persists the final ordering in the backend.',
                            ),
                            const SizedBox(height: 16),
                            if (_tracks.isEmpty)
                              Text(
                                'No tracks linked yet.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              )
                            else
                              ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _tracks.length,
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  _moveTrack(oldIndex, newIndex);
                                },
                                itemBuilder: (context, index) {
                                  final track = _tracks[index];
                                  return Container(
                                    key: ValueKey(track.songId),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(
                                        color: index == 0
                                            ? const Color(0xFF8B5CF6)
                                                .withOpacity(0.55)
                                            : Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          (index + 1)
                                              .toString()
                                              .padLeft(2, '0'),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            image: track.thumbnailUrl
                                                        ?.isNotEmpty ==
                                                    true
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        track.thumbnailUrl!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                            color:
                                                Colors.white.withOpacity(0.05),
                                          ),
                                          child:
                                              track.thumbnailUrl?.isNotEmpty ==
                                                      true
                                                  ? null
                                                  : const Icon(
                                                      Icons.music_note_rounded,
                                                      color: Colors.white70,
                                                    ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                track.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                index == 0
                                                    ? 'Opening position'
                                                    : 'Position ${index + 1}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeTrack(track),
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(
                                            Icons.drag_handle_rounded,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.08))),
                                const SizedBox(width: 10),
                                Text(
                                  'add tracks from artist catalog',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.08))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            StudioTextField(
                              controller: _trackSearchController,
                              label: 'Search artist tracks',
                              hint: 'Search songs by title...',
                              icon: Icons.search_rounded,
                              onChanged: (value) {
                                setState(() => _trackSearchQuery = value);
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _trackSearchQuery.trim().length >= 2
                                  ? 'Only tracks not already in the album are shown here.'
                                  : 'Type at least 2 characters to search tracks.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            if (_trackSearchQuery.trim().length >= 2) ...[
                              const SizedBox(height: 10),
                              if (filteredLibrarySongs.isEmpty)
                                Text(
                                  'No tracks found for "${_trackSearchQuery.trim()}".',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                )
                              else
                                Column(
                                  children: filteredLibrarySongs
                                      .map(
                                        (song) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              image: song.thumbnailUrl
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          song.thumbnailUrl!),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                              color: Colors.white
                                                  .withOpacity(0.05),
                                            ),
                                            child: song.thumbnailUrl
                                                        ?.isNotEmpty ==
                                                    true
                                                ? null
                                                : const Icon(
                                                    Icons.music_note_rounded,
                                                    color: Colors.white70,
                                                  ),
                                          ),
                                          title: Text(
                                            song.songName ?? 'Unknown title',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: OutlinedButton(
                                            onPressed: () => _addTrack(song),
                                            child: const Text('Add'),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      StudioSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StudioSectionTitle('Release details'),
                            const SizedBox(height: 14),
                            _AlbumEditAdaptivePair(
                              left: StudioTextField(
                                controller: _labelController,
                                label: 'Label',
                                hint: 'Label or imprint (optional)',
                                icon: Icons.business_rounded,
                              ),
                              right: StudioTextField(
                                controller: _genreController,
                                label: 'Genre',
                                hint: 'Pop, Electronic, Indie...',
                                icon: Icons.library_music_rounded,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Album type',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _albumTypeValues.map((value) {
                                final selected = _selectedAlbumType == value;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(
                                    _displayAlbumType(value),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.04),
                                  selectedColor: const Color(0xFF8B5CF6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    side: BorderSide(
                                      color: selected
                                          ? const Color(0xFF8B5CF6)
                                              .withOpacity(0.9)
                                          : Colors.white.withOpacity(0.16),
                                    ),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedAlbumType =
                                          selected ? value : null;
                                    });
                                  },
                                );
                              }).toList(growable: false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      StudioPrimaryButton(
                        loading: _saving,
                        text: 'Save album changes',
                        icon: Icons.save_rounded,
                        onPressed: () => _save(album),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlbumEditAdaptivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _AlbumEditAdaptivePair({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _AlbumArtistChip extends StatelessWidget {
  final String label;
  final bool locked;
  final VoidCallback? onRemove;

  const _AlbumArtistChip({
    required this.label,
    required this.locked,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: (locked ? Pallete.accentCyan : Colors.white)
                  .withOpacity(0.12),
            ),
            child: Text(
              locked ? 'PRIMARY' : 'LINKED',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableAlbumTrack {
  final String songId;
  final String title;
  final String? thumbnailUrl;

  const _EditableAlbumTrack({
    required this.songId,
    required this.title,
    this.thumbnailUrl,
  });

  factory _EditableAlbumTrack.fromAlbumTrack(AlbumTrack track) {
    return _EditableAlbumTrack(
      songId: track.songId,
      title: track.songName ?? 'Unknown title',
      thumbnailUrl: track.thumbnailUrl,
    );
  }

  factory _EditableAlbumTrack.fromArtistSongRef(ArtistSongRef track) {
    return _EditableAlbumTrack(
      songId: track.songId,
      title: track.songName ?? 'Unknown title',
      thumbnailUrl: track.thumbnailUrl,
    );
  }
}
