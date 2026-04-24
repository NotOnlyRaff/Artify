import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/studio_badge.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/album_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/details_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/studio_background.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/tracks_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/upload_album_form_card.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/upload_album_header.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/upload_album_tab_switcher.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadAlbumPage extends ConsumerStatefulWidget {
  const UploadAlbumPage({super.key});

  @override
  ConsumerState<UploadAlbumPage> createState() => _UploadAlbumPageState();
}

class _UploadAlbumPageState extends ConsumerState<UploadAlbumPage> {
  int _currentTabIndex = 0;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _labelController = TextEditingController();
  final _genreController = TextEditingController();
  final _artistSearchController = TextEditingController();
  final _trackSearchController = TextEditingController();

  final List<ArtistModel> _selectedArtists = [];
  final List<AlbumTrackEntry> _tracks = [];

  DateTime? _releaseDate;
  String? _selectedAlbumType = 'album';
  PickedMedia? _selectedCover;
  String _artistSearchQuery = '';
  String _trackSearchQuery = '';

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
    super.dispose();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _dedupArtistIds() {
    final ids = <String>[];
    for (final artist in _selectedArtists) {
      if (!ids.contains(artist.id)) {
        ids.add(artist.id);
      }
    }
    return ids;
  }

  Future<String?> _uploadCoverIfNeeded() async {
    if (_selectedCover == null) return null;

    final result =
        await ref.read(albumViewModelProvider.notifier).uploadAlbumCover(
              cover: _selectedCover!,
            );

    switch (result) {
      case Left(value: final failure):
        if (mounted) {
          showSnackBar(context, failure.message);
        }
        return null;
      case Right(value: final coverUrl):
        return coverUrl;
    }
  }

  Future<SongModel?> _uploadLocalTrack({
    required AlbumTrackLocal localTrack,
    required DateTime releaseDate,
    required PickedMedia cover,
  }) async {
    final fallbackArtistIds = _dedupArtistIds();
    final resolvedArtistIds = localTrack.artistIds.isNotEmpty
        ? localTrack.artistIds
        : fallbackArtistIds;

    final artistLinks = resolvedArtistIds
        .asMap()
        .entries
        .map(
          (entry) => SongArtistModel(
            artistId: entry.value,
            role: localTrack.artistRoles[entry.value] ??
                (entry.key == 0
                    ? SongArtistRole.primary
                    : SongArtistRole.featured),
          ),
        )
        .toList(growable: false);

    final result =
        await ref.read(songViewModelProvider.notifier).uploadSongResult(
              selectedAudio: localTrack.audio,
              selectedThumbnail: cover,
              songName: localTrack.title,
              releaseDate: releaseDate,
              composerName: localTrack.composer,
              genre: localTrack.genre,
              lyrics: localTrack.lyrics,
              mood: localTrack.mood,
              artistIds: resolvedArtistIds,
              artistLinks: artistLinks,
            );

    switch (result) {
      case Left(value: final failure):
        if (mounted) {
          showSnackBar(context, failure.message);
        }
        return null;
      case Right(value: final song):
        return song;
    }
  }

  Future<void> _submit() async {
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

    final hasLocalTracks = _tracks.any((entry) => entry.local != null);
    if (hasLocalTracks && _selectedCover == null) {
      setState(() => _currentTabIndex = 0);
      showSnackBar(
        context,
        'Select an album cover before uploading local tracks.',
      );
      return;
    }

    for (final entry in _tracks.where((item) => item.local != null)) {
      final local = entry.local!;
      if (local.title.trim().isEmpty || local.composer.trim().isEmpty) {
        setState(() => _currentTabIndex = 1);
        showSnackBar(
          context,
          'Every local track needs title and composer before album creation.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final coverUrl = await _uploadCoverIfNeeded();
      if (_selectedCover != null && coverUrl == null) {
        return;
      }

      final orderedSongIds = <String>[];

      for (final entry in _tracks) {
        if (entry.existingSong != null) {
          orderedSongIds.add(entry.existingSong!.id);
          continue;
        }

        final uploadedSong = await _uploadLocalTrack(
          localTrack: entry.local!,
          releaseDate: _releaseDate!,
          cover: _selectedCover!,
        );

        if (uploadedSong == null) {
          return;
        }

        orderedSongIds.add(uploadedSong.id);
      }

      await ref.read(albumViewModelProvider.notifier).createAlbum(
            title: _titleController.text.trim(),
            releaseDate: _releaseDate,
            label: _emptyToNull(_labelController.text),
            albumType: _selectedAlbumType,
            genre: _emptyToNull(_genreController.text),
            coverUrl: coverUrl,
            artistIds: _dedupArtistIds(),
            songIds: orderedSongIds,
          );

      final albumState = ref.read(albumViewModelProvider);
      if (albumState?.hasError == true) {
        if (mounted) {
          showSnackBar(context, albumState!.error.toString());
        }
        return;
      }

      ref.invalidate(getAllSongsProvider);
      ref.invalidate(getAllAlbumsProvider);
      for (final artistId in _dedupArtistIds()) {
        ref.invalidate(getArtistProvider(artistId));
      }

      if (!mounted) return;
      showSnackBar(context, 'Album created successfully.');
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumLoading = ref.watch(
        albumViewModelProvider.select((value) => value?.isLoading == true));
    final isLoading = _isSubmitting || albumLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'New album',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const StudioBadge(),
          ],
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _submit,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          const StudioBackground(),
          SafeArea(
            child: isLoading
                ? const Center(child: Loader())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const UploadAlbumHeader(),
                              const SizedBox(height: 24),
                              UploadAlbumFormCard(
                                tabSwitcher: UploadAlbumTabSwitcher(
                                  currentIndex: _currentTabIndex,
                                  onTabSelected: (index) =>
                                      setState(() => _currentTabIndex = index),
                                ),
                                activeTab: _buildActiveTab(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_currentTabIndex) {
      case 0:
        return AlbumTab(
          key: const ValueKey('tab-album'),
          selectedCover: _selectedCover,
          onSelectCover: () async {
            final picked = await pickImage();
            if (picked != null && mounted) {
              setState(() => _selectedCover = picked);
            }
          },
          titleController: _titleController,
          selectedArtists: _selectedArtists,
          onAddArtist: (artist) {
            if (_selectedArtists.any((item) => item.id == artist.id)) return;
            setState(() => _selectedArtists.add(artist));
          },
          onRemoveArtist: (artist) => setState(() =>
              _selectedArtists.removeWhere((item) => item.id == artist.id)),
          artistSearchController: _artistSearchController,
          artistSearchQuery: _artistSearchQuery,
          onArtistQueryChanged: (value) =>
              setState(() => _artistSearchQuery = value),
        );
      case 1:
        return TracksTab(
          key: const ValueKey('tab-tracks'),
          tracks: _tracks,
          onAddExistingTrack: (song) {
            if (_tracks.any((entry) => entry.existingSong?.id == song.id)) {
              return;
            }
            setState(() => _tracks.add(AlbumTrackEntry.existing(song)));
          },
          onAddLocalTrack: (track) =>
              setState(() => _tracks.add(AlbumTrackEntry.local(track))),
          onRemoveTrack: (entry) => setState(() => _tracks.remove(entry)),
          onMoveTrack: (from, to) {
            setState(() {
              final moved = _tracks.removeAt(from);
              _tracks.insert(to, moved);
            });
          },
          trackSearchController: _trackSearchController,
          trackSearchQuery: _trackSearchQuery,
          onTrackQueryChanged: (value) =>
              setState(() => _trackSearchQuery = value),
        );
      default:
        return DetailsTab(
          key: const ValueKey('tab-details'),
          releaseDate: _releaseDate,
          onPickReleaseDate: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _releaseDate ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(DateTime.now().year + 5),
            );
            if (picked != null && mounted) {
              setState(() => _releaseDate = picked);
            }
          },
          labelController: _labelController,
          genreController: _genreController,
          albumTypeValues: _albumTypeValues,
          selectedAlbumType: _selectedAlbumType,
          onAlbumTypeChanged: (value) =>
              setState(() => _selectedAlbumType = value),
        );
    }
  }
}
