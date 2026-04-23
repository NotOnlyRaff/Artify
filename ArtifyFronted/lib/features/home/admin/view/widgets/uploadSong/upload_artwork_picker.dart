// lib/features/home/song/view/widgets/upload_artwork_picker.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart'; // per PickedMedia
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadArtworkPicker extends StatelessWidget {
  final PickedMedia? selectedImage;
  final VoidCallback onTap;

  const UploadArtworkPicker({
    super.key,
    required this.selectedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: selectedImage != null
          ? SizedBox(
              height: 170,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: kIsWeb && selectedImage!.bytes != null
                    ? Image.memory(
                        selectedImage!.bytes!,
                        fit: BoxFit.cover,
                      )
                    : (selectedImage!.asFile != null
                        ? Image.file(
                            selectedImage!.asFile!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Pallete.borderColor,
                          )),
              ),
            )
          : Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Pallete.borderColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to select artwork',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommended: 1:1 ratio, at least 1000x1000 px',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
