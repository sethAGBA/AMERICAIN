import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_piece.dart';
import '../ludo_layout_helper.dart';
import '../ludo_logic.dart';
import 'ludo_piece_widget.dart';
import '../providers/ludo_provider.dart'; // To access notifier for moves

class LudoBoard extends ConsumerWidget {
  final LudoGameState gameState;

  const LudoBoard({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        // Move border and shadow OUTSIDE the LayoutBuilder to avoid affecting inner constraints
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = constraints.maxWidth;
            final cellSize = boardSize / 15;
            final pieceSize = cellSize * 0.95; // Larger pieces

            return Stack(
              children: [
                // 1. Valid Board Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: LudoBoardPainter(players: gameState.players),
                  ),
                ),

                // 2. Render Pieces
                ..._buildPieces(context, ref, boardSize, cellSize, pieceSize),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildPieces(
    BuildContext context,
    WidgetRef ref,
    double boardSize,
    double cellSize,
    double pieceSize,
  ) {
    // 1. Group pieces by Player and Coordinates
    // Key: String "colorIndex_x_y"
    final Map<String, List<LudoPiece>> groups = {};

    for (var player in gameState.players) {
      if (player.type == PlayerType.none) continue;
      for (var piece in player.pieces) {
        final coords = LudoLayoutHelper.getCoordinates(piece);
        final key = "${player.color.index}_${coords.dx}_${coords.dy}";

        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(piece);
      }
    }

    // 2. Build Widgets from Groups
    final List<Widget> pieceWidgets = [];

    groups.forEach((key, pieces) {
      final firstPiece = pieces.first;
      final coords = LudoLayoutHelper.getCoordinates(firstPiece);

      final double left = coords.dx * cellSize + (cellSize - pieceSize) / 2;
      final double top = coords.dy * cellSize + (cellSize - pieceSize) / 2;

      final isCurrentPlayer = firstPiece.color == gameState.currentPlayer.color;

      pieceWidgets.add(
        Positioned(
          left: left,
          top: top,
          child: LudoPieceWidget(
            color: firstPiece.color,
            size: pieceSize,
            count: pieces.length,
            isSelected:
                isCurrentPlayer &&
                gameState.turnState == LudoTurnState.waitingForMove &&
                gameState.diceValues.isNotEmpty,
            onTap: () {
              if (isCurrentPlayer) {
                // If grouped, tapping moves any valid piece in the group.
                // We just pick the first one from the group.
                ref.read(ludoProvider.notifier).movePiece(firstPiece.id);
              }
            },
          ),
        ),
      );
    });

    return pieceWidgets;
  }
}

class LudoBoardPainter extends CustomPainter {
  final List<LudoPlayer> players;

  LudoBoardPainter({required this.players});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cellW = w / 15;
    final cellH = h / 15;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // 1. Draw 4 Corner Bases (6x6)
    // Red Base (Top-Left)
    _drawBase(
      canvas,
      0,
      0,
      cellW,
      cellH,
      players[0].type == PlayerType.none ? Colors.grey.shade300 : Colors.red,
      paint,
    );
    // Green Base (Top-Right)
    _drawBase(
      canvas,
      9 * cellW,
      0,
      cellW,
      cellH,
      players[1].type == PlayerType.none ? Colors.grey.shade300 : Colors.green,
      paint,
    );
    // Yellow Base (Bottom-Right)
    _drawBase(
      canvas,
      9 * cellW,
      9 * cellH,
      cellW,
      cellH,
      players[2].type == PlayerType.none ? Colors.grey.shade300 : Colors.yellow,
      paint,
    );
    // Blue Base (Bottom-Left)
    _drawBase(
      canvas,
      0,
      9 * cellH,
      cellW,
      cellH,
      players[3].type == PlayerType.none ? Colors.grey.shade300 : Colors.blue,
      paint,
    );

    // 2. Center Home Triangle
    _drawCenter(canvas, size, paint);

    // 3. Tracks
    // We can draw the grid lines
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, h), strokePaint);
      canvas.drawLine(Offset(0, i * cellH), Offset(w, i * cellH), strokePaint);
    }

    // 4. Safe Zones (Stars)
    for (final index in LudoLogic.safeSpots) {
      final coords = LudoLayoutHelper.getTrackPosition(index);
      final left = coords.dx * cellW;
      final top = coords.dy * cellH;

      // Draw a simple star icon or shape
      _drawStar(canvas, left + cellW / 2, top + cellH / 2, cellW * 0.6, paint);
    }
    // 5. Exit Squares (Colored)
    final startPositions = {
      Colors.red: 0,
      Colors.green: 13,
      Colors.yellow: 26,
      Colors.blue: 39,
    };

    startPositions.forEach((color, index) {
      final coords = LudoLayoutHelper.getTrackPosition(index);
      paint.color = color.withValues(alpha: 0.5);
      canvas.drawRect(
        Rect.fromLTWH(coords.dx * cellW, coords.dy * cellH, cellW, cellH),
        paint,
      );
    });

    // Fill Colored Paths (Home Stretches)
    // Red Stretch (Lines 1-5, Col 7) -> actually horizontal from left?
    // Standard Ludo Orientation:
    // Red (Top-Left), Green (Top-Right), Yellow (Bottom-Right), Blue (Bottom-Left)
    // Track usually runs clockwise.
    // Red Home Stretch: From (1,7) to (5,7)? No.
    // Let's assume standard grid mapping.
    // Red Home Stretch: (1, 6) to (5, 6) ??
    // Need a specific coordinate map.
    // For MVP, just coloring the middle strips roughly.

    // Red Strip (Left middle row)
    paint.color = Colors.red.withValues(alpha: 0.3); // Light Red
    canvas.drawRect(Rect.fromLTWH(cellW, 7 * cellH, 5 * cellW, cellH), paint);

    // Green Strip (Top middle col)
    paint.color = Colors.green.withValues(alpha: 0.3);
    canvas.drawRect(Rect.fromLTWH(7 * cellW, cellH, cellW, 5 * cellH), paint);

    // Yellow Strip (Right middle row)
    paint.color = Colors.yellow.withValues(alpha: 0.3);
    canvas.drawRect(
      Rect.fromLTWH(9 * cellW, 7 * cellH, 5 * cellW, cellH),
      paint,
    );

    // Blue Strip (Bottom middle col)
    paint.color = Colors.blue.withValues(alpha: 0.3);
    canvas.drawRect(
      Rect.fromLTWH(7 * cellW, 9 * cellH, cellW, 5 * cellH),
      paint,
    );
  }

  void _drawBase(
    Canvas canvas,
    double x,
    double y,
    double cw,
    double ch,
    Color color,
    Paint paint,
  ) {
    paint.color = color;
    canvas.drawRect(Rect.fromLTWH(x, y, 6 * cw, 6 * ch), paint);

    // Inner white square
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cw, y + ch, 4 * cw, 4 * ch), paint);
  }

  void _drawCenter(Canvas canvas, Size size, Paint paint) {
    final c = size.center(Offset.zero);
    final boxSize = size.width / 5; // 3x3 cells in middle = 3 * (w/15) = w/5

    // Draw the triangles
    // Top (Green)
    paint.color = Colors.green;
    Path p = Path();
    p.moveTo(c.dx, c.dy);
    p.lineTo(c.dx - boxSize / 2, c.dy - boxSize / 2);
    p.lineTo(c.dx + boxSize / 2, c.dy - boxSize / 2);
    p.close();
    canvas.drawPath(p, paint);

    // Right (Yellow)
    paint.color = Colors.yellow;
    p = Path();
    p.moveTo(c.dx, c.dy);
    p.lineTo(c.dx + boxSize / 2, c.dy - boxSize / 2);
    p.lineTo(c.dx + boxSize / 2, c.dy + boxSize / 2);
    p.close();
    canvas.drawPath(p, paint);

    // Bottom (Blue)
    paint.color = Colors.blue;
    p = Path();
    p.moveTo(c.dx, c.dy);
    p.lineTo(c.dx + boxSize / 2, c.dy + boxSize / 2);
    p.lineTo(c.dx - boxSize / 2, c.dy + boxSize / 2);
    p.close();
    canvas.drawPath(p, paint);

    // Left (Red)
    paint.color = Colors.red;
    p = Path();
    p.moveTo(c.dx, c.dy);
    p.lineTo(c.dx - boxSize / 2, c.dy + boxSize / 2);
    p.lineTo(c.dx - boxSize / 2, c.dy - boxSize / 2);
    p.close();
    canvas.drawPath(p, paint);
  }

  void _drawStar(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Paint paint,
  ) {
    // Draw a semi-transparent circle for Safe Zone
    paint.color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), size / 2.5, paint);

    // Draw a border
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade700
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), size / 3, stroke);

    // Center dot
    paint.color = Colors.grey.shade600;
    canvas.drawCircle(Offset(cx, cy), size / 6, paint);
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter oldDelegate) {
    return oldDelegate.players != players;
  }
}
