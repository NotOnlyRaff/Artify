import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistStudioPage extends ConsumerStatefulWidget {
  const ArtistStudioPage({super.key});

  @override
  ConsumerState<ArtistStudioPage> createState() => _ArtistStudioPageState();
}

class _ArtistStudioPageState extends ConsumerState<ArtistStudioPage> {
  // ───────────────── SONG FORM ─────────────────
  final _songFormKey = GlobalKey<FormState>();
  final _songNameController = TextEditingController();
  final _composerController = TextEditingController();
  final _producerController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();

  // ───────────────── ALBUM FORM ────────────────
  final _albumFormKey = GlobalKey<FormState>();
  final _albumTitleController = TextEditingController();
  final _albumLabelController = TextEditingController();
  final _albumGenreController = TextEditingController();
  final _adminArtistIdController = TextEditingController();

  DateTime? _songReleaseDate;
  DateTime? _albumReleaseDate;

  PickedMedia? _selectedAudio;
  PickedMedia? _selectedSongThumbnail;
  PickedMedia? _selectedAlbumCover;

  String _albumType = 'album';

  bool _submittingSong = false;
  bool _submittingAlbum = false;

  @override
  void dispose() {
    _songNameController.dispose();
    _composerController.dispose();
    _producerController.dispose();
    _genreController.dispose();
    _moodController.dispose();
    _lyricsController.dispose();

    _albumTitleController.dispose();
    _albumLabelController.dispose();
    _albumGenreController.dispose();
    _adminArtistIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserNotifierProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Loader()),
      );
    }

    final isUserOnly = currentUser.role == UserRole.user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          title: Text(
            'Artist Studio',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Pallete.gradient1,
                        Pallete.gradient2,
                        Pallete.gradient3,
                      ],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.library_music_rounded),
                      text: 'Upload Track',
                    ),
                    Tab(
                      icon: Icon(Icons.album_rounded),
                      text: 'Create Album',
                    ),
                  ],
                ),
              ),
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
          child: isUserOnly
              ? _buildForbiddenState(context)
              : TabBarView(
                  children: [
                    _buildSongTab(context, currentUser),
                    _buildAlbumTab(context, currentUser),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildForbiddenState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Pallete.surfacePrimary.withOpacity(0.78),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Pallete.primary.withOpacity(0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Studio access unavailable',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This area is reserved for artists and admins. Standard listener accounts can browse, search and enjoy music, but cannot upload content.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongTab(BuildContext context, UserModel currentUser) {
    final resolvedArtistId = _resolveArtistId(currentUser);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(
                icon: Icons.multitrack_audio_rounded,
                title: 'Release a new track',
                subtitle:
                    'Upload audio, attach a cover, set credits and publish a clean metadata package for your catalog.',
              ),
              const SizedBox(height: 20),
              if (currentUser.role == UserRole.admin) ...[
                _buildAdminArtistTargetCard(),
                const SizedBox(height: 20),
              ],
              _buildSectionCard(
                child: Form(
                  key: _songFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Media'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _mediaPickerCard(
                              label: 'Audio file',
                              value: _selectedAudio?.name,
                              icon: Icons.audio_file_rounded,
                              buttonText: 'Select audio',
                              onTap: () async {
                                final picked = await pickAudio();
                                if (picked != null) {
                                  setState(() {
                                    _selectedAudio = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _mediaPickerCard(
                              label: 'Thumbnail',
                              value: _selectedSongThumbnail?.name,
                              icon: Icons.image_outlined,
                              buttonText: 'Select image',
                              onTap: () async {
                                final picked = await pickImage();
                                if (picked != null) {
                                  setState(() {
                                    _selectedSongThumbnail = picked;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Metadata'),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _songNameController,
                        label: 'Track title',
                        hint: 'Insert the track name',
                        icon: Icons.music_note_rounded,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Track title is required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _composerController,
                              label: 'Composer',
                              hint: 'Who composed the song?',
                              icon: Icons.edit_note_rounded,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Composer is required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              controller: _producerController,
                              label: 'Producer',
                              hint: 'Optional',
                              icon: Icons.tune_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _genreController,
                              label: 'Genre',
                              hint: 'Pop, indie, techno...',
                              icon: Icons.graphic_eq_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              controller: _moodController,
                              label: 'Mood',
                              hint: 'Dark, chill, energetic...',
                              icon: Icons.auto_awesome_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _dateField(
                        label: 'Release date',
                        value: _songReleaseDate,
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _songReleaseDate ?? DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _songReleaseDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _multilineField(
                        controller: _lyricsController,
                        label: 'Lyrics',
                        hint: 'Optional lyrics or notes',
                        icon: Icons.lyrics_outlined,
                      ),
                      const SizedBox(height: 22),
                      _submitButton(
                        loading: _submittingSong,
                        text: 'Upload track',
                        icon: Icons.cloud_upload_rounded,
                        onPressed: resolvedArtistId == null
                            ? null
                            : () => _submitSong(currentUser, resolvedArtistId),
                      ),
                      if (resolvedArtistId == null) ...[
                        const SizedBox(height: 12),
                        _infoText(
                          currentUser.role == UserRole.admin
                              ? 'Admin mode requires a target artist id before uploading a track.'
                              : 'Your account has no linked artist profile yet.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumTab(BuildContext context, UserModel currentUser) {
    final resolvedArtistId = _resolveArtistId(currentUser);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(
                icon: Icons.album_rounded,
                title: 'Create a new album',
                subtitle:
                    'Publish an album shell with cover, release date and catalog metadata. You can later evolve it into a full release flow.',
              ),
              const SizedBox(height: 20),
              if (currentUser.role == UserRole.admin) ...[
                _buildAdminArtistTargetCard(),
                const SizedBox(height: 20),
              ],
              _buildSectionCard(
                child: Form(
                  key: _albumFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Cover'),
                      const SizedBox(height: 14),
                      _mediaPickerCard(
                        label: 'Album cover',
                        value: _selectedAlbumCover?.name,
                        icon: Icons.image_rounded,
                        buttonText: 'Select cover',
                        onTap: () async {
                          final picked = await pickImage();
                          if (picked != null) {
                            setState(() {
                              _selectedAlbumCover = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Album metadata'),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _albumTitleController,
                        label: 'Album title',
                        hint: 'Insert album title',
                        icon: Icons.album_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Album title is required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dateField(
                              label: 'Release date',
                              value: _albumReleaseDate,
                              onPick: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _albumReleaseDate ?? DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _albumReleaseDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdownField(
                              label: 'Album type',
                              value: _albumType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'album',
                                  child: Text('Album'),
                                ),
                                DropdownMenuItem(
                                  value: 'ep',
                                  child: Text('EP'),
                                ),
                                DropdownMenuItem(
                                  value: 'single',
                                  child: Text('Single'),
                                ),
                                DropdownMenuItem(
                                  value: 'compilation',
                                  child: Text('Compilation'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _albumType = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _albumLabelController,
                              label: 'Label',
                              hint: 'Optional label',
                              icon: Icons.business_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              controller: _albumGenreController,
                              label: 'Genre',
                              hint: 'Optional genre',
                              icon: Icons.library_music_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _infoCallout(
                        title: 'Release strategy',
                        body:
                            'This version creates the album metadata and cover in a clean first step. Song linking can be added later once your full release workflow is stabilized.',
                      ),
                      const SizedBox(height: 22),
                      _submitButton(
                        loading: _submittingAlbum,
                        text: 'Create album',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: resolvedArtistId == null
                            ? null
                            : () => _submitAlbum(currentUser, resolvedArtistId),
                      ),
                      if (resolvedArtistId == null) ...[
                        const SizedBox(height: 12),
                        _infoText(
                          currentUser.role == UserRole.admin
                              ? 'Admin mode requires a target artist id before creating an album.'
                              : 'Your account has no linked artist profile yet.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveArtistId(UserModel currentUser) {
    if (currentUser.role == UserRole.admin) {
      final target = _adminArtistIdController.text.trim();
      return target.isEmpty ? null : target;
    }

    return currentUser.artistId;
  }

  Future<void> _submitSong(UserModel currentUser, String artistId) async {
    if (!_songFormKey.currentState!.validate()) {
      showSnackBar(context, 'Complete the track form first.');
      return;
    }

    if (_selectedAudio == null) {
      showSnackBar(context, 'Select an audio file.');
      return;
    }

    if (_selectedSongThumbnail == null) {
      showSnackBar(context, 'Select a thumbnail image.');
      return;
    }

    if (_songReleaseDate == null) {
      showSnackBar(context, 'Select a release date.');
      return;
    }

    setState(() {
      _submittingSong = true;
    });

    try {
      await ref.read(songViewModelProvider.notifier).uploadSong(
        selectedAudio: _selectedAudio!,
        selectedThumbnail: _selectedSongThumbnail!,
        songName: _songNameController.text.trim(),
        releaseDate: _songReleaseDate!,
        composerName: _composerController.text.trim(),
        producerName: _emptyToNull(_producerController.text),
        genre: _emptyToNull(_genreController.text),
        lyrics: _emptyToNull(_lyricsController.text),
        mood: _emptyToNull(_moodController.text),
        artistIds: [artistId],
      );

      final state = ref.read(songViewModelProvider);

      if (state!.hasError) {
        showSnackBar(context, state.error.toString());
        return;
      }

      showSnackBar(context, 'Track uploaded successfully.');
      _clearSongForm();
    } finally {
      if (mounted) {
        setState(() {
          _submittingSong = false;
        });
      }
    }
  }

  Future<void> _submitAlbum(UserModel currentUser, String artistId) async {
    if (!_albumFormKey.currentState!.validate()) {
      showSnackBar(context, 'Complete the album form first.');
      return;
    }

    if (_albumReleaseDate == null) {
      showSnackBar(context, 'Select an album release date.');
      return;
    }

    setState(() {
      _submittingAlbum = true;
    });

    try {
      String? coverUrl;

      if (_selectedAlbumCover != null) {
        final coverUploadRes =
            await ref.read(albumViewModelProvider.notifier).uploadAlbumCover(
                  cover: _selectedAlbumCover!,
                );

        switch (coverUploadRes) {
          case Left(value: final failure):
            showSnackBar(context, failure.message);
            return;
          case Right(value: final uploadedUrl):
            coverUrl = uploadedUrl;
        }
      }

      await ref.read(albumViewModelProvider.notifier).createAlbum(
        title: _albumTitleController.text.trim(),
        releaseDate: _albumReleaseDate,
        label: _emptyToNull(_albumLabelController.text),
        albumType: _albumType,
        genre: _emptyToNull(_albumGenreController.text),
        coverUrl: coverUrl,
        artistIds: [artistId],
      );

      final state = ref.read(albumViewModelProvider);

      if (state!.hasError) {
        showSnackBar(context, state.error.toString());
        return;
      }

      showSnackBar(context, 'Album created successfully.');
      _clearAlbumForm();
    } finally {
      if (mounted) {
        setState(() {
          _submittingAlbum = false;
        });
      }
    }
  }

  void _clearSongForm() {
    _songNameController.clear();
    _composerController.clear();
    _producerController.clear();
    _genreController.clear();
    _moodController.clear();
    _lyricsController.clear();

    setState(() {
      _selectedAudio = null;
      _selectedSongThumbnail = null;
      _songReleaseDate = null;
    });
  }

  void _clearAlbumForm() {
    _albumTitleController.clear();
    _albumLabelController.clear();
    _albumGenreController.clear();

    setState(() {
      _selectedAlbumCover = null;
      _albumReleaseDate = null;
      _albumType = 'album';
    });
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildHeroCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Pallete.surfacePrimary.withOpacity(0.75),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Pallete.primary.withOpacity(0.16),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Pallete.gradient1,
                  Pallete.gradient2,
                ],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminArtistTargetCard() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Admin target artist'),
          const SizedBox(height: 10),
          Text(
            'In admin mode, select which artist entity should receive the uploaded content.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _adminArtistIdController,
            label: 'Target artist id',
            hint: 'Paste the artist id',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _mediaPickerCard({
    required String label,
    required String? value,
    required IconData icon,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value ?? 'No file selected',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  Widget _multilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      minLines: 5,
      maxLines: 7,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          hint: 'Pick a date',
          icon: Icons.calendar_month_rounded,
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
          style: GoogleFonts.plusJakartaSans(
            color: value == null ? Colors.white38 : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(
        label: label,
        hint: '',
        icon: Icons.category_outlined,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Pallete.surfaceSecondary,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _submitButton({
    required bool loading,
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Pallete.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _infoCallout({
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Pallete.accentCyan.withOpacity(0.08),
        border: Border.all(
          color: Pallete.accentCyan.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Pallete.accentCyan,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoText(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white70,
        fontSize: 12.5,
        height: 1.45,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white70,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white38,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: Colors.white60,
              size: 20,
            ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Pallete.gradient2,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Pallete.errorColor,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Pallete.errorColor,
          width: 1.2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}
