import 'dart:ui';

import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SECTION TITLE --------------------------------------------------------------
class SectionTitle extends StatelessWidget {
  final String label;

  const SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFA855F7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ABOUT SECTION --------------------------------------------------------------
class AboutSection extends StatelessWidget {
  final ArtistModel artist;

  const AboutSection({
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final bio = (artist.bio ?? '').trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            bio,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
