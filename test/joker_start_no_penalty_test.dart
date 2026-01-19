import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Joker Start Rule', () {
    test('Joker as start card has no penalty and allows any card', () {
      final alice = Player(
        id: 'alice',
        name: 'Alice',
        hand: [
          const PlayingCard(id: '3h', suit: Suit.hearts, rank: Rank.three),
        ],
        position: 0,
      );
      final bob = Player(id: 'bob', name: 'Bob', hand: [], position: 1);

      final state = GameState(
        gameId: 'test',
        players: [alice, bob],
        deck: [],
        discardPile: [
          const PlayingCard(id: 'joker', suit: Suit.spades, rank: Rank.joker),
        ],
        hostId: 'alice',
        currentPlayerIndex: 0,
      );

      final result = GameLogic.applyStartCardEffectsForTest(state);

      // Verify no penalty
      expect(result.pendingPenalties, isEmpty);
      expect(result.players.first.hand.length, 1); // Still 1 card
      expect(result.currentPlayerIndex, 0);

      // Verify any card can be played
      final cardToPlay = alice.hand.first;
      final isValid = GameLogic.isValidMove(
        cardToPlay,
        result.topCard!,
        result.currentSuit,
      );
      expect(isValid, true, reason: 'Should be able to play any card on Joker');
    });
  });
}
