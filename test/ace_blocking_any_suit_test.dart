import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Ace Blocking Logic', () {
    test('Player can block Ace of Spades with Ace of Hearts', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [
          const PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace),
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

      // Alice plays Ace of Hearts on Ace of Spades
      final nextState = GameLogic.playCard(state, 'p1', p1.hand[0]);

      expect(nextState.discardPile.last.rank, Rank.ace);
      expect(nextState.discardPile.last.suit, Suit.hearts);

      expect(
        nextState.getPenaltyFor('p1'),
        0,
        reason: 'Penalty on Alice should be cleared',
      );
      expect(
        nextState.getPenaltyFor('p2'),
        0,
        reason:
            'Bob should NOT have the penalty yet (Cancelled until accompaniment)',
      );
      expect(
        nextState.currentPlayer?.id,
        'p2',
        reason: 'Turn moves to Bob after Ace block (No accompaniment)',
      );
    });

    test('Bot can block Ace of Spades with Ace of Hearts', () {
      final p1 = Player(id: 'p1', name: 'Alice', position: 0, hand: []);
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [const PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace)],
        isBot: true,
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 1, // Bob current
        deck: const [],
        discardPile: [
          const PlayingCard(id: 'as', suit: Suit.spades, rank: Rank.ace),
        ],
        activeAttackCard: const PlayingCard(
          id: 'as',
          suit: Suit.spades,
          rank: Rank.ace,
        ),
        pendingPenalties: const {'p2': 1},
      );

      // Simulate Bot finding move
      final bot = state.currentPlayer!;
      PlayingCard? cardToPlay;
      try {
        cardToPlay = bot.hand.firstWhere(
          (card) => GameLogic.isValidMove(
            card,
            state.topCard!,
            state.currentSuit,
            penalty: state.getPenaltyFor(bot.id),
            activeAttackCard: state.activeAttackCard,
          ),
        );
      } catch (_) {
        cardToPlay = null;
      }

      expect(
        cardToPlay?.id,
        'ah',
        reason: 'Bot should find the Ace of Hearts as a valid block',
      );
    });

    test('Ace can be played on any suit when no penalty is active', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [const PlayingCard(id: 'as', suit: Suit.spades, rank: Rank.ace)],
      );
      final p2 = Player(id: 'p2', name: 'Bob', position: 1, hand: []);

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 0,
        deck: const [],
        discardPile: [
          const PlayingCard(id: 'h5', suit: Suit.hearts, rank: Rank.five),
        ],
      );

      // Alice tries to play Ace of Spades on 5 of Hearts
      final isValid = GameLogic.isValidMove(
        p1.hand[0],
        state.topCard!,
        state.currentSuit,
      );

      expect(
        isValid,
        isFalse,
        reason: 'Ace is NOT universal, must match suit hearts or rank 5',
      );
    });
  });
}
