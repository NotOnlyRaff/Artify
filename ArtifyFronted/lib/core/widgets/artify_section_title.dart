// lib/features/home/song/view/widgets/upload_section_title.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtifySectionTitle extends StatelessWidget {
  final String text;

  const ArtifySectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
