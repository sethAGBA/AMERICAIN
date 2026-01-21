import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dara_models.dart';

final daraProvider = StateNotifierProvider<DaraNotifier, DaraGameState>((ref) {
  return DaraNotifier();
});

class DaraNotifier extends StateNotifier<DaraGameState> {
  DaraNotifier() : super(DaraGameState.initial()) {
    _loadSavedGame();
  }

  static const _saveKey = 'dara_game_state';

  Future<void> _loadSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_saveKey);
      if (savedData != null) {
        state = DaraGameState.fromJson(json.decode(savedData));
        _checkBotTurn();
      }
    } catch (e) {
      debugPrint('Error loading Dara: $e');
    }
  }

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_saveKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving Dara: $e');
    }
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  void startGame({bool isSolo = false}) {
    state = DaraGameState.initial(isSolo: isSolo);
    _saveGame();
  }

  void resetGame() {
    state = DaraGameState.initial(isSolo: state.isSolo);
    _saveGame();
  }

  void onSquareTap(DaraSquare square) {
    if (state.status == DaraStatus.finished) return;

    if (state.phase == DaraPhase.drop) {
      _handleDrop(square);
    } else if (state.phase == DaraPhase.capture) {
      _handleCapture(square);
    }
  }

  void onMove(DaraSquare from, DaraSquare to) {
    if (state.phase != DaraPhase.move || state.status == DaraStatus.finished)
      return;
    _handleMove(from, to);
  }

  void _handleDrop(DaraSquare square) {
    if (state.board[square] != null) return;

    // Check for 3-in-a-row constraint during drop
    if (_wouldFormMoreThanThree(square, state.currentTurn)) return;

    final newBoard = Map<DaraSquare, DaraPiece?>.from(state.board);
    newBoard[square] = state.currentTurn;

    int p1Drop = state.p1PiecesToDrop;
    int p2Drop = state.p2PiecesToDrop;
    if (state.currentTurn == DaraPiece.player1)
      p1Drop--;
    else
      p2Drop--;

    final nextPhase = (p1Drop == 0 && p2Drop == 0)
        ? DaraPhase.move
        : DaraPhase.drop;

    state = state.copyWith(
      board: newBoard,
      p1PiecesToDrop: p1Drop,
      p2PiecesToDrop: p2Drop,
      phase: nextPhase,
      currentTurn: state.currentTurn.opponent,
    );

    _saveGame();
    _checkBotTurn();
  }

  void _handleMove(DaraSquare from, DaraSquare to) {
    if (state.board[from] != state.currentTurn) return;
    if (state.board[to] != null) return;

    // Orthogonal distance check
    if ((from.row - to.row).abs() + (from.col - to.col).abs() != 1) return;

    final newBoard = Map<DaraSquare, DaraPiece?>.from(state.board);
    newBoard[from] = null;
    newBoard[to] = state.currentTurn;

    // Check if exactly 3 in a row
    if (_isExactlyThree(to, newBoard)) {
      state = state.copyWith(board: newBoard, phase: DaraPhase.capture);
    } else {
      state = state.copyWith(
        board: newBoard,
        currentTurn: state.currentTurn.opponent,
      );
    }

    _saveGame();
    _checkBotTurn();
  }

  void _handleCapture(DaraSquare square) {
    final piece = state.board[square];
    if (piece == null || piece == state.currentTurn) return;

    final newBoard = Map<DaraSquare, DaraPiece?>.from(state.board);
    newBoard[square] = null;

    int p1Score = state.p1Score;
    int p2Score = state.p2Score;
    if (piece == DaraPiece.player1)
      p1Score--;
    else
      p2Score--;

    DaraStatus status = DaraStatus.playing;
    if (p1Score < 3 || p2Score < 3) {
      status = DaraStatus.finished;
      clearSavedGame();
    }

    state = state.copyWith(
      board: newBoard,
      p1Score: p1Score,
      p2Score: p2Score,
      status: status,
      phase: DaraPhase.move,
      currentTurn: state.currentTurn.opponent,
    );

    _saveGame();
    _checkBotTurn();
  }

  bool _wouldFormMoreThanThree(DaraSquare sq, DaraPiece p) {
    final tempBoard = Map<DaraSquare, DaraPiece?>.from(state.board);
    tempBoard[sq] = p;

    // Check horizontal
    int hCount = 1;
    for (
      int c = sq.col + 1;
      c < 6 && tempBoard[DaraSquare(sq.row, c)] == p;
      c++
    )
      hCount++;
    for (
      int c = sq.col - 1;
      c >= 0 && tempBoard[DaraSquare(sq.row, c)] == p;
      c--
    )
      hCount++;
    if (hCount > 3) return true;

    // Check vertical
    int vCount = 1;
    for (
      int r = sq.row + 1;
      r < 5 && tempBoard[DaraSquare(r, sq.col)] == p;
      r++
    )
      vCount++;
    for (
      int r = sq.row - 1;
      r >= 0 && tempBoard[DaraSquare(r, sq.col)] == p;
      r--
    )
      vCount++;
    if (vCount > 3) return true;

    return false;
  }

  bool _isExactlyThree(DaraSquare sq, Map<DaraSquare, DaraPiece?> board) {
    final p = board[sq];

    // Horizontal
    int hCount = 1;
    for (int c = sq.col + 1; c < 6 && board[DaraSquare(sq.row, c)] == p; c++)
      hCount++;
    for (int c = sq.col - 1; c >= 0 && board[DaraSquare(sq.row, c)] == p; c--)
      hCount++;
    if (hCount == 3) return true;

    // Vertical
    int vCount = 1;
    for (int r = sq.row + 1; r < 5 && board[DaraSquare(r, sq.col)] == p; r++)
      vCount++;
    for (int r = sq.row - 1; r >= 0 && board[DaraSquare(r, sq.col)] == p; r--)
      vCount++;
    if (vCount == 3) return true;

    return false;
  }

  void _checkBotTurn() {
    if (state.isSolo &&
        state.currentTurn == DaraPiece.player2 &&
        state.status == DaraStatus.playing) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _makeBotMove();
      });
    }
  }

  void _makeBotMove() {
    if (state.phase == DaraPhase.drop) {
      final List<DaraSquare> options = [];
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 6; c++) {
          final sq = DaraSquare(r, c);
          if (state.board[sq] == null &&
              !_wouldFormMoreThanThree(sq, DaraPiece.player2)) {
            options.add(sq);
          }
        }
      }
      if (options.isNotEmpty) {
        options.shuffle();
        _handleDrop(options.first);
      }
    } else if (state.phase == DaraPhase.move) {
      // Find all possible moves
      final List<List<DaraSquare>> moves = [];
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 6; c++) {
          final from = DaraSquare(r, c);
          if (state.board[from] == DaraPiece.player2) {
            final neighbors = [
              DaraSquare(r + 1, c),
              DaraSquare(r - 1, c),
              DaraSquare(r, c + 1),
              DaraSquare(r, c - 1),
            ];
            for (var to in neighbors) {
              if (to.isValid && state.board[to] == null) {
                moves.add([from, to]);
              }
            }
          }
        }
      }

      if (moves.isNotEmpty) {
        // Greedy: prioritize move that forms 3
        for (var move in moves) {
          final tempBoard = Map<DaraSquare, DaraPiece?>.from(state.board);
          tempBoard[move[0]] = null;
          tempBoard[move[1]] = DaraPiece.player2;
          if (_isExactlyThree(move[1], tempBoard)) {
            _handleMove(move[0], move[1]);
            return;
          }
        }

        moves.shuffle();
        _handleMove(moves.first[0], moves.first[1]);
      }
    } else if (state.phase == DaraPhase.capture) {
      final List<DaraSquare> p1Pieces = [];
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 6; c++) {
          final sq = DaraSquare(r, c);
          if (state.board[sq] == DaraPiece.player1) p1Pieces.add(sq);
        }
      }
      if (p1Pieces.isNotEmpty) {
        p1Pieces.shuffle();
        _handleCapture(p1Pieces.first);
      }
    }
  }
}
