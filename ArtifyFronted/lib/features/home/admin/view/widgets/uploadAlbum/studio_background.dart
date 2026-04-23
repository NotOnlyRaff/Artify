//lib/features/home/admin/view/widgets/uploadAlbum/studio_background.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class StudioBackground extends StatelessWidget {
  const StudioBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050509), Color(0xFF140813)],
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Pallete.gradient2.withOpacity(0.26),
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
