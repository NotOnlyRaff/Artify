// lib/features/home/admin/view/pages/artist/upload_artist_page.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_artwork_picker.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadArtistPage extends ConsumerStatefulWidget {
  const UploadArtistPage({super.key});

  @override
  ConsumerState<UploadArtistPage> createState() => _UploadArtistPageState();
}

class _UploadArtistPageState extends ConsumerState<UploadArtistPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();

  // Immagine profilo artista (scelta dal dispositivo)
  PickedMedia? selectedImage;

  final List<String> _countrySuggestions = const [
    'United States',
    'United Kingdom',
    'Italy',
    'France',
    'Germany',
    'Spain',
    'Brazil',
    'Mexico',
    'Japan',
    'South Korea',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _slugController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Helper slug
  String _slugFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  // Picker immagine profilo
  Future<void> _selectImage() async {
    final picked = await pickImage();
    if (picked != null) {
      setState(() {
        selectedImage = picked;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final slugText = _slugController.text.trim();
    final country = _countryController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      showSnackBar(context, 'Artist name is required.');
      return;
    }

    final slug = slugText.isEmpty ? _slugFromName(name) : slugText;

    String? imageUrl;
    if (selectedImage != null) {
      final imageRes = await ref
          .read(artistViewModelProvider.notifier)
          .uploadArtistImage(image: selectedImage!);

      switch (imageRes) {
        case Left(value: final failure):
          showSnackBar(context, failure.message);
          return;
        case Right(value: final uploadedUrl):
          imageUrl = uploadedUrl;
      }
    }

    await ref.read(artistViewModelProvider.notifier).createArtist(
          name: name,
          displayName: displayName.isEmpty ? null : displayName,
          slug: slug.isEmpty ? null : slug,
          imageUrl: imageUrl,
          bio: bio.isEmpty ? null : bio,
          country: country.isEmpty ? null : country,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen stato ArtistViewModel
    ref.listen<AsyncValue?>(artistViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (data) {
          showSnackBar(context, 'Artist created successfully.');
          Navigator.pop(context);
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {},
      );
    });

    final isLoading = ref
        .watch(artistViewModelProvider.select((val) => val?.isLoading == true));

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
              'New artist',
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
                'Admin',
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
          // Background
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
            left: -60,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Pallete.gradient2.withOpacity(0.25),
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
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create a new artist profile for your catalog.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Name, identity and profile info in one place.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color:
                                          Pallete.cardColor.withOpacity(0.96),
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
                                        ? _buildWideLayout()
                                        : _buildNarrowLayout(),
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

  // ---------- Avatar section comune (desktop + mobile) ----------------------

  Widget _buildAvatarSection({bool center = true}) {
    final content = Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Profile picture'),
        const SizedBox(height: 10),
        SizedBox(
          width: 140,
          child: UploadArtworkPicker(
            selectedImage: selectedImage,
            onTap: _selectImage,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: square image, min 512×512.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );

    if (center) {
      return Center(child: content);
    }
    return content;
  }

  // ---------- Layouts -------------------------------------------------------

  Widget _buildWideLayout() {
    // Colonna sinistra: avatar + hint
    final avatarColumn = SizedBox(
      width: 220,
      child: _buildAvatarSection(center: false),
    );

    // Colonna centrale: Identity
    final identityColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Identity'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Name',
          placeholder: 'Legal / canonical name',
          controller: _nameController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Display name',
          placeholder: 'Stage name shown in Artify',
          controller: _displayNameController,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Slug',
          placeholder: 'Optional, used in URLs (auto-generated if empty)',
          controller: _slugController,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              _slugController.text = _slugFromName(name);
            },
            child: const Text('Generate from name'),
          ),
        ),
      ],
    );

    // Colonna destra: Profile & bio
    final profileColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Profile & bio'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Country',
          placeholder: 'Country or region (optional)',
          controller: _countryController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Quick countries',
          suggestions: _countrySuggestions,
          onTap: (c) => _countryController.text = c,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Bio'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist bio',
          placeholder: 'Tell listeners who this artist is (optional)...',
          controller: _bioController,
          maxLines: 5,
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar fisso a sinistra
        avatarColumn,
        const SizedBox(width: 24),

        // Form a destra, splittata in due colonne
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: identityColumn),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: profileColumn),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatarSection(center: true),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Identity'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Name',
          placeholder: 'Legal / canonical name',
          controller: _nameController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Display name',
          placeholder: 'Stage name shown in Artify',
          controller: _displayNameController,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Slug',
          placeholder: 'Optional, used in URLs (auto-generated if empty)',
          controller: _slugController,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              _slugController.text = _slugFromName(name);
            },
            child: const Text('Generate from name'),
          ),
        ),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Profile & bio'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Country',
          placeholder: 'Country or region (optional)',
          controller: _countryController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Quick countries',
          suggestions: _countrySuggestions,
          onTap: (c) => _countryController.text = c,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Bio'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist bio',
          placeholder: 'Tell listeners who this artist is (optional)...',
          controller: _bioController,
          maxLines: 5,
        ),
      ],
    );
  }

  // ---------- Suggestion chips ----------------------------------------------

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
