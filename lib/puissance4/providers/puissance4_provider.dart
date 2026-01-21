import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/puissance4_player.dart';
import '../models/puissance4_state.dart' hide BotDifficulty;
import '../models/puissance4_state.dart' as p4_state;
import '../../models/settings.dart' as app_settings;
import '../../providers/settings_provider.dart';

final puissance4Provider =
    StateNotifierProvider<Puissance4Notifier, Puissance4State>((ref) {
      final settings = ref.watch(settingsProvider);
      return Puissance4Notifier(settings);
    });

class Puissance4Notifier extends StateNotifier<Puissance4State> {
  final app_settings.UserSettings settings;

  static const int rows = 6;
  static const int columns = 7;

  Puissance4Notifier(this.settings) : super(Puissance4State.initial());

  void initGame(bool isMultiplayer) {
    // Determine difficulty mapping
    p4_state.BotDifficulty difficulty;
    switch (settings.botDifficulty) {
      case app_settings.BotDifficulty.easy:
        difficulty = p4_state.BotDifficulty.easy;
        break;
      case app_settings.BotDifficulty.normal:
        difficulty = p4_state.BotDifficulty.medium;
        break;
      case app_settings.BotDifficulty.hard:
        difficulty = p4_state.BotDifficulty.hard;
        break;
    }

    final player1 = Puissance4Player(
      id: 'p1',
      name: 'Vous',
      color: Puissance4Color.red, // Player 1 always Red (starts)
      type: PlayerType.human,
    );

    final player2 = Puissance4Player(
      id: 'p2',
      name: isMultiplayer ? 'Joueur 2' : 'Bot',
      color: Puissance4Color.yellow,
      type: isMultiplayer ? PlayerType.human : PlayerType.bot,
    );

    // Empty 6x7 board
    final emptyBoard = List.generate(
      rows,
      (_) => List<Puissance4Color?>.filled(columns, null),
    );

    state = Puissance4State(
      players: [player1, player2],
      board: emptyBoard,
      currentPlayerId: player1.id,
      botDifficulty: difficulty,
    );
  }

  Future<void> playMove(int col) async {
    if (state.isGameOver) return;
    if (col < 0 || col >= columns) return;

    // Check if column is full
    if (state.board[0][col] != null) return; // Top row is full

    // Find the lowest empty row in this column
    int row = -1;
    for (int r = rows - 1; r >= 0; r--) {
      if (state.board[r][col] == null) {
        row = r;
        break;
      }
    }

    if (row == -1) return; // Should not happen if check above passed

    // Apply move
    final currentPlayer = state.currentPlayer!;
    final newBoard = List<List<Puissance4Color?>>.from(
      state.board.map((r) => List<Puissance4Color?>.from(r)),
    );
    newBoard[row][col] = currentPlayer.color;

    // Check Win
    final winInfo = _checkWin(newBoard, row, col, currentPlayer.color);

    if (winInfo != null) {
      state = state.copyWith(
        board: newBoard,
        winnerId: currentPlayer.id,
        winningCells: winInfo,
      );
    } else if (_isBoardFull(newBoard)) {
      state = state.copyWith(board: newBoard, isDraw: true);
    } else {
      // Switch turn
      final nextPlayer = state.players.firstWhere(
        (p) => p.id != currentPlayer.id,
      );
      state = state.copyWith(board: newBoard, currentPlayerId: nextPlayer.id);

      // Trigger Bot if needed
      if (nextPlayer.type == PlayerType.bot && !state.isGameOver) {
        await Future.delayed(const Duration(milliseconds: 600));
        _playBotMove();
      }
    }
  }

  void _playBotMove() {
    if (state.isGameOver) return;

    int col = -1;

    if (state.botDifficulty == p4_state.BotDifficulty.easy) {
      // Random valid column
      final validCols = _getValidColumns(state.board);
      if (validCols.isNotEmpty) {
        col = validCols[Random().nextInt(validCols.length)];
      }
    } else {
      // Medium/Hard: Try to win or block
      // 1. Check for winning move
      col = _findWinningMove(state.board, Puissance4Color.yellow);

      // 2. Block opponent winning move
      if (col == -1) {
        col = _findWinningMove(state.board, Puissance4Color.red);
      }

      // 3. Fallback to random valid
      if (col == -1) {
        final validCols = _getValidColumns(state.board);
        if (validCols.isNotEmpty) {
          // Prefer center columns for strategy
          if (validCols.contains(3))
            col = 3;
          else if (validCols.contains(2))
            col = 2;
          else if (validCols.contains(4))
            col = 4;
          else
            col = validCols[Random().nextInt(validCols.length)];
        }
      }
    }

    if (col != -1) {
      playMove(col);
    }
  }

  int _findWinningMove(
    List<List<Puissance4Color?>> board,
    Puissance4Color color,
  ) {
    final validCols = _getValidColumns(board);
    for (final c in validCols) {
      // Simulate move
      int r = -1;
      for (int row = rows - 1; row >= 0; row--) {
        if (board[row][c] == null) {
          r = row;
          break;
        }
      }
      if (r != -1) {
        final tempBoard = List<List<Puissance4Color?>>.from(
          board.map((row) => List<Puissance4Color?>.from(row)),
        );
        tempBoard[r][c] = color;
        if (_checkWin(tempBoard, r, c, color) != null) {
          return c;
        }
      }
    }
    return -1;
  }

  List<int> _getValidColumns(List<List<Puissance4Color?>> board) {
    List<int> cols = [];
    for (int c = 0; c < columns; c++) {
      if (board[0][c] == null) cols.add(c);
    }
    return cols;
  }

  bool _isBoardFull(List<List<Puissance4Color?>> board) {
    for (int c = 0; c < columns; c++) {
      if (board[0][c] == null) return false;
    }
    return true;
  }

  List<Point<int>>? _checkWin(
    List<List<Puissance4Color?>> board,
    int row,
    int col,
    Puissance4Color color,
  ) {
    // Directions: Horizontal, Vertical, Diagonal /, Diagonal \
    final directions = [
      [Point(0, 1), Point(0, -1)], // Horizontal
      [Point(1, 0), Point(-1, 0)], // Vertical
      [Point(1, 1), Point(-1, -1)], // Diagonal \
      [Point(1, -1), Point(-1, 1)], // Diagonal /
    ];

    for (final dirPair in directions) {
      List<Point<int>> winningLine = [Point(row, col)];

      for (final dir in dirPair) {
        int r = row + dir.x;
        int c = col + dir.y;

        while (r >= 0 &&
            r < rows &&
            c >= 0 &&
            c < columns &&
            board[r][c] == color) {
          winningLine.add(Point(r, c));
          r += dir.x;
          c += dir.y;
        }
      }

      if (winningLine.length >= 4) {
        return winningLine;
      }
    }
    return null;
  }

  void restartGame() {
    // Just check if we are in multiplayer or not based on player 2 type
    final isMultiplayer =
        state.players.length > 1 && state.players[1].type == PlayerType.human;
    initGame(isMultiplayer);
  }
}
