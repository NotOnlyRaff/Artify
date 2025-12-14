import 'package:client/features/home/artist/view/widgets/artist_detail_body.dart';
import 'package:client/features/home/view/widgets/music_slab.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistDetailPage extends StatelessWidget {
  final String artistId;

  const ArtistDetailPage({super.key, required this.artistId});

  @override
  Widget build(BuildContext context) {
    // Codice di rendering della pagina principale
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050509),
            Color(0xFF060317),
            Color(0xFF140832),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            'Artist profile',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
        body: Stack(
          children: [
            // Artist Detail Body
            SafeArea(
              child: ArtistDetailBody(artistId: artistId),
            ),
            // MusicSlab
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: const MusicSlab(),
            ),
          ],
        ),
      ),
    );
  }
}
