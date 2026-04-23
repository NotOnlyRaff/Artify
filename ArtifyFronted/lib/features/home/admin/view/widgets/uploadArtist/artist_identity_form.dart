import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:flutter/material.dart';

class ArtistIdentityForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController displayNameController;
  final TextEditingController slugController;
  final VoidCallback onGenerateSlug;

  const ArtistIdentityForm({
    super.key,
    required this.nameController,
    required this.displayNameController,
    required this.slugController,
    required this.onGenerateSlug,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Identity'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Name',
          placeholder: 'Legal / canonical name',
          controller: nameController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Display name',
          placeholder: 'Stage name shown in Artify',
          controller: displayNameController,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Slug',
          placeholder: 'Optional, used in URLs',
          controller: slugController,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onGenerateSlug,
            child: const Text('Generate from name'),
          ),
        ),
      ],
    );
  }
}
