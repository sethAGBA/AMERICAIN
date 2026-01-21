import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/chifoumi_state.dart';
import '../models/chifoumi_move.dart';

final chifoumiProvider = StateNotifierProvider<ChifoumiNotifier, ChifoumiState>(
  (ref) {
    return ChifoumiNotifier();
  },
);

class ChifoumiNotifier extends StateNotifier<ChifoumiState> {
  final Random _random = Random();

  ChifoumiNotifier() : super(ChifoumiState.initial());

  void playMove(ChifoumiMove playerMove) async {
    // If already revealing, ignore new inputs
    if (state.isRevealing) return;

    // Set revealing state (bot move is hidden initially in UI but calculated here)
    // Actually, setting botMove immediately is fine if UI hides it based on animation state,
    // but usually better to set 'isRevealing' true, show animation, then show result.

    // Simulating "Pierre... Feuille... Ciseaux..." delay could be done in UI.
    // Logic:
    // 1. Generate Bot Move
    final botMove =
        ChifoumiMove.values[_random.nextInt(ChifoumiMove.values.length)];

    // 2. determine winner
    String resultMsg;
    int pScore = state.playerScore;
    int bScore = state.botScore;

    if (playerMove == botMove) {
      resultMsg = "ÉGALITÉ !";
    } else if (playerMove.beats(botMove)) {
      resultMsg = "GAGNÉ !";
      pScore++;
    } else {
      resultMsg = "PERDU !";
      bScore++;
    }

    // Update state to show revealed moves
    // Simple version: Immediate update.
    // Polished version: Update state with moves, UI handles "reveal" animation.

    state = state.copyWith(
      playerMove: playerMove,
      botMove: botMove,
      playerScore: pScore, // Optimistic update or wait? Let's update now.
      botScore: bScore,
      isRevealing: true,
      resultMessage: resultMsg,
    );

    // Auto-reset round state after delay?
    // Or waiting for user to click "Next"?
    // Quick play style: click move -> show result -> available to click again immediately?
    // Let's rely on user to simply click a new move, which will reset the 'revealing' visual if we want,
    // OR have a "Replay" button.
    // For flow: Click > Animation > Result Overlay > "Rejouer" button or just tap standard buttons again.
    // Let's implement a 'reset' method called by UI when ready.
  }

  void resetGame() {
    state = ChifoumiState.initial();
  }

  void nextRound() {
    state = state.resetRound();
  }
}
