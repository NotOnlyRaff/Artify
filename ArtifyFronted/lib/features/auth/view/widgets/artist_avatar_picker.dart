// lib/features/auth/view/widgets/artist_avatar_picker.dart
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistAvatarPicker extends StatelessWidget {
  final PickedMedia? selectedImage;
  final VoidCallback onSelectImage;

  const ArtistAvatarPicker({
    super.key,
    required this.selectedImage,
    required this.onSelectImage,
  });

  @override
  Widget build(BuildContext context) {
    final previewImage = switch ((selectedImage?.bytes, selectedImage?.asFile)) {
      (final bytes?, _) => MemoryImage(bytes) as ImageProvider,
      (_, final file?) => FileImage(file),
      _ => null,
    };

    return Center(
      child: GestureDetector(
        onTap: onSelectImage,
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
                gradient: previewImage == null
                    ? const LinearGradient(
                        colors: [
                          Pallete.gradient1,
                          Pallete.gradient2,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: previewImage != null
                    ? DecorationImage(
                        image: previewImage,
                        fit: BoxFit.cover,
                      )
                    : null,
                color: previewImage == null ? null : Colors.white12,
              ),
              child: previewImage == null
                  ? const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.white,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              'Add profile image',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
