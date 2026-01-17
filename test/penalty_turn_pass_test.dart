import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Penalty Turn Pass Verification (1v1)', () {
    late GameState state;
    late Player alice, bob;

    setUp(() {
      alice = Player(
        id: 'alice',
        name: 'Alice',
        hand: [
          const PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two),
          const PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace),
        ],
        position: 0,
      );

      bob = Player(
        id: 'bob',
        name: 'Bob',
        hand: [
          const PlayingCard(id: '7h', suit: Suit.hearts, rank: Rank.seven),
        ],
        position: 1,
      );

      state = GameState(
        gameId: '1v1_test',
        players: [alice, bob],
        deck: const [
          PlayingCard(id: 'd1', suit: Suit.spades, rank: Rank.three),
        ],
        discardPile: const [
          PlayingCard(id: 'start', suit: Suit.hearts, rank: Rank.five),
        ],
        hostId: 'alice',
        currentPlayerIndex: 0,
      );
    });

    test('Alice plays Ace -> Bob draws -> Turn to Alice', () {
      var s = GameLogic.playCard(state, 'alice', alice.hand[1]);
      expect(s.currentPlayerIndex, 1);

      s = GameLogic.drawCard(s, 'bob');
      expect(
        s.currentPlayerIndex,
        0,
        reason: "Turn MUST return to Alice after Bob draws Ace penalty",
      );
    });

    test(
      'Alice plays 2 -> Bob draws penalty -> Turn to Alice (Sequential)',
      () {
        var s = GameLogic.playCard(state, 'alice', alice.hand[0]);
        expect(s.currentPlayerIndex, 1);
        expect(s.pendingPenalties['bob'], 2);
        expect(s.nextCascadeLevels, [1], reason: 'Cascade level 1 pending');

        // Bob draws 2 cards
        s = GameLogic.drawCard(s, 'bob');
        expect(
          s.currentPlayerIndex,
          0,
          reason: "Turn MUST return to Alice after Bob draws 2-penalty",
        );
        expect(
          s.pendingPenalties['alice'],
          1,
          reason: 'Alice gets cascade penalty of 1',
        );
      },
    );
  });

  group('Penalty Turn Pass Verification (3 Players - Sequential)', () {
    late GameState state;
    late Player alice, bob, charlie;

    setUp(() {
      alice = Player(
        id: 'alice',
        name: 'Alice',
        hand: const [
          PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two),
          PlayingCard(id: 'dummyA', suit: Suit.clubs, rank: Rank.four),
        ],
        position: 0,
      );

      bob = Player(
        id: 'bob',
        name: 'Bob',
        hand: const [
          PlayingCard(id: '7h', suit: Suit.hearts, rank: Rank.seven),
        ],
        position: 1,
      );

      charlie = Player(
        id: 'charlie',
        name: 'Charlie',
        hand: const [
          PlayingCard(id: '8h', suit: Suit.hearts, rank: Rank.eight),
        ],
        position: 2,
      );

      state = GameState(
        gameId: '3p_test',
        players: [alice, bob, charlie],
        deck: const [
          PlayingCard(id: 'd1', suit: Suit.spades, rank: Rank.three),
          PlayingCard(id: 'd2', suit: Suit.spades, rank: Rank.four),
          PlayingCard(id: 'd3', suit: Suit.spades, rank: Rank.five),
        ],
        discardPile: const [
          PlayingCard(id: 'start', suit: Suit.hearts, rank: Rank.five),
        ],
        hostId: 'alice',
        currentPlayerIndex: 0,
      );
    });

    test(
      'Alice plays 2 -> Bob draws (2) -> Charlie gets penalty (1) -> Charlie draws',
      () {
        // 1. Alice plays 2 (Sequential: Bob gets 2 immediately, cascade [1] pending)
        var s = GameLogic.playCard(state, 'alice', alice.hand[0]);
        expect(s.currentPlayerIndex, 1);
        expect(s.pendingPenalties['bob'], 2);
        expect(s.nextCascadeLevels, [1], reason: 'Cascade level 1 pending');
        expect(
          s.pendingPenalties['charlie'],
          isNull,
          reason: 'Charlie not yet targeted',
        );

        // 2. Bob draws (2 cards)
        s = GameLogic.drawCard(s, 'bob');
        expect(
          s.currentPlayerIndex,
          2,
          reason: "Turn passes to Charlie after Bob draws",
        );
        expect(
          s.pendingPenalties['bob'] ?? 0,
          0,
          reason: 'Bob penalty cleared',
        );
        expect(
          s.pendingPenalties['charlie'],
          1,
          reason: 'Charlie now gets cascade penalty',
        );

        // 3. Charlie draws (1 card)
        s = GameLogic.drawCard(s, 'charlie');
        expect(
          s.currentPlayerIndex,
          0,
          reason: "Turn returns to Alice after all penalties drawn",
        );
        expect(s.pendingPenalties.isEmpty, true);
        expect(s.nextCascadeLevels, isEmpty, reason: 'Cascade complete');
      },
    );
  });
}
