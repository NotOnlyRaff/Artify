// lib/features/home/song/view/widgets/upload_release_date_field.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/core/theme/app_pallete.dart';

class UploadReleaseDateField extends StatelessWidget {
  final DateTime? releaseDate;
  final VoidCallback onTap;

  const UploadReleaseDateField({
    super.key,
    required this.releaseDate,
    required this.onTap,
  });

  String _formatReleaseDate(DateTime? d) {
    if (d == null) return 'Select release date';
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.02),
          border: Border.all(
            color: Pallete.borderColor.withOpacity(0.9),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Colors.white70,
            ),
            const SizedBox(width: 10),
            Text(
              _formatReleaseDate(releaseDate),
              style: GoogleFonts.plusJakartaSans(
                color: releaseDate == null ? Colors.white38 : Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
