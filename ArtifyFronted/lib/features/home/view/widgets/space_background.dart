import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';

class SpaceBackground extends StatelessWidget {
  const SpaceBackground({super.key});

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF04050E),
                Color(0xFF0A0E1A),
              ],
            ),
          ),
        ),

        // il widget corretto per particelle
        const ParticleNetwork(
          particleCount: 70,
          maxSpeed: 0.5,
          maxSize: 2,
          lineDistance: 100,
          particleColor: Colors.white24,
          lineColor: Colors.white12,
          touchActivation: true,
        )
      ],
    );
  }
}
