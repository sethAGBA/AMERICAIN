import 'package:flutter/material.dart';
import '../models/dara_models.dart';

class DaraBoardWidget extends StatelessWidget {
  final Map<DaraSquare, DaraPiece?> board;
  final Function(DaraSquare) onSquareTap;
  final Function(DaraSquare, DaraSquare)? onMove;
  final DaraSquare? selectedSquare;
  final DaraPhase phase;

  const DaraBoardWidget({
    super.key,
    required this.board,
    required this.onSquareTap,
    this.onMove,
    this.selectedSquare,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 6 / 5, // 6 columns, 5 rows
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8D6E63), // Brownish wood-like color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5D4037), width: 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
          ),
          itemCount: 30,
          itemBuilder: (context, index) {
            final r = index ~/ 6;
            final c = index % 6;
            final sq = DaraSquare(r, c);
            final piece = board[sq];
            final isSelected = selectedSquare == sq;

            return GestureDetector(
              onTap: () => onSquareTap(sq),
              child: DragTarget<DaraSquare>(
                onWillAcceptWithDetails: (details) {
                  if (phase != DaraPhase.move || piece != null) return false;
                  final from = details.data;
                  return (from.row - r).abs() + (from.col - c).abs() == 1;
                },
                onAcceptWithDetails: (details) {
                  onMove?.call(details.data, sq);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF5D4037).withValues(alpha: 0.5),
                      ),
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : (candidateData.isNotEmpty
                                ? Colors.green.withValues(alpha: 0.3)
                                : null),
                    ),
                    child: Center(
                      child: piece != null
                          ? (phase == DaraPhase.move
                                ? Draggable<DaraSquare>(
                                    data: sq,
                                    feedback: DaraPieceWidget(
                                      piece: piece,
                                      size: 50,
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: DaraPieceWidget(piece: piece),
                                    ),
                                    child: DaraPieceWidget(piece: piece),
                                  )
                                : DaraPieceWidget(piece: piece))
                          : null,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class DaraPieceWidget extends StatelessWidget {
  final DaraPiece piece;
  final double? size;

  const DaraPieceWidget({super.key, required this.piece, this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size ?? 40,
      height: size ?? 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: piece == DaraPiece.player1 ? Colors.white : Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        gradient: RadialGradient(
          colors: piece == DaraPiece.player1
              ? [Colors.white, Colors.grey.shade300]
              : [Colors.grey.shade800, Colors.black],
          center: const Alignment(-0.3, -0.3),
        ),
      ),
    );
  }
}
