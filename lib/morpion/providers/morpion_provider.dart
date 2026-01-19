import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/morpion_state.dart';
import '../../services/sound_service.dart';

final morpionProvider = StateNotifierProvider<MorpionNotifier, MorpionState>((
  ref,
) {
  return MorpionNotifier();
});

class MorpionNotifier extends StateNotifier<MorpionState> {
  MorpionNotifier()
    : super(
        MorpionState(
          board: List.filled(9, MorpionSymbol.none),
          players: [],
          currentTurn: 0,
          status: MorpionStatus.lobby,
        ),
      );

  void setupGame({
    required bool vsBot,
    MorpionSymbol humanSymbol = MorpionSymbol.x,
  }) {
    List<MorpionPlayer> players = [];

    if (humanSymbol == MorpionSymbol.x) {
      players.add(
        const MorpionPlayer(
          id: 'p1',
          name: 'Joueur 1',
          symbol: MorpionSymbol.x,
        ),
      );
      if (vsBot) {
        players.add(
          const MorpionPlayer(
            id: 'bot',
            name: 'Bot',
            symbol: MorpionSymbol.o,
            isBot: true,
          ),
        );
      } else {
        players.add(
          const MorpionPlayer(
            id: 'p2',
            name: 'Joueur 2',
            symbol: MorpionSymbol.o,
          ),
        );
      }
    } else {
      if (vsBot) {
        players.add(
          const MorpionPlayer(
            id: 'bot',
            name: 'Bot',
            symbol: MorpionSymbol.x,
            isBot: true,
          ),
        );
      } else {
        players.add(
          const MorpionPlayer(
            id: 'p2',
            name: 'Joueur 2',
            symbol: MorpionSymbol.x,
          ),
        );
      }
      players.add(
        const MorpionPlayer(
          id: 'p1',
          name: 'Joueur 1',
          symbol: MorpionSymbol.o,
        ),
      );
    }

    state = state.copyWith(
      players: players,
      board: List.filled(9, MorpionSymbol.none),
      currentTurn: 0,
      status: MorpionStatus.playing,
      winnerId: null,
      winningLine: null,
      isDraw: false,
    );

    // If bot starts
    if (state.players[0].isBot) {
      _makeBotMove();
    }
  }

  void makeMove(int index) {
    if (state.status != MorpionStatus.playing) return;
    if (state.board[index] != MorpionSymbol.none) return;

    final currentPlayer = state.players[state.currentTurn];
    List<MorpionSymbol> newBoard = List.from(state.board);
    newBoard[index] = currentPlayer.symbol;

    state = state.copyWith(board: newBoard);
    SoundService.playDominoPlay(); // Excellent clac pour le morpion aussi

    if (_checkVictory(newBoard)) return;
    if (_checkDraw(newBoard)) return;

    _nextTurn();
  }

  void _nextTurn() {
    int nextTurn = (state.currentTurn + 1) % 2;
    state = state.copyWith(currentTurn: nextTurn);

    if (state.players[nextTurn].isBot) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _makeBotMove();
      });
    }
  }

  void _makeBotMove() {
    if (state.status != MorpionStatus.playing) return;

    // 1. Try to win
    int move = _findWinningMove(
      state.board,
      state.players[state.currentTurn].symbol,
    );

    // 2. Try to block opponent
    if (move == -1) {
      MorpionSymbol opponentSymbol =
          (state.players[state.currentTurn].symbol == MorpionSymbol.x)
          ? MorpionSymbol.o
          : MorpionSymbol.x;
      move = _findWinningMove(state.board, opponentSymbol);
    }

    // 3. Take center if free
    if (move == -1 && state.board[4] == MorpionSymbol.none) {
      move = 4;
    }

    // 4. Random move
    if (move == -1) {
      List<int> freeIndices = [];
      for (int i = 0; i < 9; i++) {
        if (state.board[i] == MorpionSymbol.none) freeIndices.add(i);
      }
      if (freeIndices.isNotEmpty) {
        move = freeIndices[math.Random().nextInt(freeIndices.length)];
      }
    }

    if (move != -1) {
      makeMove(move);
    }
  }

  int _findWinningMove(List<MorpionSymbol> board, MorpionSymbol symbol) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Horizontals
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Verticals
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (var line in lines) {
      int count = 0;
      int emptyIndex = -1;
      for (var index in line) {
        if (board[index] == symbol) count++;
        if (board[index] == MorpionSymbol.none) emptyIndex = index;
      }
      if (count == 2 && emptyIndex != -1) return emptyIndex;
    }
    return -1;
  }

  bool _checkVictory(List<MorpionSymbol> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Horizontals
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Verticals
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (var line in lines) {
      if (board[line[0]] != MorpionSymbol.none &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        String winnerId = state.players
            .firstWhere((p) => p.symbol == board[line[0]])
            .id;
        state = state.copyWith(
          status: MorpionStatus.finished,
          winnerId: winnerId,
          winningLine: line,
        );
        return true;
      }
    }
    return false;
  }

  bool _checkDraw(List<MorpionSymbol> board) {
    if (!board.contains(MorpionSymbol.none)) {
      state = state.copyWith(status: MorpionStatus.finished, isDraw: true);
      return true;
    }
    return false;
  }

  void resetGame() {
    state = state.copyWith(
      board: List.filled(9, MorpionSymbol.none),
      currentTurn: 0,
      status: MorpionStatus.lobby,
      winnerId: null,
      winningLine: null,
      isDraw: false,
    );
  }
}
