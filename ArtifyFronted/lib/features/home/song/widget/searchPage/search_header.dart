import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Artify',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find tracks, artists and moods in your library.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
