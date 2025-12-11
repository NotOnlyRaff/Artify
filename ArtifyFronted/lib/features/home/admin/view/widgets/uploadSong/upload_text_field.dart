// lib/features/home/song/widget/UploadSong/upload_text_field.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool required;
  final int maxLines;

  const UploadTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + badge "Required"
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Text(
                  'Required',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13,
          ),
          cursorColor: Pallete.gradient2,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.02),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
        ),
      ],
    );
  }
}
