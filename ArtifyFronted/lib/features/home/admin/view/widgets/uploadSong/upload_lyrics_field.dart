// lib/features/home/song/view/widgets/upload_lyrics_field.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadLyricsField extends StatelessWidget {
  final TextEditingController controller;

  const UploadLyricsField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 13,
      ),
      cursorColor: Pallete.gradient2,
      decoration: InputDecoration(
        hintText: 'Write your lyrics here (optional)...',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Pallete.borderColor.withOpacity(0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Pallete.gradient2,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
