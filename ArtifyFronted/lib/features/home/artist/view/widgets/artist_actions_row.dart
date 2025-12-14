import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ACTIONS --------------------------------------------------------------------
class ArtistActionsRow extends StatelessWidget {
  final ArtistModel artist;

  const ArtistActionsRow({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Play
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: integra col player (play tutta la discografia / top songs)
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              'Play artist',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.gradient2,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Radio / shuffle
        ElevatedButton(
          onPressed: () {
            // TODO: shuffle discografia
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.07),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Icon(Icons.shuffle_rounded, size: 20),
        ),
      ],
    );
  }
}
