import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudioBadge extends StatelessWidget {
  final String label;
  const StudioBadge({super.key, this.label = 'Studio'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      ),
    );
  }
}
