import 'package:flutter/material.dart';

class HangmanPainter extends CustomPainter {
  final int mistakes;
  final Color color;

  HangmanPainter({required this.mistakes, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Base dimensions
    final w = size.width;
    final h = size.height;

    // 1. Base (always visible or first mistake?)
    // Let's say we draw the gallows first if mistakes >= 1 or always?
    // Usually gallows are drawn as mistakes progress or static.
    // Let's assume standard progression:
    // 0: Empty
    // 1: Base
    // 2: Pole
    // 3: Top bar & Rope
    // 4: Head
    // 5: Body
    // 6: Arms
    // 7: Legs

    if (mistakes >= 1) {
      // Base
      canvas.drawLine(Offset(w * 0.1, h), Offset(w * 0.9, h), paint);
    }

    if (mistakes >= 2) {
      // Pole
      canvas.drawLine(Offset(w * 0.2, h), Offset(w * 0.2, h * 0.1), paint);
    }

    if (mistakes >= 3) {
      // Top bar
      canvas.drawLine(
        Offset(w * 0.2, h * 0.1),
        Offset(w * 0.7, h * 0.1),
        paint,
      );
      // Rope
      canvas.drawLine(
        Offset(w * 0.7, h * 0.1),
        Offset(w * 0.7, h * 0.25),
        paint,
      );
    }

    if (mistakes >= 4) {
      // Head
      canvas.drawCircle(Offset(w * 0.7, h * 0.35), h * 0.1, paint);
    }

    if (mistakes >= 5) {
      // Body
      canvas.drawLine(
        Offset(w * 0.7, h * 0.45),
        Offset(w * 0.7, h * 0.75),
        paint,
      );
    }

    if (mistakes >= 6) {
      // Arms
      canvas.drawLine(
        Offset(w * 0.7, h * 0.55),
        Offset(w * 0.6, h * 0.65),
        paint,
      );
      canvas.drawLine(
        Offset(w * 0.7, h * 0.55),
        Offset(w * 0.8, h * 0.65),
        paint,
      );
    }

    if (mistakes >= 7) {
      // Legs
      canvas.drawLine(
        Offset(w * 0.7, h * 0.75),
        Offset(w * 0.6, h * 0.9),
        paint,
      );
      canvas.drawLine(
        Offset(w * 0.7, h * 0.75),
        Offset(w * 0.8, h * 0.9),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(HangmanPainter oldDelegate) {
    return oldDelegate.mistakes != mistakes || oldDelegate.color != color;
  }
}
