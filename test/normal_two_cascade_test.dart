import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Normal 2 Cascade (2-1)', () {
    test(
      'Sequential 2-1 Cascade: Alice plays 2H, Bob draws 2, Alice draws 1',
      () {
        // 1v1 Scenario
        final p1 = Player(
          id: 'p1',
          name: 'Alice',
          position: 0,
          hand: [
            const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two),
            const PlayingCard(id: 's5', suit: Suit.spades, rank: Rank.five),
          ],
        );
        final p2 = Player(
          id: 'p2',
          name: 'Bob',
          position: 1,
          hand: [
            const PlayingCard(id: 'd10', suit: Suit.diamonds, rank: Rank.ten),
          ],
        );

        var state = GameState(
          gameId: 'test',
          hostId: 'p1',
          players: [p1, p2],
          currentPlayerIndex: 0, // Alice turn
          deck: [
            const PlayingCard(id: 'c3', suit: Suit.clubs, rank: Rank.three),
            const PlayingCard(id: 'c4', suit: Suit.clubs, rank: Rank.four),
            const PlayingCard(id: 'c5', suit: Suit.clubs, rank: Rank.five),
          ],
          discardPile: [
            const PlayingCard(id: 'h9', suit: Suit.hearts, rank: Rank.nine),
          ],
        );

        // 1. Alice plays 2 of Hearts
        state = GameLogic.playCard(state, 'p1', p1.hand[0]);

        expect(
          state.getPenaltyFor('p2'),
          2,
          reason: 'Bob should target with 2',
        );
        expect(state.nextCascadeLevels, [
          1,
        ], reason: 'Next cascade level should be 1');
        expect(state.currentPlayer?.id, 'p2', reason: 'Turn moves to Bob');

        // 2. Bob draws for penalty (2 cards)
        state = GameLogic.drawCard(state, 'p2');

        expect(state.getPenaltyFor('p2'), 0, reason: 'Bob penalty cleared');
        expect(
          state.getPenaltyFor('p1'),
          1,
          reason: 'Alice targeted with 1 (Cascade)',
        );
        expect(
          state.players[1].hand.length,
          3,
          reason: 'Bob should have 3 cards (1 original + 2 drawn)',
        );
        expect(state.currentPlayer?.id, 'p1', reason: 'Turn moves to Alice');

        // 3. Alice draws for penalty (1 card)
        state = GameLogic.drawCard(state, 'p1');

        expect(state.getPenaltyFor('p1'), 0, reason: 'Alice penalty cleared');
        expect(state.nextCascadeLevels, isEmpty, reason: 'Cascade finished');
        expect(
          state.players[0].hand.length,
          2,
          reason: 'Alice should have 2 cards (1 remaining + 1 drawn)',
        );
        expect(
          state.currentPlayer?.id,
          'p2', // Turn passed to Bob
          reason: 'Turn should PASS to Bob after Alice draws final cascade',
        );
      },
    );
    group('Defense Propagation (Normal 2)', () {
      test('Bob blocks Alice\'s 2H with 2D', () {
        final p1 = Player(
          id: 'p1',
          name: 'Alice',
          position: 0,
          hand: [
            const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two),
            const PlayingCard(id: 'h5', suit: Suit.hearts, rank: Rank.five),
          ],
        );
        final p2 = Player(
          id: 'p2',
          name: 'Bob',
          position: 1,
          hand: [
            const PlayingCard(id: 'd2', suit: Suit.diamonds, rank: Rank.two),
          ],
        );

        var state = GameState(
          gameId: 'test',
          hostId: 'p1',
          players: [p1, p2],
          currentPlayerIndex: 0,
          deck: const [],
          discardPile: [
            const PlayingCard(id: 'h9', suit: Suit.hearts, rank: Rank.nine),
          ],
        );

        // Alice plays 2H
        state = GameLogic.playCard(state, 'p1', p1.hand[0]);
        expect(state.getPenaltyFor('p2'), 2);
        expect(state.nextCascadeLevels, [1]);

        // Bob plays 2D to defend
        state = GameLogic.playCard(state, 'p2', p2.hand[0]);

        expect(state.getPenaltyFor('p2'), 0, reason: 'Bob penalty cleared');
        expect(
          state.getPenaltyFor('p1'),
          0,
          reason: 'Alice targeted with 0 (Block = Cancellation)',
        );
        expect(
          state.nextCascadeLevels,
          isEmpty,
          reason: 'Cascade levels cleared',
        );
        expect(
          state.currentPlayer?.id,
          'p2',
          reason: 'Turn stays with Bob for accompaniment',
        );
        expect(
          state.mustMatchSuit,
          Suit.diamonds,
          reason: 'Must match suit of the blocking 2',
        );
      });
    });
  });
}
