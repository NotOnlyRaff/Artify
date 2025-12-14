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
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
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

  // Search artists
  final TextEditingController _artistSearchController = TextEditingController();
  String _artistSearchQuery = '';
  final List<ArtistModel> _selectedArtists = [];

  /// Ruolo associato per ogni artista selezionato
  /// (oggi NON lo inviamo ancora al backend, ma è pronto per quando vorrai).
  final Map<String, SongArtistRole> _artistRoles = {};

  // --- RELEASE DATE ---
  DateTime? _releaseDate;

  // --- MEDIA PICKED ---
  PickedMedia? selectedImage;
  PickedMedia? selectedAudio;

  final formKey = GlobalKey<FormState>();

  // Tab correntemente selezionata: 0 = Track, 1 = Artists, 2 = Details
  int _currentTabIndex = 0;

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
    _artistSearchController.dispose();
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

  // ---------- ARTIST MANAGEMENT ----------

  void _onSelectArtist(ArtistModel artist) {
    setState(() {
      if (_selectedArtists.any((a) => a.id == artist.id)) return;

      _selectedArtists.add(artist);

      // Di default il primo è PRIMARY, gli altri FEATURED
      if (_selectedArtists.length == 1) {
        _artistRoles[artist.id] = SongArtistRole.primary;
      } else {
        _artistRoles[artist.id] = SongArtistRole.featured;
      }
    });
  }

  void _onRemoveArtist(ArtistModel artist) {
    setState(() {
      _selectedArtists.removeWhere((a) => a.id == artist.id);
      _artistRoles.remove(artist.id);
    });
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

    if (songName.isEmpty ||
        composerName.isEmpty ||
        _releaseDate == null ||
        selectedAudio == null ||
        selectedImage == null) {
      // Se mancano campi chiave, ti porto sulla tab "giusta"
      if (selectedAudio == null || selectedImage == null) {
        setState(() => _currentTabIndex = 0); // Track
      } else if (_releaseDate == null || genre.isEmpty || mood.isEmpty) {
        setState(() => _currentTabIndex = 2); // Details
      }

      showSnackBar(
        context,
        'Please fill song name, composer, release date and select audio + artwork.',
      );
      return;
    }

    final audioFile = selectedAudio!;
    final imageFile = selectedImage!;

    // IDs degli artisti selezionati (da search)
    final artistIds = _selectedArtists.map((a) => a.id).toList();

    // Se in futuro vorrai mandare i ruoli al backend, hai già questa struttura:
    // final artistRolesPayload = _selectedArtists
    //     .map((a) => {
    //           'artist_id': a.id,
    //           'role':
    //               (_artistRoles[a.id] ?? SongArtistRole.primary).value,
    //         })
    //     .toList();

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
          // Background gradient + glow
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
                                'Upload a new song to your Artify catalog.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Audio, artwork and metadata — split in focused tabs.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Card principale con TAB
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

  // ---------- TAB SWITCHER ---------------------------------------------------

  Widget _buildTabSwitcher() {
    final tabs = [
      ('Track', Icons.music_note_rounded),
      ('Artists', Icons.people_alt_rounded),
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
        return _buildTrackTab(context);
      case 1:
        return _buildArtistTab(context);
      case 2:
      default:
        return _buildDetailsTab(context);
    }
  }

  // ---------- TAB: TRACK -----------------------------------------------------

  Widget _buildTrackTab(BuildContext context) {
    return Column(
      key: const ValueKey('tab-track'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Artwork & audio'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // dimensione massima della miniatura in base allo spazio
            final maxWidth = constraints.maxWidth;
            final coverSize = maxWidth < 400
                ? 140.0 // schermi piccoli
                : maxWidth < 700
                    ? 180.0 // tablet / web stretto
                    : 200.0; // web largo

            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: coverSize,
                child: AspectRatio(
                  aspectRatio: 1, // 1:1, stile copertina album
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: UploadArtworkPicker(
                      selectedImage: selectedImage,
                      onTap: selectImage,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ArtifyAudioPicker(
          selectedAudio: selectedAudio,
          onTapSelectAudio: selectAudio,
        ),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Track text'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Song title',
          placeholder: 'Give your track a name',
          controller: songNameController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Composer(s)',
          placeholder: 'Who wrote this track?',
          controller: composerController,
          required: true,
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

  // ---------- TAB: ARTISTS ---------------------------------------------------

  Widget _buildArtistTab(BuildContext context) {
    final trimmedQuery = _artistSearchQuery.trim();
    final bool enableSearch = trimmedQuery.length >= 2;

    final artistsAsync = enableSearch
        ? ref.watch(
            getArtistsProvider(
              search: trimmedQuery,
            ),
          )
        : const AsyncValue<List<ArtistModel>>.data([]);

    return Column(
      key: const ValueKey('tab-artists'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Linked artists & roles'),
        const SizedBox(height: 8),

        // Lista artisti selezionati con ruolo
        if (_selectedArtists.isNotEmpty)
          Column(
            children: _selectedArtists.map((artist) {
              final displayName = artist.displayName?.isNotEmpty == true
                  ? artist.displayName!
                  : artist.name;
              final currentRole = _artistRoles[artist.id] ??
                  (_selectedArtists.first.id == artist.id
                      ? SongArtistRole.primary
                      : SongArtistRole.featured);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      child: Text(
                        (displayName.isNotEmpty ? displayName[0] : '?')
                            .toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Artist role',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<SongArtistRole>(
                        dropdownColor: const Color(0xFF111018),
                        value: currentRole,
                        items: SongArtistRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role.value,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _artistRoles[artist.id] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => _onRemoveArtist(artist),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Text(
            'No artists linked yet. Use the search below to attach them to this track.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),

        const SizedBox(height: 18),

        Text(
          'Search & link artists',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        // Campo ricerca
        TextField(
          controller: _artistSearchController,
          onChanged: (value) {
            setState(() {
              _artistSearchQuery = value;
            });
          },
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search artist by name...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Pallete.gradient2,
                width: 1.2,
              ),
            ),
            suffixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Colors.white54,
            ),
          ),
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

        // Risultati di ricerca
        if (enableSearch)
          artistsAsync.when(
            data: (artists) {
              final filtered = artists
                  .where((a) => !_selectedArtists.any((sel) => sel.id == a.id))
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filtered.take(6).map((artist) {
                  final displayName = artist.displayName?.isNotEmpty == true
                      ? artist.displayName!
                      : artist.name;

                  return InkWell(
                    onTap: () => _onSelectArtist(artist),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Pallete.gradient2,
                ),
              ),
            ),
            error: (e, _) => Text(
              e.toString(),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ),

        const SizedBox(height: 24),

        const ArtifySectionTitle('Production'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Producer',
          placeholder: 'Optional',
          controller: producerController,
        ),
      ],
    );
  }

  // ---------- TAB: DETAILS ---------------------------------------------------

  Widget _buildDetailsTab(BuildContext context) {
    return Column(
      key: const ValueKey('tab-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        UploadReleaseDateField(
          releaseDate: _releaseDate,
          onTap: _pickReleaseDate,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
