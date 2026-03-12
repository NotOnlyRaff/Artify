//lib/features/home/admin/view/widgets/uploadAlbum/upload_album_header.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadAlbumHeader extends StatelessWidget {
  const UploadAlbumHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a new album in your Artify catalog.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Artwork, tracklist and metadata — split into focused tabs.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
