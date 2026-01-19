import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Ace Defense and Propagation', () {
    test('Alice blocks Bob\'s Ace with another Ace (Universal)', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [
          const PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace),
          const PlayingCard(id: 'h10', suit: Suit.hearts, rank: Rank.ten),
          const PlayingCard(
            id: 's5',
            suit: Suit.spades,
            rank: Rank.five,
          ), // Extra card to prevent win
        ],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [const PlayingCard(id: 'h9', suit: Suit.hearts, rank: Rank.nine)],
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p2',
        players: [p1, p2],
        currentPlayerIndex: 0,
        deck: const [],
        discardPile: [
          const PlayingCard(id: 'as', suit: Suit.spades, rank: Rank.ace),
        ],
        activeAttackCard: const PlayingCard(
          id: 'as',
          suit: Suit.spades,
          rank: Rank.ace,
        ),
        pendingPenalties: const {'p1': 1},
      );

      // Alice plays Ace of Hearts to defend
      state = GameLogic.playCard(state, 'p1', p1.hand[0]);

      expect(
        state.getPenaltyFor('p1'),
        0,
        reason: 'Alice penalty should be cleared',
      );
      expect(
        state.getPenaltyFor('p2'),
        0,
        reason: 'Bob penalty should be 0 (cancelled until accompaniment)',
      );
      expect(
        state.currentPlayer?.id,
        'p2',
        reason: 'Turn moves to Bob after Ace block',
      );
      expect(state.discardPile.last.id, 'ah');
    });

    test('8 blocks 2-Spades penalty cascade', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [
          const PlayingCard(id: 'h8', suit: Suit.hearts, rank: Rank.eight),
        ],
      );
      final p2 = Player(id: 'p2', name: 'Bob', position: 1, hand: []);

      var state = GameState(
        gameId: 'test',
        hostId: 'p2',
        players: [p1, p2],
        currentPlayerIndex: 0,
        deck: const [],
        discardPile: [
          const PlayingCard(id: 's2', suit: Suit.spades, rank: Rank.two),
        ],
        activeAttackCard: const PlayingCard(
          id: 's2',
          suit: Suit.spades,
          rank: Rank.two,
        ),
        pendingPenalties: const {'p1': 4},
        nextCascadeLevels: const [2, 1],
      );

      // Alice attempts to play 8 to block (should follow matching rule or be blocked by logic)
      final tempState = GameLogic.playCard(state, 'p1', p1.hand[0]);

      expect(
        tempState,
        state,
        reason: '8 should NOT be playable against 2 of Spades per new rule',
      );
      expect(state.getPenaltyFor('p1'), 4);
      expect(
        state.nextCascadeLevels,
        isNotEmpty,
        reason: 'Cascade should NOT be cancelled',
      );
    });
  });
}
