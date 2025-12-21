// lib/features/home/admin/view/pages/album/upload_album_page.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/album_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/details_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/tracks_tab.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadAlbumPage extends ConsumerStatefulWidget {
  const UploadAlbumPage({super.key});

  @override
  ConsumerState<UploadAlbumPage> createState() => _UploadAlbumPageState();
}

class _UploadAlbumPageState extends ConsumerState<UploadAlbumPage> {
  // TAB INDEX: 0 = Album, 1 = Tracks, 2 = Details
  int _currentTabIndex = 0;

  // --- TEXT CONTROLLERS (album fields) ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();

  // --- ARTISTS (Album tab) ---
  final TextEditingController _artistSearchController = TextEditingController();
  String _artistSearchQuery = '';
  final List<ArtistModel> _selectedArtists = [];

  // --- TRACKS (Tracks tab) ---
  final TextEditingController _trackSearchController = TextEditingController();
  String _trackSearchQuery = '';
  final List<AlbumTrackEntry> _tracks = [];

  // --- DETAILS ---
  DateTime? _releaseDate;
  String? _selectedAlbumType;
  final List<String> _albumTypeValues = const [
    'album',
    'single',
    'ep',
    'compilation',
  ];

  // --- COVER PICKED ---
  PickedMedia? _selectedCover;

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _labelController.dispose();
    _genreController.dispose();
    _artistSearchController.dispose();
    _trackSearchController.dispose();
    super.dispose();
  }

  // ───────────── PICKERS / HELPERS ─────────────

  Future<void> _selectCover() async {
    final picked = await pickImage();
    if (picked != null) {
      setState(() {
        _selectedCover = picked;
      });
    }
  }

  Future<void> _pickReleaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Pallete.gradient2,
              surface: Color(0xFF050509),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _releaseDate = picked;
      });
    }
  }

  void _addArtist(ArtistModel artist) {
    setState(() {
      if (_selectedArtists.any((a) => a.id == artist.id)) return;
      _selectedArtists.add(artist);
    });
  }

  void _removeArtist(ArtistModel artist) {
    setState(() {
      _selectedArtists.removeWhere((a) => a.id == artist.id);
    });
  }

  void _addExistingTrack(SongModel song) {
    setState(() {
      // evita duplicati, tenendo conto che alcune entry possono essere "local"
      final alreadyPresent =
          _tracks.any((t) => t.existingSong?.id == song.id);
      if (alreadyPresent) return;

      _tracks.add(AlbumTrackEntry.existing(song));
    });
  }

  void _addLocalTrack(AlbumTrackLocal track) {
    setState(() {
      _tracks.add(AlbumTrackEntry.local(track));
    });

    debugPrint(
        '[UploadAlbumPage] _addLocalTrack -> added local track '
        'localId=${track.localId}, title=${track.title}. '
        'Total tracks now: ${_tracks.length}');
  }

  void _removeTrack(AlbumTrackEntry entry) {
    setState(() {
      _tracks.remove(entry);
    });
  }

  void _moveTrack(int from, int to) {
    if (from < 0 || from >= _tracks.length || to < 0 || to >= _tracks.length) {
      return;
    }
    setState(() {
      final item = _tracks.removeAt(from);
      _tracks.insert(to, item);
    });
  }

  // ───────────── SUBMIT ─────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final label = _labelController.text.trim();
    final genre = _genreController.text.trim();

    if (title.isEmpty) {
      setState(() => _currentTabIndex = 0);
      showSnackBar(context, 'Album title is required.');
      return;
    }

    final artistIds = _selectedArtists.map((a) => a.id).toList();

    // DEBUG STATO PRIMA DI ELABORARE
    debugPrint('================= CREATE ALBUM DEBUG =================');
    debugPrint('Album title: $title');
    debugPrint('Album releaseDate: $_releaseDate');
    debugPrint('Album label: "$label"');
    debugPrint('Album genre: "$genre"');
    debugPrint('Album type: $_selectedAlbumType');
    debugPrint('Selected album artists: $artistIds');
    debugPrint('Total _tracks in state: ${_tracks.length}');

    for (var i = 0; i < _tracks.length; i++) {
      final t = _tracks[i];
      debugPrint('[TRACK $i] '
          'existingSong=${t.existingSong != null} '
          'local=${t.local != null} '
          'existingId=${t.existingSong?.id} '
          'localId=${t.local?.localId} '
          'title=${t.displayTitle}');
    }

    // 1) Tracce esistenti -> song_ids
    final existingEntries =
        _tracks.where((t) => t.existingSong != null).toList();

    final List<String> existingSongIds =
        existingEntries.map((e) => e.existingSong!.id).toList();

    // 2) Tracce locali -> newSongs (SongModel)
    final localEntries = _tracks.where((t) => t.local != null).toList();

    debugPrint('existingEntries count: ${existingEntries.length}');
    debugPrint('localEntries count: ${localEntries.length}');

    final bool hasAlbumGenre = genre.isNotEmpty;
    final String? albumGenreOrNull = hasAlbumGenre ? genre : null;

final List<SongModel> newSongs = localEntries.map((entry) {
      final track = entry.local!;
      final trackArtistIds =
          track.artistIds.isNotEmpty ? track.artistIds : artistIds;

      // 🔹 mappa gli ID in SongArtistModel + role
      final List<SongArtistModel> songArtists = trackArtistIds.map((artistId) {
        final role = track.artistRoles[artistId] ?? SongArtistRole.primary;
        return SongArtistModel(
          artistId: artistId,
          role: role,
        );
      }).toList();


      final song = SongModel(
        id: 'local-${track.localId}', // id fittizio lato FE
        songName: track.title,
        songUrl: track.songUrl,       // String (path/blob/url) come nel resto del progetto
        thumbnailUrl: null,
        releaseDate: _releaseDate,
        composerName: track.composer,
        producerName: null,
        genre: track.genre ?? albumGenreOrNull,
        lyrics: track.lyrics,
        mood: track.mood,
        artists: songArtists,         // ✅ ora è List<SongArtistModel>, non List<String>
      );
      

      debugPrint('  -> mapped local track to SongModel '
          'id=${song.id}, name=${song.songName}, url=${song.songUrl}');
      return song;
    }).toList();

    debugPrint('existingSongIds: $existingSongIds');
    debugPrint('newSongs count: ${newSongs.length}');
    debugPrint('newSongs titles: ${newSongs.map((s) => s.songName).toList()}');

    if (existingSongIds.isEmpty && newSongs.isEmpty) {
      debugPrint(
          'ABORT CREATE ALBUM: existingSongIds.isEmpty && newSongs.isEmpty');
      setState(() => _currentTabIndex = 1);
      showSnackBar(context, 'Add at least one track to the album.');
      return;
    }

    final String? coverUrl = null;

    await ref.read(albumViewModelProvider.notifier).createAlbum(
          title: title,
          releaseDate: _releaseDate,
          label: label.isEmpty ? null : label,
          albumType: _selectedAlbumType,
          genre: genre.isEmpty ? null : genre,
          coverUrl: coverUrl,
          artistIds: artistIds,
          songIds: existingSongIds,
          newSongs: newSongs, // <-- deve esistere nel viewmodel / repository
        );
  }



  // ───────────── BUILD ─────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue?>(albumViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (data) {
          showSnackBar(context, 'Album created successfully!');
          Navigator.pop(context);
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {},
      );
    });

    final isLoading = ref
        .watch(albumViewModelProvider.select((val) => val?.isLoading == true));

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.08),
              ),
              child: Text(
                'Studio',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
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
          // background gradient + glow
          Container(
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
          ),
          Positioned(
            right: -80,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Pallete.gradient2.withOpacity(0.26),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(child: Loader())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create a new album in your Artify catalog.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Artwork, tracklist and metadata — split into focused tabs.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Pallete.cardColor.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Pallete.borderColor.withOpacity(0.7),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.45),
                                      blurRadius: 26,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTabSwitcher(),
                                    const SizedBox(height: 20),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: _buildCurrentTab(context),
                                    ),
                                  ],
                                ),
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

  // ───────────── TAB SWITCHER + CURRENT TAB ─────────────

  Widget _buildTabSwitcher() {
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
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final (label, icon) = tabs[index];
          final bool isActive = _currentTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTabIndex = index;
                });
              },
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

  Widget _buildCurrentTab(BuildContext context) {
    switch (_currentTabIndex) {
      case 0:
        return AlbumTab(
          key: const ValueKey('tab-album'),
          selectedCover: _selectedCover,
          onSelectCover: _selectCover,
          titleController: _titleController,
          selectedArtists: _selectedArtists,
          onAddArtist: _addArtist,
          onRemoveArtist: _removeArtist,
          artistSearchController: _artistSearchController,
          artistSearchQuery: _artistSearchQuery,
          onArtistQueryChanged: (value) {
            setState(() => _artistSearchQuery = value);
          },
        );
      case 1:
        return TracksTab(
          tracks: _tracks,
          onAddExistingTrack: _addExistingTrack,
          onAddLocalTrack: _addLocalTrack,
          onRemoveTrack: _removeTrack,
          onMoveTrack: _moveTrack,
          trackSearchController: _trackSearchController,
          trackSearchQuery: _trackSearchQuery,
          onTrackQueryChanged: (value) {
            setState(() {
              _trackSearchQuery = value;
            });
          },
        );
      case 2:
      default:
        return DetailsTab(
          key: const ValueKey('tab-details'),
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
