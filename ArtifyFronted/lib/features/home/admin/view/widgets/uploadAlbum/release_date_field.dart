// lib/features/home/admin/view/widgets/uploadAlbum/upload_album_release_date_field.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReleaseDateField extends StatelessWidget {
  final DateTime? releaseDate;
  final VoidCallback onTap;

  const ReleaseDateField({
    super.key,
    required this.releaseDate,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = releaseDate != null;
    final text = hasDate ? _formatDate(releaseDate!) : 'Select release date';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasDate
                ? Pallete.gradient2.withOpacity(0.9)
                : Colors.white.withOpacity(0.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Pallete.gradient2,
                    Color(0xFF811F1A),
                  ],
                ),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: hasDate ? Colors.white : Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
