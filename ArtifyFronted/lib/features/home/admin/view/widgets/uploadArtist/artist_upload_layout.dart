import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/admin/view/widgets/uploadArtist/artist_avatar_section.dart';
import 'package:client/features/home/admin/view/widgets/uploadArtist/artist_bio_form.dart';
import 'package:client/features/home/admin/view/widgets/uploadArtist/artist_identity_form.dart';
import 'package:flutter/material.dart';

class ArtistUploadLayout extends StatelessWidget {
  final PickedMedia? selectedImage;
  final VoidCallback onPickImage;
  final TextEditingController nameController;
  final TextEditingController displayNameController;
  final TextEditingController slugController;
  final TextEditingController countryController;
  final TextEditingController bioController;
  final VoidCallback onGenerateSlug;

  const ArtistUploadLayout({
    super.key,
    required this.selectedImage,
    required this.onPickImage,
    required this.nameController,
    required this.displayNameController,
    required this.slugController,
    required this.countryController,
    required this.bioController,
    required this.onGenerateSlug,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Pallete.cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Pallete.borderColor.withOpacity(0.7)),
              ),
              child: isWide ? _buildWide() : _buildNarrow(),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: ArtistAvatarSection(
              center: false, selectedImage: selectedImage, onTap: onPickImage),
        ),
        const SizedBox(width: 32),
        Expanded(child: _buildForms()),
      ],
    );
  }

  Widget _buildNarrow() {
    return Column(children: [
      ArtistAvatarSection(
          center: true, selectedImage: selectedImage, onTap: onPickImage),
      const SizedBox(height: 32),
      _buildForms(),
    ]);
  }

  Widget _buildForms() {
    return Column(children: [
      ArtistIdentityForm(
        nameController: nameController,
        displayNameController: displayNameController,
        slugController: slugController,
        onGenerateSlug: onGenerateSlug,
      ),
      const SizedBox(height: 24),
      ArtistBioForm(
        countryController: countryController,
        bioController: bioController,
        countrySuggestions: const [
          'Italy',
          'USA',
          'UK',
          'France',
          'Japan',
          'Germany',
          'Spain'
        ],
      ),
    ]);
  }
}
