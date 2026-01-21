import 'package:flutter/material.dart';
import '../models/chess_models.dart';

class ChessBoardWidget extends StatelessWidget {
  final Map<ChessSquare, ChessPiece?> board;
  final ChessSquare? selectedSquare;
  final List<ChessSquare> validMoves;
  final Function(ChessSquare) onSquareTap;
  final ChessColor currentPlayer;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.selectedSquare,
    this.validMoves = const [],
    required this.onSquareTap,
    required this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown[900]!, width: 4),
        ),
        child: Column(
          children: List.generate(8, (r) {
            // Rank 7 is top of board for white
            final rank = 7 - r;
            return Expanded(
              child: Row(
                children: List.generate(8, (file) {
                  return Expanded(child: _buildSquare(ChessSquare(rank, file)));
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSquare(ChessSquare square) {
    final isDark = (square.rank + square.file) % 2 == 0;
    final piece = board[square];
    final isSelected = selectedSquare == square;
    final isValidMove = validMoves.contains(square);

    return GestureDetector(
      onTap: () => onSquareTap(square),
      child: Container(
        color: isDark ? Colors.brown[700] : Colors.brown[200],
        child: Stack(
          children: [
            // Highlighting
            if (isSelected)
              Container(color: Colors.yellow.withValues(alpha: 0.4)),
            if (isValidMove)
              Center(
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: piece == null
                        ? Colors.black26
                        : Colors.red.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            // Piece
            if (piece != null) Center(child: ChessPieceWidget(piece: piece)),
          ],
        ),
      ),
    );
  }
}

class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;

  const ChessPieceWidget({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    return Text(
      _getPieceChar(),
      style: TextStyle(
        fontSize: 40,
        color: piece.color == ChessColor.white ? Colors.white : Colors.black,
        shadows: piece.color == ChessColor.white
            ? [const Shadow(color: Colors.black, blurRadius: 2)]
            : [const Shadow(color: Colors.white70, blurRadius: 2)],
      ),
    );
  }

  String _getPieceChar() {
    if (piece.color == ChessColor.white) {
      switch (piece.type) {
        case ChessPieceType.pawn:
          return '♙';
        case ChessPieceType.rook:
          return '♖';
        case ChessPieceType.knight:
          return '♘';
        case ChessPieceType.bishop:
          return '♗';
        case ChessPieceType.queen:
          return '♕';
        case ChessPieceType.king:
          return '♔';
      }
    } else {
      switch (piece.type) {
        case ChessPieceType.pawn:
          return '♟';
        case ChessPieceType.rook:
          return '♜';
        case ChessPieceType.knight:
          return '♞';
        case ChessPieceType.bishop:
          return '♝';
        case ChessPieceType.queen:
          return '♛';
        case ChessPieceType.king:
          return '♚';
      }
    }
  }
}
