// lib/features/home/song/view/pages/upload_song_page.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';

// Nuovi widget estratti
import 'package:client/features/home/admin/view/widgets/UploadSong/upload_tab_switcher.dart';
import 'package:client/features/home/admin/view/widgets/UploadSong/track_tab_content.dart';
import 'package:client/features/home/admin/view/widgets/UploadSong/artists_tab_content.dart';
import 'package:client/features/home/admin/view/widgets/UploadSong/details_tab_content.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadSongPage extends ConsumerStatefulWidget {
  const UploadSongPage({super.key});

  @override
  ConsumerState<UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends ConsumerState<UploadSongPage> {
  final songNameController = TextEditingController();
  final composerController = TextEditingController();
  final producerController = TextEditingController();
  final genreController = TextEditingController();
  final moodController = TextEditingController();
  final lyricsController = TextEditingController();
  final _artistSearchController = TextEditingController();

  String _artistSearchQuery = '';
  final List<ArtistModel> _selectedArtists = [];
  final Map<String, SongArtistRole> _artistRoles = {};

  DateTime? _releaseDate;
  PickedMedia? selectedImage;
  PickedMedia? selectedAudio;

  final formKey = GlobalKey<FormState>();
  int _currentTabIndex = 0;

  @override
  void dispose() {
    songNameController.dispose();
    composerController.dispose();
    producerController.dispose();
    genreController.dispose();
    moodController.dispose();
    lyricsController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  Future<void> selectAudio() async {
    final pickedAudio = await pickAudio();
    if (pickedAudio != null) {
      setState(() => selectedAudio = pickedAudio);
    }
  }

  Future<void> selectImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      setState(() => selectedImage = pickedImage);
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
      setState(() => _releaseDate = picked);
    }
  }

  void _onSelectArtist(ArtistModel artist) {
    setState(() {
      if (_selectedArtists.any((a) => a.id == artist.id)) return;
      _selectedArtists.add(artist);
      _artistRoles[artist.id] = _selectedArtists.length == 1
          ? SongArtistRole.primary
          : SongArtistRole.featured;
    });
  }

  void _onRemoveArtist(ArtistModel artist) {
    setState(() {
      _selectedArtists.removeWhere((a) => a.id == artist.id);
      _artistRoles.remove(artist.id);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final songName = songNameController.text.trim();
    final composerName = composerController.text.trim();
    final producerName = producerController.text.trim();
    final genre = genreController.text.trim();
    final mood = moodController.text.trim();
    final lyrics = lyricsController.text.trim();

    if (songName.isEmpty ||
        composerName.isEmpty ||
        _releaseDate == null ||
        selectedAudio == null ||
        selectedImage == null) {
      if (selectedAudio == null || selectedImage == null) {
        setState(() => _currentTabIndex = 0);
      } else if (_releaseDate == null || genre.isEmpty || mood.isEmpty) {
        setState(() => _currentTabIndex = 2);
      }
      showSnackBar(context,
          'Please fill song name, composer, release date and select audio + artwork.');
      return;
    }

    final artistIds = _selectedArtists.map((a) => a.id).toList();

    await ref.read(songViewModelProvider.notifier).uploadSong(
          selectedAudio: selectedAudio!,
          selectedThumbnail: selectedImage!,
          songName: songName,
          releaseDate: _releaseDate!,
          composerName: composerName,
          producerName: producerName.isEmpty ? null : producerName,
          genre: genre.isEmpty ? null : genre,
          lyrics: lyrics.isEmpty ? null : lyrics,
          mood: mood.isEmpty ? null : mood,
          artistIds: artistIds,
        );
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return TrackTabContent(
          key: const ValueKey('tab-track'),
          selectedImage: selectedImage,
          selectedAudio: selectedAudio,
          onSelectImage: selectImage,
          onSelectAudio: selectAudio,
          songNameController: songNameController,
          composerController: composerController,
          lyricsController: lyricsController,
        );
      case 1:
        return ArtistsTabContent(
          key: const ValueKey('tab-artists'),
          selectedArtists: _selectedArtists,
          artistRoles: _artistRoles,
          searchController: _artistSearchController,
          searchQuery: _artistSearchQuery,
          onSearchChanged: (val) => setState(() => _artistSearchQuery = val),
          onSelectArtist: _onSelectArtist,
          onRemoveArtist: _onRemoveArtist,
          onRoleChanged: (id, role) => setState(() => _artistRoles[id] = role),
          producerController: producerController,
        );
      case 2:
      default:
        return DetailsTabContent(
          key: const ValueKey('tab-details'),
          releaseDate: _releaseDate,
          onPickReleaseDate: _pickReleaseDate,
          genreController: genreController,
          moodController: moodController,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue?>(songViewModelProvider, (prev, next) {
      if (next == null) return;
      next.when(
        data: (data) {
          showSnackBar(context, 'Song uploaded successfully!');
          Navigator.pop(context, data is SongModel ? data : null);
        },
        error: (error, stack) => showSnackBar(context, error.toString()),
        loading: () {},
      );
    });

    final isLoading = ref
        .watch(songViewModelProvider.select((val) => val?.isLoading == true));

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
            Text('New track',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.08),
              ),
              child: Text('Studio',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70)),
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050509), Color(0xFF140813)],
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
                gradient: RadialGradient(colors: [
                  Pallete.gradient2.withOpacity(0.26),
                  Colors.transparent
                ]),
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
                              Text('Upload a new song to your Artify catalog.',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(
                                  'Audio, artwork and metadata — split in focused tabs.',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white38, fontSize: 11)),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Pallete.cardColor.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color:
                                          Pallete.borderColor.withOpacity(0.7)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.45),
                                        blurRadius: 26,
                                        offset: const Offset(0, 18)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UploadTabSwitcher(
                                      currentTabIndex: _currentTabIndex,
                                      onTabChanged: (index) => setState(
                                          () => _currentTabIndex = index),
                                    ),
                                    const SizedBox(height: 20),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: _buildCurrentTab(),
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
}
