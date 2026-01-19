import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Bot Loop and Turn Logic Refinement', () {
    test('Turn SHOULD pass after drawing a penalty (Loss of turn)', () {
      final player = Player(
        id: 'p1',
        name: 'Player',
        hand: [const PlayingCard(id: 'c1', suit: Suit.hearts, rank: Rank.five)],
        position: 0,
      );
      final bot = Player(
        id: 'bot',
        name: 'Bot',
        hand: [
          const PlayingCard(id: 'c2', suit: Suit.hearts, rank: Rank.seven),
        ],
        position: 1,
        isBot: true,
      );

      final state = GameState(
        gameId: 'test',
        players: [player, bot],
        deck: [
          const PlayingCard(id: 'd1', suit: Suit.hearts, rank: Rank.three),
        ],
        discardPile: [
          const PlayingCard(id: 'top', suit: Suit.hearts, rank: Rank.ace),
        ],
        hostId: 'p1',
        currentPlayerIndex: 1, // Bot's turn
        pendingPenalties: const {'bot': 1},
        activeAttackCard: const PlayingCard(
          id: 'top',
          suit: Suit.hearts,
          rank: Rank.ace,
        ),
      );

      // Bot draws penalty
      final result = GameLogic.drawCard(state, 'bot');

      // EXPECTATION: Turn stays with bot so it can play its regular turn
      expect(
        result.currentPlayerIndex,
        0,
        reason: 'Turn should pass to next player after penalty draw',
      );
      expect(result.lastTurnWasForcedDraw, isTrue);
    });

    test(
      'Turn should NOT pass after blocking a 2 (must be able to accompany)',
      () {
        final player = Player(id: 'p1', name: 'Player', hand: [], position: 0);
        final bot = Player(
          id: 'bot',
          name: 'Bot',
          hand: [
            const PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two),
            const PlayingCard(id: '5h', suit: Suit.hearts, rank: Rank.five),
          ],
          position: 1,
          isBot: true,
        );

        final state = GameState(
          gameId: 'test',
          players: [player, bot],
          deck: [],
          discardPile: [
            const PlayingCard(id: '2d', suit: Suit.diamonds, rank: Rank.two),
          ],
          hostId: 'p1',
          currentPlayerIndex: 1, // Bot's turn
          pendingPenalties: const {'bot': 2},
          activeAttackCard: const PlayingCard(
            id: '2d',
            suit: Suit.diamonds,
            rank: Rank.two,
          ),
        );

        // Bot plays 2h to block 2s
        final result = GameLogic.playCard(state, 'bot', bot.hand[0]);

        // EXPECTATION: Turn stays with bot for accompaniment
        expect(
          result.currentPlayerIndex,
          1,
          reason: 'Turn should stay with bot after blocking a 2',
        );
        expect(
          result.mustMatchSuit,
          Suit.hearts,
          reason: 'Must match suit of the blocking 2',
        );
      },
    );

    test('Turn SHOULD pass after blocking an Ace (No accompaniment)', () {
      final player = Player(
        id: 'p1',
        name: 'Player',
        hand: [const PlayingCard(id: 'c1', suit: Suit.clubs, rank: Rank.three)],
        position: 0,
      );
      final bot = Player(
        id: 'bot',
        name: 'Bot',
        hand: [
          const PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace),
          const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two),
        ],
        position: 1,
        isBot: true,
      );

      final state = GameState(
        gameId: 'test',
        players: [player, bot],
        deck: [],
        discardPile: [
          const PlayingCard(id: 'as', suit: Suit.spades, rank: Rank.ace),
        ],
        hostId: 'p1',
        currentPlayerIndex: 1, // Bot's turn
        pendingPenalties: const {'bot': 1},
        activeAttackCard: const PlayingCard(
          id: 'as',
          suit: Suit.spades,
          rank: Rank.ace,
        ),
      );

      // Bot plays ah to block as
      final result = GameLogic.playCard(state, 'bot', bot.hand[0]);

      // EXPECTATION: Turn passes to next player (player)
      expect(
        result.currentPlayerIndex,
        0,
        reason: 'Turn should pass after blocking an Ace',
      );
    });
  });
}
