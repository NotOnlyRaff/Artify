import 'package:particles_flutter/particles_engine.dart';
import 'package:particles_flutter/particles.dart';
import 'package:flutter/material.dart';

class SpaceBackground extends StatelessWidget {
  const SpaceBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
        Particles(
          height: size.height,
          width: size.width,
          awayRadius: 150,
          // crea lista di particelle
          particles: List.generate(
            100,
            (index) => Particle(
              position: Offset(
                (index % 10) * (size.width / 10),
                (index % 10) * (size.height / 10),
              ),
              color: Colors.white.withValues(alpha: 0.15),
              size: 2 + (index % 3).toDouble(),
              velocity: Offset(
                (index % 5) * 0.5,
                (index % 7) * 0.5,
              ),
            ),
          ),
          connectDots: false, // rimuove le linee tra le particelle
          onTapAnimation: true,
          enableHover: false,
        ),
      ],
    );
  }
}
