// ignore_for_file: avoid_print

import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  print('--- Debugging Jack of Spades 1v1 ---');

  final p1 = Player(
    id: 'p1',
    name: 'Human',
    position: 0,
    hand: [const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two)],
  );
  final p2 = Player(
    id: 'p2',
    name: 'Bot',
    position: 1,
    hand: [
      const PlayingCard(id: 'js', suit: Suit.spades, rank: Rank.jack),
      const PlayingCard(id: 'dummy', suit: Suit.clubs, rank: Rank.ace),
    ],
    isBot: true,
  );

  final state = GameState(
    gameId: 'test',
    players: [p1, p2],
    currentPlayerIndex: 1, // Bot starts
    deck: [],
    discardPile: [
      const PlayingCard(id: 's10', suit: Suit.spades, rank: Rank.ten),
    ],
    hostId: 'p1',
  );

  print('Initial Player: ${state.currentPlayerIndex} (Should be 1/Bot)');
  print('Num Players: ${state.players.length}');

  // Run Play Card Logic Trace
  final card = p2.hand[0];
  print('Playing Card: $card');

  // Manual Logic Trace (simulating playCard)
  bool turnPasses = false;
  int pendingSkips = 0;

  if (card.rank == Rank.jack) {
    if (card.suit == Suit.spades) {
      pendingSkips += 2;
      if (state.players.length == 2) {
        print('Logic: 1v1 Detected -> Turn Passes');
        turnPasses = true;
      } else {
        print('Logic: >2 Players -> Turn Stays');
        turnPasses = false;
      }
    }
  }

  print('Calculated turnPasses: $turnPasses');
  print('Calculated pendingSkips: $pendingSkips');

  if (turnPasses) {
    int startIdx = 1;
    print('Starting Math from Index: $startIdx');

    // 1. Next Player
    int idx = (startIdx + 1) % 2;
    print('After NextPlayer (Move): $idx');

    // 2. Skips
    for (int i = 0; i < pendingSkips; i++) {
      idx = (idx + 1) % 2;
      print('After Skip ${i + 1}: $idx');
    }

    print('Final Index: $idx');
  }

  // Real Execution
  final nextState = GameLogic.playCard(state, 'p2', card);
  print('--- Real Result ---');
  print('Next State Index: ${nextState.currentPlayerIndex}');
  print('Must Match Suit: ${nextState.mustMatchSuit}');
}
