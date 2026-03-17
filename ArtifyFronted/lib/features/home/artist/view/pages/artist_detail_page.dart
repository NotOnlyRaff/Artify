import 'dart:ui';

import 'package:client/features/home/artist/view/widgets/detailpage/artist_detail_body.dart';
import 'package:client/features/home/view/widgets/music_slab.dart';
import 'package:client/features/home/view/widgets/space_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistDetailPage extends StatelessWidget {
  final String artistId;

  const ArtistDetailPage({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.14),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: Colors.black.withOpacity(0.10),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Artist profile',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Catalog, identity and releases',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: SpaceBackground(),
          ),
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 88),
                child: ArtistDetailBody(artistId: artistId),
              ),
            ),
          ),
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
