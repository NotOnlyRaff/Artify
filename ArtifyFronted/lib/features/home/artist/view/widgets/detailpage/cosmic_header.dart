import 'dart:ui';

import 'package:client/features/home/artist/view/widgets/detailpage/cosmic_avatar.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/nebula_painter.dart';
import 'package:flutter/material.dart';

class CosmicHeader extends StatelessWidget {
  final String displayName;
  final String? imageUrl;

  const CosmicHeader({required this.displayName, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // Nebula background
          Positioned.fill(
            child: CustomPaint(
              painter: NebulaPainter(),
            ),
          ),
          // Glassmorphism card
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      CosmicAvatar(
                          displayName: displayName, imageUrl: imageUrl),
                      const SizedBox(width: 16),
                      // Additional content
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
