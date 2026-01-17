import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Joker & Stacking Mechanics', () {
    late GameState state;
    late Player p1, p2, p3;

    setUp(() {
      final dummy = PlayingCard(id: 'dummy', suit: Suit.clubs, rank: Rank.two);
      p1 = Player(
        id: 'p1',
        name: 'Alice',
        hand: [dummy],
        position: 0,
        isCurrentTurn: true,
      );
      p2 = Player(id: 'p2', name: 'Bob', hand: [dummy], position: 1);
      p3 = Player(id: 'p3', name: 'Charlie', hand: [dummy], position: 2);
      state = GameState(
        gameId: 'test',
        players: [p1, p2, p3],
        deck: [PlayingCard(id: 'deck', suit: Suit.clubs, rank: Rank.two)],
        discardPile: [],
        hostId: 'p1',
      );
    });

    test('Ace can be played on Ace (Blocking)', () {
      final aceHearts = PlayingCard(
        id: 'ah',
        suit: Suit.hearts,
        rank: Rank.ace,
      );
      final aceSpades = PlayingCard(
        id: 'as',
        suit: Suit.spades,
        rank: Rank.ace,
      );

      // P1 plays Ace Hearts
      var nextState = GameLogic.playCard(
        state.copyWith(
          players: [
            p1.copyWith(hand: [aceHearts]),
            p2,
            p3,
          ],
          discardPile: [aceHearts],
        ),
        'p1',
        aceHearts,
      );

      // P2 penalized.
      expect(nextState.getPenaltyFor('p2'), 1);
      expect(nextState.activeAttackCard!.rank, Rank.ace);

      // P2 defends with Ace Spades
      // isValidMove check
      expect(
        GameLogic.isValidMove(
          aceSpades,
          aceHearts,
          null,
          penalty: 1,
          activeAttackCard: aceHearts,
        ),
        true,
      );
    });

    test('Jack can be played on Jack (Accumulation logic check)', () {
      final jackHearts = PlayingCard(
        id: 'jh',
        suit: Suit.hearts,
        rank: Rank.jack,
      );
      final jackClubs = PlayingCard(
        id: 'jc',
        suit: Suit.clubs,
        rank: Rank.jack,
      );

      // Using "Accompaniment" logic, playing Jack on Jack is a valid MATCH.
      expect(GameLogic.isValidMove(jackClubs, jackHearts, null), true);
    });

    test(
      'Joker Glide (Defense): TRANSFERS penalty and slides UNDER attack card',
      () {
        final twoSpades = PlayingCard(
          id: '2s',
          suit: Suit.spades,
          rank: Rank.two,
        );
        final joker = PlayingCard(
          id: 'joker',
          suit: Suit.hearts,
          rank: Rank.joker,
        );

        // Setup: P1 played 2 Spades. P2 is under penalty.
        var penaltyState = state.copyWith(
          players: [
            p1,
            p2.copyWith(hand: [joker], isCurrentTurn: true),
            p3,
          ],
          discardPile: [twoSpades],
          activeAttackCard: twoSpades,
          pendingPenalties: {'p2': 4},
          currentPlayerIndex: 1,
        );

        // P2 plays Joker to defend
        var nextState = GameLogic.playCard(penaltyState, 'p2', joker);

        // 1. P2 penalty cleared.
        expect(nextState.getPenaltyFor('p2'), 0);

        // 2. P3 penalized (Transfer).
        expect(
          nextState.getPenaltyFor('p3'),
          4,
          reason: 'Penalty should transfer to P3',
        );

        // 3. Top Card remains 2 Spades (Visually).
        expect(nextState.topCard!.id, '2s');

        // 4. Joker is in pile (second to last).
        expect(nextState.discardPile.length, 2);

        // 5. Active Attack Card remains 2 Spades.
        expect(nextState.activeAttackCard!.id, '2s');
      },
    );

    test('Joker Glide (Neutral): Just slides, NO penalty', () {
      final fiveHearts = PlayingCard(
        id: '5h',
        suit: Suit.hearts,
        rank: Rank.five,
      );
      final joker = PlayingCard(
        id: 'joker2',
        suit: Suit.spades,
        rank: Rank.joker,
      );

      // Setup: Neutral state. Top is 5H.
      var neutralState = state.copyWith(
        players: [
          p1,
          p2.copyWith(hand: [joker], isCurrentTurn: true),
          p3,
        ],
        discardPile: [fiveHearts],
        activeAttackCard: null,
        pendingPenalties: {},
        currentPlayerIndex: 1,
      );

      // P2 plays Joker freely
      var nextState = GameLogic.playCard(neutralState, 'p2', joker);

      // 1. Joker slides under
      expect(nextState.topCard!.id, '5h');
      expect(nextState.discardPile.length, 2);

      // 2. P3 has NO penalty (Neutral Joker does not add +4)
      expect(
        nextState.getPenaltyFor('p3'),
        0,
        reason: 'Neutral Joker should add 0 penalty',
      );

      // 3. Game continues
      // Current Suit should still likely be Hearts (from 5H)
      // or implicit from top card.
    });
  });
}
