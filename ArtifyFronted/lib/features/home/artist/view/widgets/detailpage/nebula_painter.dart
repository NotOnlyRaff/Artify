import 'package:flutter/material.dart';

class NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.2, size.height * 0.1);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF8B5CF6),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 140));

    canvas.drawCircle(center, 140, paint);

    final center2 = Offset(size.width * 0.8, size.height * 0.8);
    final paint2 = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF22D3EE),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center2, radius: 160));
    canvas.drawCircle(center2, 160, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
