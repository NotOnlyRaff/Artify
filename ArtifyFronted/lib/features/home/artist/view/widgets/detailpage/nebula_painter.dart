import 'package:flutter/material.dart';

class NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF8B5CF6),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.18, size.height * 0.16),
          radius: size.width * 0.42,
        ),
      );

    final paint2 = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF22D3EE),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.86, size.height * 0.78),
          radius: size.width * 0.46,
        ),
      );

    final paint3 = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF97316),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.62, size.height * 0.24),
          radius: size.width * 0.24,
        ),
      );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF09090F),
    );

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.16),
      size.width * 0.42,
      paint1,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.78),
      size.width * 0.46,
      paint2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.24),
      size.width * 0.24,
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
