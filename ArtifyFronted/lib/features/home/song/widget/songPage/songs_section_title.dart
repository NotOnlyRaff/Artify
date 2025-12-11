// lib/features/home/song/view/widgets/songs_section_title.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SongsSectionTitle extends StatelessWidget {
  final String title;

  const SongsSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
