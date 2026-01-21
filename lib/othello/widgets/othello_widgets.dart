import 'package:flutter/material.dart';
import '../models/othello_models.dart';

class OthelloBoardWidget extends StatelessWidget {
  final Map<OthelloSquare, OthelloPiece?> board;
  final Function(OthelloSquare) onSquareTap;
  final List<OthelloSquare> validMoves;

  const OthelloBoardWidget({
    super.key,
    required this.board,
    required this.onSquareTap,
    this.validMoves = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32), // Dark Green
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final col = index % 8;
            final square = OthelloSquare(row, col);
            final piece = board[square];
            final isValid = validMoves.contains(square);

            return GestureDetector(
              onTap: () => onSquareTap(square),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      if (isValid)
                        Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (piece != null) OthelloPieceWidget(piece: piece),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class OthelloPieceWidget extends StatelessWidget {
  final OthelloPiece piece;

  const OthelloPieceWidget({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: piece == OthelloPiece.black ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
        gradient: RadialGradient(
          colors: piece == OthelloPiece.black
              ? [Colors.grey[800]!, Colors.black]
              : [Colors.white, Colors.grey[300]!],
          center: const Alignment(-0.3, -0.3),
        ),
      ),
    );
  }
}
