import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pendu_game_state.dart';
import '../data/word_list.dart';

class PenduNotifier extends StateNotifier<PenduGameState?> {
  PenduNotifier() : super(null);

  void startGame() {
    final random = Random();
    final penduWord = penduWords[random.nextInt(penduWords.length)];
    state = PenduGameState.initial(
      word: penduWord.word,
      definition: penduWord.definition,
    );
  }

  void guessLetter(String letter) {
    if (state == null || state!.status != PenduStatus.playing) return;

    final upperLetter = letter.toUpperCase();
    if (state!.guessedLetters.contains(upperLetter)) return;

    final newState = state!.copyWith(
      guessedLetters: {...state!.guessedLetters, upperLetter},
    );

    // Check if correct
    if (!state!.targetWord.contains(upperLetter)) {
      // Wrong guess
      final remaining = newState.remainingAttempts - 1;
      state = newState.copyWith(
        remainingAttempts: remaining,
        status: remaining <= 0 ? PenduStatus.lost : PenduStatus.playing,
      );
    } else {
      // Correct guess
      state = newState;
      _checkWinCondition();
    }
  }

  void _checkWinCondition() {
    if (state == null) return;

    final allFound = state!.targetWord
        .split('')
        .every((char) => state!.guessedLetters.contains(char));

    if (allFound) {
      state = state!.copyWith(status: PenduStatus.won);
    }
  }

  void resetGame() {
    startGame();
  }
}

final penduProvider = StateNotifierProvider<PenduNotifier, PenduGameState?>((
  ref,
) {
  return PenduNotifier();
});
