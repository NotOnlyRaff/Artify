// lib/features/home/song/view/pages/upload_song_page.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_audio_picker.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_artwork_picker.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_release_date_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_lyrics_field.dart';
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
  // --- CONTROLLER TESTO ---
  final songNameController = TextEditingController();
  final composerController = TextEditingController();
  final producerController = TextEditingController();
  final genreController = TextEditingController();
  final moodController = TextEditingController();
  final lyricsController = TextEditingController();

  // 👇 nuovo
  final artistIdsController = TextEditingController();

  // --- RELEASE DATE ---
  DateTime? _releaseDate;

  // --- MEDIA PICKED ---
  PickedMedia? selectedImage;
  PickedMedia? selectedAudio;

  final formKey = GlobalKey<FormState>();

  // Suggerimenti veloci per Genre / Mood
  final List<String> _genreSuggestions = const [
    'Pop',
    'Hip-hop',
    'R&B',
    'Electronic',
    'Indie',
    'Lo-fi',
    'Rock',
  ];

  final List<String> _moodSuggestions = const [
    'Chill',
    'Upbeat',
    'Dark',
    'Dreamy',
    'Aggressive',
    'Romantic',
  ];

  @override
  void dispose() {
    songNameController.dispose();
    composerController.dispose();
    producerController.dispose();
    genreController.dispose();
    moodController.dispose();
    lyricsController.dispose();
    artistIdsController.dispose();
    super.dispose();
  }

  // ---------- PICKERS ----------

  Future<void> selectAudio() async {
    final pickedAudio = await pickAudio();
    if (pickedAudio != null) {
      setState(() {
        selectedAudio = pickedAudio;
      });
    }
  }

  Future<void> selectImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      setState(() {
        selectedImage = pickedImage;
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

  List<String> _parseIds(String raw) {
    return raw
        .split(RegExp(r'[,\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // ---------- SUBMIT ----------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final songName = songNameController.text.trim();
    final composerName = composerController.text.trim();
    final producerName = producerController.text.trim();
    final genre = genreController.text.trim();
    final mood = moodController.text.trim();
    final lyrics = lyricsController.text.trim();
    final artistIdsRaw = artistIdsController.text.trim();
    final artistIds =
        artistIdsRaw.isEmpty ? <String>[] : _parseIds(artistIdsRaw);

    if (songName.isEmpty ||
        composerName.isEmpty ||
        _releaseDate == null ||
        selectedAudio == null ||
        selectedImage == null) {
      showSnackBar(
        context,
        'Please fill song name, composer, release date and select audio + artwork.',
      );
      return;
    }

    final audioFile = selectedAudio!;
    final imageFile = selectedImage!;

    await ref.read(songViewModelProvider.notifier).uploadSong(
          selectedAudio: audioFile,
          selectedThumbnail: imageFile,
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

  @override
  Widget build(BuildContext context) {
    // LISTEN sullo stato del ViewModel (success/error)
    ref.listen<AsyncValue?>(songViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (data) {
          showSnackBar(context, 'Song uploaded successfully!');
          Navigator.pop(context);
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
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
          // Background gradient + leggero glow
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
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 960), // web
                            child: Form(
                              key: formKey,
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
                                    'Audio, artwork and metadata — all in one place.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Card principale
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color:
                                          Pallete.cardColor.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Pallete.borderColor
                                            .withOpacity(0.7),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.45),
                                          blurRadius: 26,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: isWide
                                        ? _buildWideLayout(context)
                                        : _buildNarrowLayout(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- LAYOUTS -------------------------------------------------------

  Widget _buildWideLayout(BuildContext context) {
    // Colonna media (artwork + audio + data)
    final mediaColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Artwork'),
        const SizedBox(height: 8),
        UploadArtworkPicker(
          selectedImage: selectedImage,
          onTap: selectImage,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Audio file'),
        const SizedBox(height: 8),
        ArtifyAudioPicker(
          selectedAudio: selectedAudio,
          onTapSelectAudio: selectAudio,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        UploadReleaseDateField(
          releaseDate: _releaseDate,
          onTap: _pickReleaseDate,
        ),
      ],
    );

    // Colonna dettagli (campi testo + lyrics)
    final detailsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Track details'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Song title',
          placeholder: 'Give your track a name',
          controller: songNameController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Composer',
          placeholder: 'Who wrote this track?',
          controller: composerController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Producer',
          placeholder: 'Optional',
          controller: producerController,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Metadata'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Genre',
          placeholder: 'Pop, Electronic, Indie...',
          controller: genreController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Quick genres',
          suggestions: _genreSuggestions,
          onTap: (g) => genreController.text = g,
        ),
        const SizedBox(height: 14),
        UploadTextField(
          label: 'Mood',
          placeholder: 'Chill, Dark, Upbeat...',
          controller: moodController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Suggested moods',
          suggestions: _moodSuggestions,
          onTap: (m) => moodController.text = m,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Linked artists'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist IDs',
          placeholder: 'Artist IDs (comma or space separated)',
          controller: artistIdsController,
        ),
        const SizedBox(height: 6),
        Text(
          'Tip: use internal artist IDs from the admin / API.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Lyrics'),
        const SizedBox(height: 8),
        UploadLyricsField(
          controller: lyricsController,
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: mediaColumn),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: detailsColumn),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Artwork'),
        const SizedBox(height: 8),
        UploadArtworkPicker(
          selectedImage: selectedImage,
          onTap: selectImage,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Audio file'),
        const SizedBox(height: 8),
        ArtifyAudioPicker(
          selectedAudio: selectedAudio,
          onTapSelectAudio: selectAudio,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        UploadReleaseDateField(
          releaseDate: _releaseDate,
          onTap: _pickReleaseDate,
        ),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Track details'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Song title',
          placeholder: 'Give your track a name',
          controller: songNameController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Composer',
          placeholder: 'Who wrote this track?',
          controller: composerController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Producer',
          placeholder: 'Optional',
          controller: producerController,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Metadata'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Genre',
          placeholder: 'Pop, Electronic, Indie...',
          controller: genreController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Quick genres',
          suggestions: _genreSuggestions,
          onTap: (g) => genreController.text = g,
        ),
        const SizedBox(height: 14),
        UploadTextField(
          label: 'Mood',
          placeholder: 'Chill, Dark, Upbeat...',
          controller: moodController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Suggested moods',
          suggestions: _moodSuggestions,
          onTap: (m) => moodController.text = m,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Linked artists'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist IDs',
          placeholder: 'Artist IDs (comma or space separated)',
          controller: artistIdsController,
        ),
        const SizedBox(height: 6),
        Text(
          'Tip: use internal artist IDs from the admin / API.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Lyrics'),
        const SizedBox(height: 8),
        UploadLyricsField(
          controller: lyricsController,
        ),
      ],
    );
  }

  // ---------- SUGGESTION CHIPS ----------------------------------------------

  Widget _buildSuggestionChips({
    required String label,
    required List<String> suggestions,
    required ValueChanged<String> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: suggestions
              .map(
                (s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withOpacity(0.03),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
