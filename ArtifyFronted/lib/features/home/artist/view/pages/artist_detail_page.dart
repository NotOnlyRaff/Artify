import 'package:client/features/home/artist/view/widgets/artist_detail_body.dart';
import 'package:client/features/home/view/widgets/music_slab.dart';
import 'package:client/features/home/view/widgets/space_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistDetailPage extends StatelessWidget {
  final String artistId;

  const ArtistDetailPage({super.key, required this.artistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // vogliamo che il body possa “andare sotto” la system bar
      extendBody: true,
      backgroundColor: Colors.transparent,
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
          // 🌌 SFONDO SPAZIALE COERENTE CON IL RESTO DELL’APP
          const Positioned.fill(
            child: SpaceBackground(),
          ),

          // 📄 CONTENUTO DELL’ARTISTA
          Positioned.fill(
            child: SafeArea(
              top: false, // l'AppBar già gestisce la top area
              bottom: false,
              child: Padding(
                // lasciamo spazio in basso per non coprire con lo slab
                padding: const EdgeInsets.only(bottom: 88),
                child: ArtistDetailBody(artistId: artistId),
              ),
            ),
          ),

          // 🎵 MUSIC SLAB FISSO IN BASSO
          const Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: MusicSlab(),
            ),
          ),
        ],
      ),
    );
  }
}
