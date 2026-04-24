import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_artwork_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistAvatarSection extends StatelessWidget {
  final PickedMedia? selectedImage;
  final VoidCallback onTap;
  final bool center;

  const ArtistAvatarSection({
    super.key,
    required this.selectedImage,
    required this.onTap,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Profile picture'),
        const SizedBox(height: 10),
        SizedBox(
          width: 140,
          child: UploadArtworkPicker(
            selectedImage: selectedImage,
            onTap: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: square image, minimum 512x512.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
