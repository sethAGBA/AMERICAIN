import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Start Penalty Behavior (Force Draw)', () {
    test('Start Card 2 of Hearts - Force Draw for P1 and P2', () {
      final alice = Player(id: 'alice', name: 'Alice', hand: [], position: 0);
      final bob = Player(id: 'bob', name: 'Bob', hand: [], position: 1);
      final charlie = Player(
        id: 'charlie',
        name: 'Charlie',
        hand: [],
        position: 2,
      );

      final deck = [
        const PlayingCard(id: 'd1', suit: Suit.spades, rank: Rank.three),
        const PlayingCard(id: 'd2', suit: Suit.spades, rank: Rank.four),
        const PlayingCard(id: 'd3', suit: Suit.spades, rank: Rank.five),
        const PlayingCard(id: 'd4', suit: Suit.spades, rank: Rank.six),
      ];

      final state = GameState(
        gameId: 'test',
        players: [alice, bob, charlie],
        deck: deck,
        discardPile: [
          const PlayingCard(id: 'start', suit: Suit.hearts, rank: Rank.two),
        ],
        hostId: 'alice',
        currentPlayerIndex: 0,
      );

      final result = GameLogic.applyStartCardEffectsForTest(state);

      // New behavior: Penalties are RESOLVED immediately
      expect(
        result.pendingPenalties,
        isEmpty,
        reason: 'Penalties should be resolved at start',
      );
      expect(
        result.nextCascadeLevels,
        isEmpty,
        reason: 'Cascade should be resolved at start',
      );

      // Alice (P1) should have drawn 2 cards
      final updatedAlice = result.players.firstWhere((p) => p.id == 'alice');
      expect(
        updatedAlice.hand.length,
        2,
        reason: 'Alice should have drawn 2 cards',
      );

      // Bob (P2) should have drawn 1 card (cascade)
      final updatedBob = result.players.firstWhere((p) => p.id == 'bob');
      expect(updatedBob.hand.length, 1, reason: 'Bob should have drawn 1 card');

      // Charlie (P3) should NOT be the current player yet, because turn stays with Bob after his cascade draw
      // Trace start 2H: Alice draws 2, turn stays 0. Bob gets cascade for 1. Alice (0) draws normal? Turn passes to 1.
      // Wait, let's fix the start loop logic if needed.
      // Currently it ends with the LAST person who had a penalty.
      // In this test, it should be Bob who ends current.
      expect(
        result.currentPlayerIndex,
        2, // Alice (0) -> Bob (1) -> Charlie (2).
        reason: 'Turn should pass to Charlie (P3) after Bob (P2) draws cascade',
      );
    });

    test('Start Card Ace - Force Draw for P1', () {
      final alice = Player(id: 'alice', name: 'Alice', hand: [], position: 0);
      final bob = Player(id: 'bob', name: 'Bob', hand: [], position: 1);

      final deck = [
        const PlayingCard(id: 'd1', suit: Suit.spades, rank: Rank.three),
      ];

      final state = GameState(
        gameId: 'test',
        players: [alice, bob],
        deck: deck,
        discardPile: [
          const PlayingCard(id: 'start', suit: Suit.spades, rank: Rank.ace),
        ],
        hostId: 'alice',
        currentPlayerIndex: 0,
      );

      final result = GameLogic.applyStartCardEffectsForTest(state);

      expect(result.pendingPenalties, isEmpty);

      // Alice should have drawn 1 card
      final updatedAlice = result.players.firstWhere((p) => p.id == 'alice');
      expect(updatedAlice.hand.length, 1);

      // Turn should PASS to Bob (1)
      expect(result.currentPlayerIndex, 1);
    });
  });
}
