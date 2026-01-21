import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chess_models.dart';

final chessProvider = StateNotifierProvider<ChessNotifier, ChessGameState>((
  ref,
) {
  return ChessNotifier();
});

class ChessNotifier extends StateNotifier<ChessGameState> {
  ChessNotifier() : super(ChessGameState.initial()) {
    _loadSavedGame();
  }

  static const _saveKey = 'chess_game_state';

  Future<void> _loadSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_saveKey);
      if (savedData != null) {
        final decoded = json.decode(savedData);
        state = ChessGameState.fromJson(decoded);

        // If it was bot turn, trigger it
        if (state.isSolo &&
            state.currentPlayer == ChessColor.black &&
            (state.status == ChessStatus.playing ||
                state.status == ChessStatus.check)) {
          _makeBotMove();
        }
      }
    } catch (e) {
      debugPrint('Error loading Chess game: $e');
    }
  }

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(state.toJson());
      await prefs.setString(_saveKey, jsonData);
    } catch (e) {
      debugPrint('Error saving Chess game: $e');
    }
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  void startGame({bool isSolo = false}) {
    state = ChessGameState.initial(isSolo: isSolo);
    _saveGame();
  }

  void resetGame() {
    state = ChessGameState.initial(isSolo: state.isSolo);
    _saveGame();
  }

  void selectSquare(ChessSquare square) {
    if (state.status != ChessStatus.playing &&
        state.status != ChessStatus.check) {
      return;
    }

    // Block human moves if it's bot turn
    if (state.isSolo && state.currentPlayer == ChessColor.black) return;

    final piece = state.board[square];

    // If a piece is already selected, try to move
    if (state.selectedSquare != null) {
      if (state.validMoves.contains(square)) {
        movePiece(state.selectedSquare!, square);
        return;
      }
    }

    // Otherwise, select the square if it has a piece of the current player
    if (piece != null && piece.color == state.currentPlayer) {
      final moves = getValidMoves(square);
      state = state.copyWith(selectedSquare: square, validMoves: moves);
    } else {
      state = state.copyWith(clearSelectedSquare: true, validMoves: []);
    }
  }

  void movePiece(ChessSquare from, ChessSquare to) {
    final piece = state.board[from];
    if (piece == null) return;

    final newBoard = Map<ChessSquare, ChessPiece?>.from(state.board);

    // Handle special moves like Castling/En Passant would go here
    // For now, simple move
    newBoard[to] = piece.copyWith(hasMoved: true);
    newBoard[from] = null;

    // Check for promotion
    if (piece.type == ChessPieceType.pawn && (to.rank == 0 || to.rank == 7)) {
      // Delay turn switch for promotion
      state = state.copyWith(
        board: newBoard,
        promotionPiece:
            ChessPieceType.queen, // Default for now, should show dialog
        clearSelectedSquare: true,
        validMoves: [],
      );
      _finalizeMove(to); // For now just auto-promote to queen
      return;
    }

    final newMoveHistory = [...state.moveHistory, '$from to $to'];

    state = state.copyWith(
      board: newBoard,
      clearSelectedSquare: true,
      validMoves: [],
      currentPlayer: state.currentPlayer == ChessColor.white
          ? ChessColor.black
          : ChessColor.white,
      moveHistory: newMoveHistory,
    );

    _checkGameState();
    _saveGame();

    // Trigger bot if Solo
    if (state.isSolo &&
        state.currentPlayer == ChessColor.black &&
        (state.status == ChessStatus.playing ||
            state.status == ChessStatus.check)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _makeBotMove();
      });
    }
  }

  void _makeBotMove() {
    final move = _getBestMove();
    if (move != null) {
      movePiece(move.from, move.to);
    }
  }

  _Move? _getBestMove() {
    final moves = _getAllLegalMoves(ChessColor.black, state.board);
    if (moves.isEmpty) return null;

    _Move? bestMove;
    double bestValue = double.negativeInfinity;

    for (var move in moves) {
      final tempBoard = _simulateMove(state.board, move.from, move.to);
      // Depth 2 minimax
      final value = -_minimax(
        tempBoard,
        1,
        double.negativeInfinity,
        double.infinity,
        false,
      );
      if (value > bestValue) {
        bestValue = value;
        bestMove = move;
      }
    }
    return bestMove;
  }

  double _minimax(
    Map<ChessSquare, ChessPiece?> board,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
  ) {
    if (depth == 0) return _evaluateBoard(board);

    final color = isMaximizing ? ChessColor.black : ChessColor.white;
    final moves = _getAllLegalMoves(color, board);

    if (moves.isEmpty) {
      if (_isKingInCheckOnBoard(color, board)) {
        return isMaximizing ? -10000 : 10000;
      }
      return 0; // Stalemate
    }

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (var move in moves) {
        final tempBoard = _simulateMove(board, move.from, move.to);
        final eval = _minimax(tempBoard, depth - 1, alpha, beta, false);
        maxEval = _max(maxEval, eval);
        alpha = _max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (var move in moves) {
        final tempBoard = _simulateMove(board, move.from, move.to);
        final eval = _minimax(tempBoard, depth - 1, alpha, beta, true);
        minEval = _min(minEval, eval);
        beta = _min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  double _evaluateBoard(Map<ChessSquare, ChessPiece?> board) {
    double score = 0;
    board.forEach((square, piece) {
      if (piece != null) {
        final val = _getPieceValue(piece.type);
        score += (piece.color == ChessColor.black ? val : -val);
      }
    });
    return score;
  }

  double _getPieceValue(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.pawn:
        return 10;
      case ChessPieceType.knight:
        return 30;
      case ChessPieceType.bishop:
        return 30;
      case ChessPieceType.rook:
        return 50;
      case ChessPieceType.queen:
        return 90;
      case ChessPieceType.king:
        return 900;
    }
  }

  List<_Move> _getAllLegalMoves(
    ChessColor color,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    final List<_Move> allMoves = [];
    board.forEach((square, piece) {
      if (piece != null && piece.color == color) {
        final moves = getValidMovesForSimulation(square, board, color);
        for (var to in moves) {
          allMoves.add(_Move(square, to));
        }
      }
    });
    return allMoves;
  }

  Map<ChessSquare, ChessPiece?> _simulateMove(
    Map<ChessSquare, ChessPiece?> board,
    ChessSquare from,
    ChessSquare to,
  ) {
    final newBoard = Map<ChessSquare, ChessPiece?>.from(board);
    newBoard[to] = newBoard[from]?.copyWith(hasMoved: true);
    newBoard[from] = null;
    return newBoard;
  }

  // Helper for AI to avoid using state.board
  List<ChessSquare> getValidMovesForSimulation(
    ChessSquare square,
    Map<ChessSquare, ChessPiece?> board,
    ChessColor color,
  ) {
    final piece = board[square];
    if (piece == null) return [];

    List<ChessSquare> candidates = [];

    switch (piece.type) {
      case ChessPieceType.pawn:
        candidates = _getPawnMovesForSim(square, piece, board);
        break;
      case ChessPieceType.rook:
        candidates = _getSlidingMovesForSim(square, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ], board);
        break;
      case ChessPieceType.knight:
        candidates = _getSteppingMovesForSim(square, piece, [
          [2, 1],
          [2, -1],
          [-2, 1],
          [-2, -1],
          [1, 2],
          [1, -2],
          [-1, 2],
          [-1, -2],
        ], board);
        break;
      case ChessPieceType.bishop:
        candidates = _getSlidingMovesForSim(square, piece, [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ], board);
        break;
      case ChessPieceType.queen:
        candidates = _getSlidingMovesForSim(square, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ], board);
        break;
      case ChessPieceType.king:
        candidates = _getSteppingMovesForSim(square, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ], board);
        break;
    }

    return candidates
        .where((to) => !_leavesKingInCheckSim(square, to, board, color))
        .toList();
  }

  List<ChessSquare> _getPawnMovesForSim(
    ChessSquare square,
    ChessPiece piece,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    final List<ChessSquare> moves = [];
    final direction = piece.color == ChessColor.white ? 1 : -1;

    final oneStep = ChessSquare(square.rank + direction, square.file);
    if (oneStep.isValid && board[oneStep] == null) {
      moves.add(oneStep);
      if (!piece.hasMoved) {
        final twoStep = ChessSquare(square.rank + 2 * direction, square.file);
        if (twoStep.isValid && board[twoStep] == null) {
          moves.add(twoStep);
        }
      }
    }

    for (var fOffset in [-1, 1]) {
      final diag = ChessSquare(square.rank + direction, square.file + fOffset);
      if (diag.isValid) {
        final target = board[diag];
        if (target != null && target.color != piece.color) {
          moves.add(diag);
        }
      }
    }
    return moves;
  }

  List<ChessSquare> _getSlidingMovesForSim(
    ChessSquare square,
    ChessPiece piece,
    List<List<int>> dirs,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    final List<ChessSquare> moves = [];
    for (var dir in dirs) {
      var next = ChessSquare(square.rank + dir[0], square.file + dir[1]);
      while (next.isValid) {
        final target = board[next];
        if (target == null) {
          moves.add(next);
        } else {
          if (target.color != piece.color) {
            moves.add(next);
          }
          break;
        }
        next = ChessSquare(next.rank + dir[0], next.file + dir[1]);
      }
    }
    return moves;
  }

  List<ChessSquare> _getSteppingMovesForSim(
    ChessSquare square,
    ChessPiece piece,
    List<List<int>> offsets,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    final List<ChessSquare> moves = [];
    for (var offset in offsets) {
      final next = ChessSquare(
        square.rank + offset[0],
        square.file + offset[1],
      );
      if (next.isValid) {
        final target = board[next];
        if (target == null || target.color != piece.color) {
          moves.add(next);
        }
      }
    }
    return moves;
  }

  bool _leavesKingInCheckSim(
    ChessSquare from,
    ChessSquare to,
    Map<ChessSquare, ChessPiece?> board,
    ChessColor color,
  ) {
    final tempBoard = _simulateMove(board, from, to);
    return _isKingInCheckOnBoard(color, tempBoard);
  }

  double _max(double a, double b) => a > b ? a : b;
  double _min(double a, double b) => a < b ? a : b;

  void _finalizeMove(ChessSquare to) {
    if (state.promotionPiece != null) {
      final newBoard = Map<ChessSquare, ChessPiece?>.from(state.board);
      newBoard[to] = ChessPiece(
        type: state.promotionPiece!,
        color: state.currentPlayer,
        hasMoved: true,
      );

      final newMoveHistory = [...state.moveHistory, 'Promotion at $to'];

      state = state.copyWith(
        board: newBoard,
        clearPromotion: true,
        currentPlayer: state.currentPlayer == ChessColor.white
            ? ChessColor.black
            : ChessColor.white,
        moveHistory: newMoveHistory,
      );
      _checkGameState();
      _saveGame();
    }
  }

  List<ChessSquare> getValidMoves(ChessSquare square) {
    return getValidMovesForSimulation(square, state.board, state.currentPlayer);
  }

  bool _isKingInCheckOnBoard(
    ChessColor color,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    ChessSquare? kingSquare;
    board.forEach((square, piece) {
      if (piece != null &&
          piece.type == ChessPieceType.king &&
          piece.color == color) {
        kingSquare = square;
      }
    });

    if (kingSquare == null) return false;

    for (var entry in board.entries) {
      final piece = entry.value;
      if (piece != null && piece.color != color) {
        if (_canAttack(entry.key, kingSquare!, piece, board)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canAttack(
    ChessSquare from,
    ChessSquare to,
    ChessPiece piece,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    switch (piece.type) {
      case ChessPieceType.pawn:
        final direction = piece.color == ChessColor.white ? 1 : -1;
        return (to.rank == from.rank + direction) &&
            (to.file - from.file).abs() == 1;
      case ChessPieceType.rook:
        return _isSlidingAttack(from, to, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ], board);
      case ChessPieceType.knight:
        return (to.rank - from.rank).abs() * (to.file - from.file).abs() == 2;
      case ChessPieceType.bishop:
        return _isSlidingAttack(from, to, [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ], board);
      case ChessPieceType.queen:
        return _isSlidingAttack(from, to, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ], board);
      case ChessPieceType.king:
        return (to.rank - from.rank).abs() <= 1 &&
            (to.file - from.file).abs() <= 1;
    }
  }

  bool _isSlidingAttack(
    ChessSquare from,
    ChessSquare to,
    List<List<int>> dirs,
    Map<ChessSquare, ChessPiece?> board,
  ) {
    for (var dir in dirs) {
      var next = ChessSquare(from.rank + dir[0], from.file + dir[1]);
      while (next.isValid) {
        if (next == to) return true;
        if (board[next] != null) break;
        next = ChessSquare(next.rank + dir[0], next.file + dir[1]);
      }
    }
    return false;
  }

  void _checkGameState() {
    final isCheck = _isKingInCheckOnBoard(state.currentPlayer, state.board);
    bool hasLegalMoves = false;
    for (var entry in state.board.entries) {
      if (entry.value != null && entry.value!.color == state.currentPlayer) {
        if (getValidMovesForSimulation(
          entry.key,
          state.board,
          state.currentPlayer,
        ).isNotEmpty) {
          hasLegalMoves = true;
          break;
        }
      }
    }

    if (!hasLegalMoves) {
      state = state.copyWith(
        status: isCheck ? ChessStatus.checkmate : ChessStatus.stalemate,
      );
      clearSavedGame();
    } else {
      state = state.copyWith(
        status: isCheck ? ChessStatus.check : ChessStatus.playing,
      );
    }
  }
}

class _Move {
  final ChessSquare from;
  final ChessSquare to;
  _Move(this.from, this.to);
}
