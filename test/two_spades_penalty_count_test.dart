import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('2 of Spades Penalty Count', () {
    test('isValidMove should allow 2 of Spades on 9 of Hearts', () {
      final card2S = const PlayingCard(
        id: 's2',
        suit: Suit.spades,
        rank: Rank.two,
      );
      final topCard = const PlayingCard(
        id: 's9',
        suit: Suit.spades,
        rank: Rank.nine,
      );

      final isValid = GameLogic.isValidMove(card2S, topCard, null);

      expect(
        isValid,
        isTrue,
        reason: '2 of Spades should be playable on 9 of Spades (Matching Suit)',
      );
    });

    test('Player should draw exactly 4 cards for 2 of Spades', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: const [
          PlayingCard(id: 's2', suit: Suit.spades, rank: Rank.two),
          PlayingCard(id: 'h5', suit: Suit.hearts, rank: Rank.five),
          PlayingCard(id: 'd7', suit: Suit.diamonds, rank: Rank.seven),
        ],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: const [
          PlayingCard(id: 'd10', suit: Suit.diamonds, rank: Rank.ten),
        ],
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 0,
        deck: const [
          PlayingCard(id: 'c3', suit: Suit.clubs, rank: Rank.three),
          PlayingCard(id: 'c4', suit: Suit.clubs, rank: Rank.four),
          PlayingCard(id: 'c5', suit: Suit.clubs, rank: Rank.five),
          PlayingCard(id: 'c6', suit: Suit.clubs, rank: Rank.six),
          PlayingCard(id: 'c7', suit: Suit.clubs, rank: Rank.seven),
        ],
        discardPile: const [
          PlayingCard(id: 's9', suit: Suit.spades, rank: Rank.nine),
        ],
      );

      // Alice plays 2 of Spades
      state = GameLogic.playCard(state, 'p1', p1.hand[0]);

      expect(
        state.getPenaltyFor('p2'),
        4,
        reason: 'Bob should have penalty of 4',
      );
      expect(state.currentPlayer?.id, 'p2', reason: 'Turn should be Bob\'s');
      expect(state.nextCascadeLevels, [
        2,
        1,
      ], reason: 'Cascade levels should be [2, 1]');

      final bobHandBefore = state.players[1].hand.length;

      // Bob draws for penalty
      state = GameLogic.drawCard(state, 'p2');

      final bobHandAfter = state.players[1].hand.length;

      expect(
        bobHandAfter - bobHandBefore,
        4,
        reason: 'Bob should draw EXACTLY 4 cards, not 5',
      );

      expect(
        state.getPenaltyFor('p2'),
        0,
        reason: 'Bob penalty should be cleared',
      );
      expect(
        state.currentPlayer?.id,
        'p1',
        reason: 'Turn should pass to Alice',
      );
      expect(
        state.getPenaltyFor('p1'),
        2,
        reason: 'Alice should now have cascade penalty of 2',
      );
    });
  });
}
