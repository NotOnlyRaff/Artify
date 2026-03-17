import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SongsHeader extends StatelessWidget {
  final String? userName;

  const SongsHeader({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final displayName =
        (userName == null || userName!.trim().isEmpty) ? 'Artist' : userName!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good vibes,',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover your next obsession',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
