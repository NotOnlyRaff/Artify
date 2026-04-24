import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/artists_tab_content.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/details_tab_content.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/track_tab_content.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_tab_switcher.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
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
  final _composerSearchController = TextEditingController();
  final _producerSearchController = TextEditingController();

  String _artistSearchQuery = '';
  String _composerSearchQuery = '';
  String _producerSearchQuery = '';

  final List<ArtistModel> _selectedArtists = [];
  final Map<String, SongArtistRole> _artistRoles = {};
  ArtistModel? _linkedComposerArtist;
  ArtistModel? _linkedProducerArtist;

  DateTime? _releaseDate;
  PickedMedia? selectedImage;
  PickedMedia? selectedAudio;

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
    _composerSearchController.dispose();
    _producerSearchController.dispose();
    super.dispose();
  }

  Future<void> selectAudio() async {
    final pickedAudio = await pickAudio();
    if (pickedAudio != null && mounted) {
      setState(() => selectedAudio = pickedAudio);
    }
  }

  Future<void> selectImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null && mounted) {
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

    if (picked != null && mounted) {
      setState(() => _releaseDate = picked);
    }
  }

  void _onSelectArtist(ArtistModel artist) {
    if (_selectedArtists.any((item) => item.id == artist.id)) return;

    setState(() {
      _selectedArtists.add(artist);
      _artistRoles[artist.id] = _selectedArtists.length == 1
          ? SongArtistRole.primary
          : SongArtistRole.featured;
    });
  }

  void _onRemoveArtist(ArtistModel artist) {
    setState(() {
      _selectedArtists.removeWhere((item) => item.id == artist.id);
      _artistRoles.remove(artist.id);

      if (_selectedArtists.isNotEmpty &&
          !_artistRoles.containsKey(_selectedArtists.first.id)) {
        _artistRoles[_selectedArtists.first.id] = SongArtistRole.primary;
      }
    });
  }

  void _selectComposerArtist(ArtistModel artist) {
    setState(() {
      _linkedComposerArtist = artist;
      composerController.text = artist.displayName?.isNotEmpty == true
          ? artist.displayName!
          : artist.name;
      _composerSearchController.clear();
      _composerSearchQuery = '';
    });
  }

  void _selectProducerArtist(ArtistModel artist) {
    setState(() {
      _linkedProducerArtist = artist;
      producerController.text = artist.displayName?.isNotEmpty == true
          ? artist.displayName!
          : artist.name;
      _producerSearchController.clear();
      _producerSearchQuery = '';
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
      } else {
        setState(() => _currentTabIndex = 1);
      }

      showSnackBar(
        context,
        'Please complete title, composer, release date, audio and artwork before publishing.',
      );
      return;
    }

    final artistIds = _selectedArtists.map((artist) => artist.id).toList();
    final artistLinks = _selectedArtists
        .map(
          (artist) => SongArtistModel(
            artistId: artist.id,
            role: _artistRoles[artist.id] ??
                (_selectedArtists.isNotEmpty &&
                        _selectedArtists.first.id == artist.id
                    ? SongArtistRole.primary
                    : SongArtistRole.featured),
          ),
        )
        .toList(growable: false);

    await ref.read(songViewModelProvider.notifier).uploadSong(
          selectedAudio: selectedAudio!,
          selectedThumbnail: selectedImage!,
          songName: songName,
          releaseDate: _releaseDate!,
          composerId: _linkedComposerArtist?.id,
          composerName: composerName,
          producerId: _linkedProducerArtist?.id,
          producerName: producerName.isEmpty ? null : producerName,
          genre: genre.isEmpty ? null : genre,
          lyrics: lyrics.isEmpty ? null : lyrics,
          mood: mood.isEmpty ? null : mood,
          artistIds: artistIds,
          artistLinks: artistLinks,
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
          lyricsController: lyricsController,
        );
      case 1:
        return ArtistsTabContent(
          key: const ValueKey('tab-artists'),
          selectedArtists: _selectedArtists,
          artistRoles: _artistRoles,
          searchController: _artistSearchController,
          searchQuery: _artistSearchQuery,
          onSearchChanged: (value) =>
              setState(() => _artistSearchQuery = value),
          onSelectArtist: _onSelectArtist,
          onRemoveArtist: _onRemoveArtist,
          onRoleChanged: (id, role) => setState(() => _artistRoles[id] = role),
          composerController: composerController,
          composerSearchController: _composerSearchController,
          composerSearchQuery: _composerSearchQuery,
          linkedComposerArtist: _linkedComposerArtist,
          onComposerSearchChanged: (value) =>
              setState(() => _composerSearchQuery = value),
          onSelectComposerArtist: _selectComposerArtist,
          onClearLinkedComposerArtist: () =>
              setState(() => _linkedComposerArtist = null),
          producerController: producerController,
          producerSearchController: _producerSearchController,
          producerSearchQuery: _producerSearchQuery,
          linkedProducerArtist: _linkedProducerArtist,
          onProducerSearchChanged: (value) =>
              setState(() => _producerSearchQuery = value),
          onSelectProducerArtist: _selectProducerArtist,
          onClearLinkedProducerArtist: () =>
              setState(() => _linkedProducerArtist = null),
        );
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
    ref.listen<AsyncValue?>(songViewModelProvider, (previous, next) {
      if (next == null) return;
      next.when(
        data: (data) {
          showSnackBar(context, 'Song uploaded successfully.');
          Navigator.pop(context, data is SongModel ? data : null);
        },
        error: (error, _) => showSnackBar(context, error.toString()),
        loading: () {},
      );
    });

    final isLoading = ref.watch(
        songViewModelProvider.select((value) => value?.isLoading == true));

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
              'New track',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload a new song to your Artify catalog.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Split media, artist roles and metadata into focused tabs so credits stay consistent with the backend model.',
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
                                  UploadTabSwitcher(
                                    currentTabIndex: _currentTabIndex,
                                    onTabChanged: (index) => setState(
                                        () => _currentTabIndex = index),
                                  ),
                                  const SizedBox(height: 20),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
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
        ],
      ),
    );
  }
}
