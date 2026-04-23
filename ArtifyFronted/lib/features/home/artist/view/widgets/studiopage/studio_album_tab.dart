import 'package:client/core/utils.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

class StudioAlbumTab extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final String? resolvedArtistId;
  final AsyncValue<ArtistModel>? targetArtistAsync;

  const StudioAlbumTab({
    super.key,
    required this.currentUser,
    required this.resolvedArtistId,
    required this.targetArtistAsync,
  });

  @override
  ConsumerState<StudioAlbumTab> createState() => _StudioAlbumTabState();
}

class _StudioAlbumTabState extends ConsumerState<StudioAlbumTab> {
  final _formKey = GlobalKey<FormState>();

  int _currentTabIndex = 0;

  final _titleController = TextEditingController();
  final _labelController = TextEditingController();
  final _genreController = TextEditingController();
  final _artistSearchController = TextEditingController();
  final _trackSearchController = TextEditingController();

  PickedMedia? _selectedCover;
  DateTime? _releaseDate;
  String? _selectedAlbumType = 'album';

  String _artistSearchQuery = '';
  String _trackSearchQuery = '';

  final List<ArtistModel> _selectedAlbumArtists = [];
  final List<_StudioAlbumTrackEntry> _tracks = [];

  bool _submitting = false;

  final List<String> _albumTypeValues = const [
    'album',
    'single',
    'ep',
    'compilation',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _labelController.dispose();
    _genreController.dispose();
    _artistSearchController.dispose();
    _trackSearchController.dispose();

    for (final entry in _tracks) {
      entry.local?.dispose();
    }

    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await pickImage();
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedCover = picked);
    }
  }

  Future<void> _pickReleaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null && mounted) {
      setState(() => _releaseDate = picked);
    }
  }

  void _addAlbumArtist(ArtistModel artist) {
    if (_selectedAlbumArtists.any((a) => a.id == artist.id)) return;
    setState(() => _selectedAlbumArtists.add(artist));
  }

  void _removeAlbumArtist(ArtistModel artist) {
    setState(() => _selectedAlbumArtists.removeWhere((a) => a.id == artist.id));
  }

  void _addExistingTrack(ArtistSongRef song) {
    final alreadyAdded =
        _tracks.any((t) => t.existingSong?.songId == song.songId);
    if (alreadyAdded) return;

    setState(() {
      _tracks.add(_StudioAlbumTrackEntry.existing(song));
    });
  }

  void _addLocalTrack(_StudioLocalAlbumTrack track) {
    setState(() {
      _tracks.add(_StudioAlbumTrackEntry.local(track));
    });
  }

  void _removeTrack(_StudioAlbumTrackEntry entry) {
    setState(() {
      _tracks.remove(entry);
      entry.local?.dispose();
    });
  }

  void _moveTrack(int from, int to) {
    setState(() {
      final item = _tracks.removeAt(from);
      _tracks.insert(to, item);
    });
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> _uploadAlbumCoverIfNeeded() async {
    if (_selectedCover == null) return null;

    final res =
        await ref.read(albumViewModelProvider.notifier).uploadAlbumCover(
              cover: _selectedCover!,
            );

    switch (res) {
      case Left(value: final failure):
        if (mounted) {
          showSnackBar(context, failure.message);
        }
        return null;
      case Right(value: final coverUrl):
        return coverUrl;
    }
  }

  Future<SongModel?> _uploadOneLocalTrack({
    required ArtistModel primaryArtist,
    required _StudioLocalAlbumTrack draft,
    required DateTime releaseDate,
    required PickedMedia fallbackCover,
  }) async {
    final resolvedArtwork = draft.customArtwork ?? fallbackCover;

    final orderedArtists = <ArtistModel>[
      primaryArtist,
      ...draft.selectedArtists.where((artist) => artist.id != primaryArtist.id),
    ];

    final artistIds = orderedArtists.map((artist) => artist.id).toList();

    final res = await ref.read(songViewModelProvider.notifier).uploadSongResult(
          selectedAudio: draft.audio!,
          selectedThumbnail: resolvedArtwork,
          songName: draft.titleController.text.trim(),
          releaseDate: releaseDate,
          composerName: draft.composerController.text.trim(),
          producerName: _emptyToNull(draft.producerController.text),
          genre: _emptyToNull(draft.genreController.text) ??
              _emptyToNull(_genreController.text),
          lyrics: _emptyToNull(draft.lyricsController.text),
          mood: _emptyToNull(draft.moodController.text),
          artistIds: artistIds,
        );

    switch (res) {
      case Left(value: final failure):
        if (mounted) {
          showSnackBar(context, failure.message);
        }
        return null;

      case Right(value: final song):
        return song;
    }
  }

  Future<void> _submit(ArtistModel primaryArtist) async {
    FocusScope.of(context).unfocus();

    if (_titleController.text.trim().isEmpty) {
      setState(() => _currentTabIndex = 0);
      showSnackBar(context, 'Album title is required.');
      return;
    }

    if (_releaseDate == null) {
      setState(() => _currentTabIndex = 2);
      showSnackBar(context, 'Release date is required.');
      return;
    }

    if (_tracks.isEmpty) {
      setState(() => _currentTabIndex = 1);
      showSnackBar(context, 'Add at least one track.');
      return;
    }

    for (final entry in _tracks.where((t) => t.local != null)) {
      final track = entry.local!;
      if (track.titleController.text.trim().isEmpty ||
          track.composerController.text.trim().isEmpty ||
          track.audio == null) {
        setState(() => _currentTabIndex = 1);
        showSnackBar(
          context,
          'Every new track needs title, composer and audio.',
        );
        return;
      }
    }

    final hasLocalTracks = _tracks.any((t) => t.local != null);

    if (hasLocalTracks && _selectedCover == null) {
      final anyTrackWithoutArtwork = _tracks.any(
        (t) => t.local != null && t.local!.customArtwork == null,
      );

      if (anyTrackWithoutArtwork) {
        setState(() => _currentTabIndex = 0);
        showSnackBar(
          context,
          'Select an album cover or assign artwork to every new local track.',
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final coverUrl = await _uploadAlbumCoverIfNeeded();
      if (_selectedCover != null && coverUrl == null) {
        return;
      }

      final existingSongIds = <String>[];
      final uploadedSongIds = <String>[];

      for (final entry in _tracks) {
        if (entry.existingSong != null) {
          existingSongIds.add(entry.existingSong!.songId);
          continue;
        }

        final localTrack = entry.local!;
        final fallbackCover = localTrack.customArtwork ?? _selectedCover;

        if (fallbackCover == null) {
          showSnackBar(
            context,
            'Missing artwork for local track "${localTrack.titleController.text.trim()}".',
          );
          return;
        }

        final uploadedSong = await _uploadOneLocalTrack(
          primaryArtist: primaryArtist,
          draft: localTrack,
          releaseDate: _releaseDate!,
          fallbackCover: fallbackCover,
        );

        if (uploadedSong == null) {
          return;
        }

        uploadedSongIds.add(uploadedSong.id);
      }

      final albumArtistIds = <String>[
        primaryArtist.id,
        ..._selectedAlbumArtists
            .where((artist) => artist.id != primaryArtist.id)
            .map((artist) => artist.id),
      ];

      await ref.read(albumViewModelProvider.notifier).createAlbum(
        title: _titleController.text.trim(),
        releaseDate: _releaseDate,
        label: _emptyToNull(_labelController.text),
        albumType: _selectedAlbumType,
        genre: _emptyToNull(_genreController.text),
        coverUrl: coverUrl,
        artistIds: albumArtistIds,
        songIds: [
          ...existingSongIds,
          ...uploadedSongIds,
        ],
      );

      final albumState = ref.read(albumViewModelProvider);
      if (albumState?.hasError == true) {
        showSnackBar(context, albumState!.error.toString());
        return;
      }

      ref.invalidate(getArtistProvider(primaryArtist.id));
      ref.invalidate(getArtistsProvider());
      ref.invalidate(getAllSongsProvider);
      ref.invalidate(getAllAlbumsProvider);

      showSnackBar(context, 'Album created successfully.');
      _clearForm();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _labelController.clear();
    _genreController.clear();
    _artistSearchController.clear();
    _trackSearchController.clear();

    for (final entry in _tracks) {
      entry.local?.dispose();
    }

    setState(() {
      _currentTabIndex = 0;
      _selectedCover = null;
      _releaseDate = null;
      _selectedAlbumType = 'album';
      _artistSearchQuery = '';
      _trackSearchQuery = '';
      _selectedAlbumArtists.clear();
      _tracks.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolvedArtistId = widget.resolvedArtistId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StudioHeroCard(
                icon: Icons.album_rounded,
                title: 'Build a real album release',
                subtitle:
                    'Upload full tracks, attach collaborators, order the tracklist and create the final album from actual song records.',
              ),
              const SizedBox(height: 20),
              if (resolvedArtistId == null)
                StudioSectionCard(
                  child: Text(
                    widget.currentUser.role == UserRole.admin
                        ? 'Admin mode is active. Enter a target artist id above to create an album.'
                        : 'Your account has no linked artist profile yet.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              else
                widget.targetArtistAsync?.when(
                      loading: () => const StudioSectionCard(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => StudioSectionCard(
                        child: Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      data: (primaryArtist) {
                        final trimmedArtistQuery =
                            _artistSearchQuery.trim().toLowerCase();
                        final enableArtistSearch =
                            trimmedArtistQuery.length >= 2;

                        final artistsAsync = enableArtistSearch
                            ? ref.watch(
                                getArtistsProvider(search: trimmedArtistQuery),
                              )
                            : const AsyncValue<List<ArtistModel>>.data(
                                <ArtistModel>[],
                              );

                        final availableLibrarySongs =
                            primaryArtist.songs.where((song) {
                          final query = _trackSearchQuery.trim().toLowerCase();
                          final matchesQuery = query.isEmpty ||
                              (song.songName?.toLowerCase().contains(query) ??
                                  false);
                          final alreadySelected = _tracks.any(
                            (t) => t.existingSong?.songId == song.songId,
                          );

                          return matchesQuery && !alreadySelected;
                        }).toList();

                        return Form(
                          key: _formKey,
                          child: StudioSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StudioAlbumTabSwitcher(
                                  currentIndex: _currentTabIndex,
                                  onTabSelected: (index) {
                                    setState(() => _currentTabIndex = index);
                                  },
                                ),
                                const SizedBox(height: 24),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _buildActiveTab(
                                    key: ValueKey(_currentTabIndex),
                                    primaryArtist: primaryArtist,
                                    artistsAsync: artistsAsync,
                                    availableLibrarySongs:
                                        availableLibrarySongs,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                StudioPrimaryButton(
                                  loading: _submitting,
                                  text: 'Create album',
                                  icon: Icons.check_rounded,
                                  onPressed: () => _submit(primaryArtist),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab({
    required Key key,
    required ArtistModel primaryArtist,
    required AsyncValue<List<ArtistModel>> artistsAsync,
    required List<ArtistSongRef> availableLibrarySongs,
  }) {
    switch (_currentTabIndex) {
      case 0:
        return _StudioAlbumInfoStep(
          key: key,
          selectedCover: _selectedCover,
          onSelectCover: _pickCover,
          titleController: _titleController,
          primaryArtist: primaryArtist,
          selectedAlbumArtists: _selectedAlbumArtists,
          onRemoveArtist: _removeAlbumArtist,
          artistSearchController: _artistSearchController,
          artistSearchQuery: _artistSearchQuery,
          onArtistQueryChanged: (value) {
            setState(() => _artistSearchQuery = value);
          },
          artistsAsync: artistsAsync,
          onAddArtist: _addAlbumArtist,
        );

      case 1:
        return _StudioAlbumTracksStep(
          key: key,
          tracks: _tracks,
          availableLibrarySongs: availableLibrarySongs,
          trackSearchController: _trackSearchController,
          trackSearchQuery: _trackSearchQuery,
          onTrackSearchChanged: (value) {
            setState(() => _trackSearchQuery = value);
          },
          onAddExistingTrack: _addExistingTrack,
          onRemoveTrack: _removeTrack,
          onMoveTrack: _moveTrack,
          onCreateLocalTrack: () async {
            final localTrack =
                await showModalBottomSheet<_StudioLocalAlbumTrack>(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF050509),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: _StudioNewTrackSheet(
                    primaryArtist: primaryArtist,
                    onCreated: (track) => Navigator.of(ctx).pop(track),
                  ),
                );
              },
            );

            if (!mounted) return;
            if (localTrack != null) {
              _addLocalTrack(localTrack);
            }
          },
        );

      default:
        return _StudioAlbumDetailsStep(
          key: key,
          releaseDate: _releaseDate,
          onPickReleaseDate: _pickReleaseDate,
          labelController: _labelController,
          genreController: _genreController,
          albumTypeValues: _albumTypeValues,
          selectedAlbumType: _selectedAlbumType,
          onAlbumTypeChanged: (value) {
            setState(() => _selectedAlbumType = value);
          },
        );
    }
  }
}

class _StudioAlbumInfoStep extends StatelessWidget {
  final PickedMedia? selectedCover;
  final VoidCallback onSelectCover;
  final TextEditingController titleController;

  final ArtistModel primaryArtist;
  final List<ArtistModel> selectedAlbumArtists;
  final ValueChanged<ArtistModel> onAddArtist;
  final ValueChanged<ArtistModel> onRemoveArtist;

  final TextEditingController artistSearchController;
  final String artistSearchQuery;
  final ValueChanged<String> onArtistQueryChanged;
  final AsyncValue<List<ArtistModel>> artistsAsync;

  const _StudioAlbumInfoStep({
    super.key,
    required this.selectedCover,
    required this.onSelectCover,
    required this.titleController,
    required this.primaryArtist,
    required this.selectedAlbumArtists,
    required this.onAddArtist,
    required this.onRemoveArtist,
    required this.artistSearchController,
    required this.artistSearchQuery,
    required this.onArtistQueryChanged,
    required this.artistsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = artistSearchQuery.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudioSectionTitle('Artwork'),
        const SizedBox(height: 10),
        StudioMediaPickerCard(
          label: 'Album cover',
          value: selectedCover?.name,
          icon: Icons.image_rounded,
          buttonText: 'Select cover',
          onTap: onSelectCover,
        ),
        const SizedBox(height: 20),
        const StudioSectionTitle('Album title'),
        const SizedBox(height: 10),
        StudioTextField(
          controller: titleController,
          label: 'Title',
          hint: 'Give your release a name',
          icon: Icons.album_outlined,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Album title is required'
              : null,
        ),
        const SizedBox(height: 22),
        const StudioSectionTitle('Album artists'),
        const SizedBox(height: 8),
        const StudioInfoCallout(
          title: 'Primary artist locked',
          body:
              'The current artist studio target is always included as the primary album artist. Add only collaborators below.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ArtistChip(
              label: primaryArtist.displayName?.isNotEmpty == true
                  ? primaryArtist.displayName!
                  : primaryArtist.name,
              role: 'PRIMARY',
              onRemove: null,
            ),
            ...selectedAlbumArtists.map(
              (artist) => _ArtistChip(
                label: artist.displayName?.isNotEmpty == true
                    ? artist.displayName!
                    : artist.name,
                role: 'COLLAB',
                onRemove: () => onRemoveArtist(artist),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StudioTextField(
          controller: artistSearchController,
          label: 'Search collaborators',
          hint: 'Search artist by name...',
          icon: Icons.search_rounded,
          onChanged: onArtistQueryChanged,
        ),
        const SizedBox(height: 6),
        Text(
          trimmedQuery.length >= 2
              ? 'Type to search artists in the catalog.'
              : 'Type at least 2 characters to search artists.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        if (trimmedQuery.length >= 2)
          artistsAsync.when(
            data: (artists) {
              final filtered = artists
                  .where((artist) {
                    final isPrimary = artist.id == primaryArtist.id;
                    final alreadySelected = selectedAlbumArtists.any(
                      (selected) => selected.id == artist.id,
                    );
                    return !isPrimary && !alreadySelected;
                  })
                  .take(6)
                  .toList();

              if (filtered.isEmpty) {
                return Text(
                  'No artists found for "$trimmedQuery".',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                );
              }

              return Column(
                children: filtered
                    .map(
                      (artist) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_rounded),
                        ),
                        title: Text(
                          artist.displayName?.isNotEmpty == true
                              ? artist.displayName!
                              : artist.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => onAddArtist(artist),
                          child: const Text('Add'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Text(
              error.toString(),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

class _StudioAlbumTracksStep extends StatelessWidget {
  final List<_StudioAlbumTrackEntry> tracks;
  final List<ArtistSongRef> availableLibrarySongs;

  final TextEditingController trackSearchController;
  final String trackSearchQuery;
  final ValueChanged<String> onTrackSearchChanged;

  final ValueChanged<ArtistSongRef> onAddExistingTrack;
  final ValueChanged<_StudioAlbumTrackEntry> onRemoveTrack;
  final void Function(int from, int to) onMoveTrack;
  final Future<void> Function() onCreateLocalTrack;

  const _StudioAlbumTracksStep({
    super.key,
    required this.tracks,
    required this.availableLibrarySongs,
    required this.trackSearchController,
    required this.trackSearchQuery,
    required this.onTrackSearchChanged,
    required this.onAddExistingTrack,
    required this.onRemoveTrack,
    required this.onMoveTrack,
    required this.onCreateLocalTrack,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = trackSearchQuery.trim().toLowerCase();
    final filteredLibrarySongs = availableLibrarySongs
        .where((song) => trimmedQuery.isEmpty
            ? true
            : (song.songName?.toLowerCase().contains(trimmedQuery) ?? false))
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const StudioSectionTitle('Tracklist'),
            const Spacer(),
            Text(
              '${tracks.length} track${tracks.length == 1 ? '' : 's'}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                tracks.isEmpty
                    ? 'Start by uploading a new track or linking existing songs.'
                    : 'Reorder the tracks. Local tracks are uploaded first, then linked to the album.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onCreateLocalTrack,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.white.withOpacity(0.08),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'New track',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (tracks.isEmpty)
          Text(
            'No tracks added yet.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracks.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              onMoveTrack(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final entry = tracks[index];
              final isLocal = entry.isLocal;

              return Container(
                key: ValueKey(entry.key),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(
                    color: isLocal
                        ? Colors.deepPurpleAccent.withOpacity(0.55)
                        : Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isLocal)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.25),
                                  ),
                                  child: Text(
                                    'UPLOAD',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            entry.displaySubtitle,
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
                      onPressed: () => onRemoveTrack(entry),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ),
                    const Icon(
                      Icons.drag_handle_rounded,
                      color: Colors.white38,
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
            const SizedBox(width: 10),
            Text(
              'or link existing songs',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
          ],
        ),
        const SizedBox(height: 16),
        StudioTextField(
          controller: trackSearchController,
          label: 'Search library tracks',
          hint: 'Search songs by title...',
          icon: Icons.search_rounded,
          onChanged: onTrackSearchChanged,
        ),
        const SizedBox(height: 6),
        Text(
          trimmedQuery.length >= 2
              ? 'Type to search tracks already present in the current artist catalog.'
              : 'Type at least 2 characters to search tracks.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        if (trimmedQuery.length >= 2)
          if (filteredLibrarySongs.isEmpty)
            Text(
              'No tracks found for "$trimmedQuery".',
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
                      leading: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white70,
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
                        onPressed: () => onAddExistingTrack(song),
                        child: const Text('Add'),
                      ),
                    ),
                  )
                  .toList(),
            ),
      ],
    );
  }
}

class _StudioAlbumDetailsStep extends StatelessWidget {
  final DateTime? releaseDate;
  final VoidCallback onPickReleaseDate;
  final TextEditingController labelController;
  final TextEditingController genreController;
  final List<String> albumTypeValues;
  final String? selectedAlbumType;
  final ValueChanged<String?> onAlbumTypeChanged;

  const _StudioAlbumDetailsStep({
    super.key,
    required this.releaseDate,
    required this.onPickReleaseDate,
    required this.labelController,
    required this.genreController,
    required this.albumTypeValues,
    required this.selectedAlbumType,
    required this.onAlbumTypeChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudioSectionTitle('Release'),
        const SizedBox(height: 10),
        StudioDateField(
          label: 'Release date',
          value: releaseDate,
          onPick: onPickReleaseDate,
        ),
        const SizedBox(height: 22),
        const StudioSectionTitle('Label & type'),
        const SizedBox(height: 10),
        StudioTextField(
          controller: labelController,
          label: 'Label',
          hint: 'Label or imprint (optional)',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 14),
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
          children: albumTypeValues.map((value) {
            final selected = selectedAlbumType == value;
            final label = _displayAlbumType(value);

            return ChoiceChip(
              selected: selected,
              label: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white.withOpacity(0.04),
              selectedColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF8B5CF6).withOpacity(0.9)
                      : Colors.white.withOpacity(0.16),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (v) => onAlbumTypeChanged(v ? value : null),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        const StudioSectionTitle('Genre'),
        const SizedBox(height: 10),
        StudioTextField(
          controller: genreController,
          label: 'Genre',
          hint: 'Pop, Electronic, Indie...',
          icon: Icons.library_music_rounded,
        ),
        const SizedBox(height: 18),
        const StudioInfoCallout(
          title: 'Operational difference',
          body:
              'New local tracks in this studio flow are uploaded as real songs before album creation. This avoids invalid local file paths inside album payloads.',
        ),
      ],
    );
  }
}

class _StudioAlbumTabSwitcher extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _StudioAlbumTabSwitcher({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Album', Icons.album_rounded),
      ('Tracks', Icons.queue_music_rounded),
      ('Details', Icons.tune_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final (label, icon) = tabs[index];
          final isActive = currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isActive
                      ? Colors.white.withOpacity(0.14)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ArtistChip extends StatelessWidget {
  final String label;
  final String role;
  final VoidCallback? onRemove;

  const _ArtistChip({
    required this.label,
    required this.role,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.08),
            ),
            child: Text(
              role,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudioNewTrackSheet extends ConsumerStatefulWidget {
  final ArtistModel primaryArtist;
  final ValueChanged<_StudioLocalAlbumTrack> onCreated;

  const _StudioNewTrackSheet({
    required this.primaryArtist,
    required this.onCreated,
  });

  @override
  ConsumerState<_StudioNewTrackSheet> createState() =>
      _StudioNewTrackSheetState();
}

class _StudioNewTrackSheetState extends ConsumerState<_StudioNewTrackSheet> {
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  final _producerController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _artistSearchController = TextEditingController();

  PickedMedia? _audio;
  PickedMedia? _artwork;

  String _artistSearchQuery = '';
  final List<ArtistModel> _selectedArtists = [];
  final Map<String, SongArtistRole> _artistRoles = {};

  @override
  void initState() {
    super.initState();
    _selectedArtists.add(widget.primaryArtist);
    _artistRoles[widget.primaryArtist.id] = SongArtistRole.primary;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _producerController.dispose();
    _genreController.dispose();
    _moodController.dispose();
    _lyricsController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final picked = await pickAudio();
    if (picked != null) {
      setState(() => _audio = picked);
    }
  }

  Future<void> _pickArtwork() async {
    final picked = await pickImage();
    if (picked != null) {
      setState(() => _artwork = picked);
    }
  }

  void _onSelectArtist(ArtistModel artist) {
    setState(() {
      if (_selectedArtists.any((a) => a.id == artist.id)) return;
      _selectedArtists.add(artist);
      _artistRoles[artist.id] = SongArtistRole.featured;
    });
  }

  void _onRemoveArtist(ArtistModel artist) {
    if (artist.id == widget.primaryArtist.id) return;

    setState(() {
      _selectedArtists.removeWhere((a) => a.id == artist.id);
      _artistRoles.remove(artist.id);
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final composer = _composerController.text.trim();

    if (title.isEmpty || composer.isEmpty || _audio == null) {
      showSnackBar(
        context,
        'Please fill track title, composer and select audio.',
      );
      return;
    }

    final track = _StudioLocalAlbumTrack(
      localId: DateTime.now().millisecondsSinceEpoch.toString(),
      titleController: TextEditingController(text: title),
      composerController: TextEditingController(text: composer),
      producerController:
          TextEditingController(text: _producerController.text.trim()),
      genreController:
          TextEditingController(text: _genreController.text.trim()),
      moodController: TextEditingController(text: _moodController.text.trim()),
      lyricsController:
          TextEditingController(text: _lyricsController.text.trim()),
      audio: _audio,
      customArtwork: _artwork,
      selectedArtists: List<ArtistModel>.from(_selectedArtists),
      artistRoles: Map<String, SongArtistRole>.from(_artistRoles),
    );

    widget.onCreated(track);
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = _artistSearchQuery.trim();
    final enableSearch = trimmedQuery.length >= 2;

    final artistsAsync = enableSearch
        ? ref.watch(getArtistsProvider(search: trimmedQuery))
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Text(
            'New album track',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This track will be uploaded as a real song before album creation.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StudioMediaPickerCard(
                  label: 'Audio',
                  value: _audio?.name,
                  icon: Icons.audio_file_rounded,
                  buttonText: 'Select audio',
                  onTap: _pickAudio,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StudioMediaPickerCard(
                  label: 'Artwork',
                  value: _artwork?.name,
                  icon: Icons.image_rounded,
                  buttonText: 'Select artwork',
                  onTap: _pickArtwork,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StudioTextField(
            controller: _titleController,
            label: 'Track title',
            hint: 'Give this track a name',
            icon: Icons.music_note_rounded,
          ),
          const SizedBox(height: 12),
          StudioTextField(
            controller: _composerController,
            label: 'Composer',
            hint: 'Who wrote this track?',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 12),
          StudioTextField(
            controller: _producerController,
            label: 'Producer',
            hint: 'Optional producer',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StudioTextField(
                  controller: _genreController,
                  label: 'Genre',
                  hint: 'Pop, Electronic, Indie...',
                  icon: Icons.graphic_eq_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StudioTextField(
                  controller: _moodController,
                  label: 'Mood',
                  hint: 'Chill, Dark, Upbeat...',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioTextField(
            controller: _lyricsController,
            label: 'Lyrics',
            hint: 'Optional lyrics or notes',
            icon: Icons.lyrics_outlined,
          ),
          const SizedBox(height: 18),
          Text(
            'Track artists',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedArtists.map((artist) {
              final role = _artistRoles[artist.id] ??
                  (artist.id == widget.primaryArtist.id
                      ? SongArtistRole.primary
                      : SongArtistRole.featured);

              return _ArtistChip(
                label: artist.displayName?.isNotEmpty == true
                    ? artist.displayName!
                    : artist.name,
                role: role.value.toUpperCase(),
                onRemove: artist.id == widget.primaryArtist.id
                    ? null
                    : () => _onRemoveArtist(artist),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          StudioTextField(
            controller: _artistSearchController,
            label: 'Search & add artists',
            hint: 'Search artist by name...',
            icon: Icons.search_rounded,
            onChanged: (value) {
              setState(() => _artistSearchQuery = value);
            },
          ),
          const SizedBox(height: 6),
          Text(
            enableSearch
                ? 'Type to search artists in your catalog.'
                : 'Type at least 2 characters to search artists.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (enableSearch)
            artistsAsync.when(
              data: (artists) {
                final filtered = artists
                    .where(
                      (artist) =>
                          !_selectedArtists.any((sel) => sel.id == artist.id),
                    )
                    .take(6)
                    .toList();

                if (filtered.isEmpty) {
                  return Text(
                    'No artists found for "$trimmedQuery".',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  );
                }

                return Column(
                  children: filtered
                      .map(
                        (artist) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_rounded),
                          ),
                          title: Text(
                            artist.displayName?.isNotEmpty == true
                                ? artist.displayName!
                                : artist.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          trailing: OutlinedButton(
                            onPressed: () => _onSelectArtist(artist),
                            child: const Text('Add'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Text(
                error.toString(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.redAccent,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Add to album',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioAlbumTrackEntry {
  // FIX: migrato da SongModel? ad ArtistSongRef?.
  // L'artista espone le sue song come ArtistSongRef (non SongModel completo).
  // I campi necessari (songId, songName) sono tutti presenti in ArtistSongRef.
  final ArtistSongRef? existingSong;
  final _StudioLocalAlbumTrack? local;

  const _StudioAlbumTrackEntry.existing(this.existingSong) : local = null;
  const _StudioAlbumTrackEntry.local(this.local) : existingSong = null;

  bool get isLocal => local != null;

  // FIX: .id → .songId
  String get key => existingSong?.songId ?? 'local-${local!.localId}';

  String get displayTitle =>
      existingSong?.songName ??
      local?.titleController.text.trim() ??
      'Untitled';

  String get displaySubtitle {
    if (existingSong != null) {
      // ArtistSongRef non ha genre — usiamo il role come etichetta.
      return 'Existing track';
    }
    final genre = local?.genreController.text.trim();
    return (genre != null && genre.isNotEmpty) ? genre : 'New upload';
  }
}

class _StudioLocalAlbumTrack {
  final String localId;
  final TextEditingController titleController;
  final TextEditingController composerController;
  final TextEditingController producerController;
  final TextEditingController genreController;
  final TextEditingController moodController;
  final TextEditingController lyricsController;

  PickedMedia? audio;
  PickedMedia? customArtwork;

  final List<ArtistModel> selectedArtists;
  final Map<String, SongArtistRole> artistRoles;

  _StudioLocalAlbumTrack({
    required this.localId,
    required this.titleController,
    required this.composerController,
    required this.producerController,
    required this.genreController,
    required this.moodController,
    required this.lyricsController,
    required this.audio,
    required this.customArtwork,
    required this.selectedArtists,
    required this.artistRoles,
  });

  void dispose() {
    titleController.dispose();
    composerController.dispose();
    producerController.dispose();
    genreController.dispose();
    moodController.dispose();
    lyricsController.dispose();
  }
}
