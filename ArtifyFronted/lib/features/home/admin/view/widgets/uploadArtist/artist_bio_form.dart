import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadArtist/suggestion_chips.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:flutter/material.dart';

class ArtistBioForm extends StatelessWidget {
  final TextEditingController countryController;
  final TextEditingController bioController;
  final List<String> countrySuggestions;

  const ArtistBioForm({
    super.key,
    required this.countryController,
    required this.bioController,
    required this.countrySuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Profile & bio'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Country',
          placeholder: 'Country or region (optional)',
          controller: countryController,
        ),
        const SizedBox(height: 6),
        SuggestionChips(
          label: 'Quick countries',
          suggestions: countrySuggestions,
          onTap: (c) => countryController.text = c,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Bio'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist bio',
          placeholder: 'Tell listeners who this artist is...',
          controller: bioController,
          maxLines: 5,
        ),
      ],
    );
  }
}
