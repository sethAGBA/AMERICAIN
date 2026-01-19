import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Reproduction of 7 on 2 Bug', () {
    test('Should NOT be possible to play a 7 when under penalty of 2', () {
      final alice = Player(
        id: 'alice',
        name: 'Alice',
        hand: [const PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two)],
        position: 0,
      );

      final bob = Player(
        id: 'bob',
        name: 'Bob',
        hand: [
          const PlayingCard(id: '7h', suit: Suit.hearts, rank: Rank.seven),
        ],
        position: 1,
      );

      final state = GameState(
        gameId: 'test',
        players: [alice, bob],
        deck: const [
          PlayingCard(id: 'd1', suit: Suit.spades, rank: Rank.three),
        ],
        discardPile: const [
          PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two),
        ],
        hostId: 'alice',
        currentPlayerIndex: 1, // Bob's turn
        pendingPenalties: const {'bob': 2},
        activeAttackCard: const PlayingCard(
          id: '2h',
          suit: Suit.hearts,
          rank: Rank.two,
        ),
      );

      final cardToPlay = bob.hand[0]; // 7 of hearts
      final topCard = state.topCard!; // 2 of hearts

      final isValid = GameLogic.isValidMove(
        cardToPlay,
        topCard,
        state.currentSuit,
        penalty: state.getPenaltyFor('bob'),
        activeAttackCard: state.activeAttackCard,
      );

      expect(
        isValid,
        isFalse,
        reason: 'Playing a 7 on a 2 under penalty should be invalid',
      );

      final newState = GameLogic.playCard(state, 'bob', cardToPlay);

      expect(
        newState.topCard,
        isNot(cardToPlay),
        reason: 'The 7 should not have been played',
      );
      expect(
        newState.players[1].hand,
        contains(cardToPlay),
        reason: 'The 7 should still be in Bob\'s hand',
      );
    });

    test(
      'Should NOT be possible to play a 7 when under penalty even if mustMatchSuit is set',
      () {
        final alice = Player(id: 'alice', name: 'Alice', hand: [], position: 0);

        final bob = Player(
          id: 'bob',
          name: 'Bob',
          hand: [
            const PlayingCard(id: '7h', suit: Suit.hearts, rank: Rank.seven),
          ],
          position: 1,
        );

        final state = GameState(
          gameId: 'test',
          players: [alice, bob],
          deck: const [
            PlayingCard(id: 'd1', suit: Suit.spades, rank: Rank.three),
          ],
          discardPile: const [
            PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two),
          ],
          hostId: 'alice',
          currentPlayerIndex: 1,
          pendingPenalties: const {'bob': 2},
          activeAttackCard: const PlayingCard(
            id: '2h',
            suit: Suit.hearts,
            rank: Rank.two,
          ),
          mustMatchSuit: Suit.hearts, // Bug trigger!
        );

        final cardToPlay = bob.hand[0]; // 7 of hearts
        final topCard = state.topCard!;

        final isValid = GameLogic.isValidMove(
          cardToPlay,
          topCard,
          state.currentSuit,
          penalty: state.getPenaltyFor('bob'),
          activeAttackCard: state.activeAttackCard,
          mustMatchSuit: state.mustMatchSuit,
        );

        expect(
          isValid,
          isFalse,
          reason: 'Penalty should take priority over suit restriction',
        );
      },
    );
  });
}
