import 'package:flutter/material.dart';
import '../models/fanorona_game_state.dart';

class FanoronaBoardPainter extends CustomPainter {
  final Map<BoardPoint, FanoronaPiece?> board;
  final List<BoardPoint> validMoves;
  final BoardPoint? selectedPoint;
  final bool showHints;

  FanoronaBoardPainter({
    required this.board,
    required this.validMoves,
    this.selectedPoint,
    this.showHints = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[300]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / 8;
    final cellHeight = size.height / 4;

    // Draw Grid Lines
    for (int y = 0; y < 5; y++) {
      // Horizontal lines
      canvas.drawLine(
        Offset(0, y * cellHeight),
        Offset(size.width, y * cellHeight),
        paint,
      );
    }

    for (int x = 0; x < 9; x++) {
      // Vertical lines
      canvas.drawLine(
        Offset(x * cellWidth, 0),
        Offset(x * cellWidth, size.height),
        paint,
      );
    }

    // Diagonal lines: only if (x + y) % 2 == 0
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 8; x++) {
        if ((x + y) % 2 == 0) {
          // Top-Left to Bottom-Right
          canvas.drawLine(
            Offset(x * cellWidth, y * cellHeight),
            Offset((x + 1) * cellWidth, (y + 1) * cellHeight),
            paint,
          );
          // Top-Right to Bottom-Left (from next x)
          canvas.drawLine(
            Offset((x + 1) * cellWidth, y * cellHeight),
            Offset(x * cellWidth, (y + 1) * cellHeight),
            paint,
          );
        }
      }
    }

    // Highlight valid moves
    if (showHints) {
      final highlightPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      for (var move in validMoves) {
        canvas.drawCircle(
          Offset(move.x * cellWidth, move.y * cellHeight),
          10.0,
          highlightPaint,
        );
      }
    }

    // Highlight selected piece
    if (selectedPoint != null) {
      final selectedPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(
        Offset(selectedPoint!.x * cellWidth, selectedPoint!.y * cellHeight),
        20.0,
        selectedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FanoronaBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.validMoves != validMoves ||
        oldDelegate.selectedPoint != selectedPoint;
  }
}

class FanoronaPieceWidget extends StatelessWidget {
  final FanoronaPiece type;
  final bool isCapturing;

  const FanoronaPieceWidget({
    super.key,
    required this.type,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: type == FanoronaPiece.white ? Colors.white : Colors.black,
        border: isCapturing
            ? Border.all(color: Colors.amber, width: 3)
            : Border.all(color: Colors.grey[700]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: type == FanoronaPiece.white
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
              ),
            )
          : null,
    );
  }
}
