import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Sequential 2-Spades Cascade', () {
    test('1v1: Alice plays 2S, Bob draws 4, Alice draws 2, Bob draws 1', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [
          const PlayingCard(id: 's2', suit: Suit.spades, rank: Rank.two),
          const PlayingCard(id: 'h10', suit: Suit.hearts, rank: Rank.ten),
        ],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [
          const PlayingCard(id: 's3', suit: Suit.spades, rank: Rank.three),
        ],
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 0,
        deck: List.generate(
          10,
          (i) => PlayingCard(id: 'd$i', suit: Suit.diamonds, rank: Rank.nine),
        ),
        discardPile: [
          const PlayingCard(id: 's5', suit: Suit.spades, rank: Rank.five),
        ],
      );

      // 1. Alice plays 2 Spades
      state = GameLogic.playCard(state, 'p1', p1.hand[0]);

      expect(state.getPenaltyFor('p2'), 4);
      expect(state.nextCascadeLevels, [2, 1]);
      expect(state.currentPlayer?.id, 'p2');

      // 2. Bob draws 4
      state = GameLogic.drawCard(state, 'p2');
      expect(state.players[1].hand.length, 1 + 4);
      expect(
        state.getPenaltyFor('p1'),
        2,
        reason: 'Alice should now be targeted with 2',
      );
      expect(state.nextCascadeLevels, [1]);
      expect(
        state.currentPlayer?.id,
        'p1',
        reason: 'Turn should move to Alice',
      );

      // 3. Alice draws 2
      state = GameLogic.drawCard(state, 'p1');
      expect(
        state.players[0].hand.length,
        1 + 2,
      ); // Alice had 1 card left (h10)
      expect(
        state.getPenaltyFor('p2'),
        1,
        reason: 'Bob should now be targeted with 1',
      );
      expect(state.nextCascadeLevels, isEmpty);
      expect(
        state.currentPlayer?.id,
        'p2',
        reason: 'Turn should move back to Bob',
      );

      // 4. Bob draws 1
      state = GameLogic.drawCard(state, 'p2');
      expect(state.getPenaltyFor('p2'), 0);
      expect(state.nextCascadeLevels, isEmpty);
      expect(
        state.currentPlayer?.id,
        'p1',
        reason: 'Turn should move to Alice (Final draw passes turn)',
      );
    });
  });
}
