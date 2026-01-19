import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Ace Robot Logic Tests', () {
    test('Scenario 1: Player draws for Ace, then turn passes', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [const PlayingCard(id: 'h5', suit: Suit.hearts, rank: Rank.five)],
        isCurrentTurn: true,
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [
          const PlayingCard(id: 'd10', suit: Suit.diamonds, rank: Rank.ten),
        ],
        isBot: true,
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 0,
        discardPile: [
          const PlayingCard(id: 'as', suit: Suit.spades, rank: Rank.ace),
        ],
        deck: [
          const PlayingCard(id: 'h7', suit: Suit.hearts, rank: Rank.seven),
        ],
        activeAttackCard: const PlayingCard(
          id: 'as',
          suit: Suit.spades,
          rank: Rank.ace,
        ),
        pendingPenalties: const {'p1': 1},
      );

      // 1. Draw card for penalty
      state = GameLogic.drawCard(state, 'p1');

      // EXPECT: Turn stays with Alice (so she can play her regular turn)
      expect(state.getPenaltyFor('p1'), 0);
      expect(
        state.currentPlayer?.id,
        'p2',
        reason: 'Turn should PASS after drawing penalty for Ace',
      );
    });

    test('Scenario 2: Bob draws for Ace, then turn passes', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [
          const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two),
          const PlayingCard(id: 'h3', suit: Suit.hearts, rank: Rank.three),
        ],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [const PlayingCard(id: 'h5', suit: Suit.hearts, rank: Rank.five)],
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 1, // Bob turn
        discardPile: [
          const PlayingCard(id: 'as', suit: Suit.spades, rank: Rank.ace),
        ],
        deck: [const PlayingCard(id: 'h10', suit: Suit.hearts, rank: Rank.ten)],
        activeAttackCard: const PlayingCard(
          id: 'as',
          suit: Suit.spades,
          rank: Rank.ace,
        ),
        pendingPenalties: const {'p2': 1},
      );

      // 1. Bob draws for Ace
      state = GameLogic.drawCard(state, 'p2');
      expect(state.getPenaltyFor('p2'), 0);
      expect(
        state.currentPlayer?.id,
        'p1',
        reason: 'Turn should PASS after drawing penalty for Ace',
      );
    });

    test('Scenario 3: Ace recursive sequence replication', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [
          const PlayingCard(id: 'h10', suit: Suit.hearts, rank: Rank.ten),
          const PlayingCard(id: 's5', suit: Suit.spades, rank: Rank.five),
        ],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [
          const PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace),
          const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two),
        ],
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 1, // Bob
        discardPile: [
          const PlayingCard(id: 'h5', suit: Suit.hearts, rank: Rank.five),
        ],
        deck: [
          const PlayingCard(id: 'd9', suit: Suit.diamonds, rank: Rank.nine),
        ],
      );

      // Bob plays Ace of Hearts
      state = GameLogic.playCard(state, 'p2', p2.hand[0]);

      // Expect Alice to be targeted, turn passes to Alice (Standard play)
      expect(state.getPenaltyFor('p1'), 1);
      expect(state.currentPlayer?.id, 'p1');
    });

    test('Scenario 4: 2 Spades 4-2-1 Cascade in 1v1', () {
      final p1 = Player(
        id: 'p1',
        name: 'Alice',
        position: 0,
        hand: [const PlayingCard(id: 's2', suit: Suit.spades, rank: Rank.two)],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bob',
        position: 1,
        hand: [
          const PlayingCard(id: 'h10', suit: Suit.hearts, rank: Rank.ten),
          const PlayingCard(id: 's9', suit: Suit.spades, rank: Rank.nine),
        ],
      );

      var state = GameState(
        gameId: 'test',
        hostId: 'p1',
        players: [p1, p2],
        currentPlayerIndex: 0,
        discardPile: [
          const PlayingCard(id: 's5', suit: Suit.spades, rank: Rank.five),
        ],
        deck: [const PlayingCard(id: 'xx', suit: Suit.clubs, rank: Rank.six)],
      );

      // Alice plays 2 Spades
      state = GameLogic.playCard(state, 'p1', p1.hand[0]);

      // NEW Sequential Rule:
      // Bob (getIdAt(1)) gets 4 IMMEDIATELY.
      // Alice (getIdAt(2)) will get 2 ONLY AFTER Bob draws.
      // Next Cascade Levels: [2, 1]

      expect(state.getPenaltyFor('p2'), 4);
      expect(state.nextCascadeLevels, [2, 1]);
      expect(state.getPenaltyFor('p1'), 0);
    });
  });
}
