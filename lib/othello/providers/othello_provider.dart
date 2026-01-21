import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/othello_models.dart';

final othelloProvider =
    StateNotifierProvider<OthelloNotifier, OthelloGameState>((ref) {
      return OthelloNotifier();
    });

class OthelloNotifier extends StateNotifier<OthelloGameState> {
  OthelloNotifier() : super(OthelloGameState.initial()) {
    _loadSavedGame();
  }

  static const _saveKey = 'othello_game_state';

  Future<void> _loadSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_saveKey);
      if (savedData != null) {
        state = OthelloGameState.fromJson(json.decode(savedData));
        _checkBotTurn();
      }
    } catch (e) {
      debugPrint('Error loading Othello: $e');
    }
  }

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_saveKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving Othello: $e');
    }
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  void startGame({bool isSolo = false}) {
    state = OthelloGameState.initial(isSolo: isSolo);
    _saveGame();
  }

  void resetGame() {
    state = OthelloGameState.initial(isSolo: state.isSolo);
    _saveGame();
  }

  void makeMove(OthelloSquare square) {
    if (state.status == OthelloStatus.finished) return;

    final flippable = _getFlippableSquares(square, state.currentTurn);
    if (flippable.isEmpty) return;

    final newBoard = Map<OthelloSquare, OthelloPiece?>.from(state.board);
    newBoard[square] = state.currentTurn;
    for (var sq in flippable) {
      newBoard[sq] = state.currentTurn;
    }

    final newHistory = [
      ...state.moveHistory,
      '${state.currentTurn.name} at ${square.row},${square.col}',
    ];

    state = state.copyWith(board: newBoard, moveHistory: newHistory);

    _finalizeTurn();
  }

  void _finalizeTurn() {
    _updateCounts();
    _nextTurn();
  }

  void _updateCounts() {
    int white = 0;
    int black = 0;
    state.board.values.forEach((p) {
      if (p == OthelloPiece.white) white++;
      if (p == OthelloPiece.black) black++;
    });
    state = state.copyWith(whiteCount: white, blackCount: black);
  }

  void _nextTurn() {
    final opponent = state.currentTurn.opponent;

    if (hasValidMoves(opponent)) {
      state = state.copyWith(currentTurn: opponent);
      _checkBotTurn();
    } else if (hasValidMoves(state.currentTurn)) {
      // Pass turn back to current player
      // UI should probably reflect this "Pass"
    } else {
      // No moves for anyone
      state = state.copyWith(status: OthelloStatus.finished);
      clearSavedGame();
    }
    _saveGame();
  }

  bool hasValidMoves(OthelloPiece piece) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (_getFlippableSquares(OthelloSquare(r, c), piece).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  List<OthelloSquare> getValidMoves(OthelloPiece piece) {
    final List<OthelloSquare> moves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final sq = OthelloSquare(r, c);
        if (_getFlippableSquares(sq, piece).isNotEmpty) {
          moves.add(sq);
        }
      }
    }
    return moves;
  }

  List<OthelloSquare> _getFlippableSquares(
    OthelloSquare start,
    OthelloPiece piece,
  ) {
    if (state.board[start] != null) return [];

    final List<OthelloSquare> allFlippable = [];
    final dirs = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];

    for (var dir in dirs) {
      final List<OthelloSquare> line = [];
      int r = start.row + dir[0];
      int c = start.col + dir[1];

      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final currentSq = OthelloSquare(r, c);
        final currentPiece = state.board[currentSq];

        if (currentPiece == null) break;
        if (currentPiece == piece) {
          if (line.isNotEmpty) {
            allFlippable.addAll(line);
          }
          break;
        }

        line.add(currentSq);
        r += dir[0];
        c += dir[1];
      }
    }
    return allFlippable;
  }

  void _checkBotTurn() {
    if (state.isSolo &&
        state.currentTurn == OthelloPiece.white &&
        state.status == OthelloStatus.playing) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _makeBotMove();
      });
    }
  }

  void _makeBotMove() {
    final moves = getValidMoves(OthelloPiece.white);
    if (moves.isEmpty) {
      _nextTurn();
      return;
    }

    // Simple greedy AI: pick move that flips most pieces
    OthelloSquare bestMove = moves.first;
    int maxFlipped = 0;

    for (var move in moves) {
      final flipped = _getFlippableSquares(move, OthelloPiece.white).length;
      if (flipped > maxFlipped) {
        maxFlipped = flipped;
        bestMove = move;
      }
    }

    makeMove(bestMove);
  }
}
