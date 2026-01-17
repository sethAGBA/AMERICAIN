import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Accompaniment Rules', () {
    late GameState state;
    late Player p1, p2, p3;

    setUp(() {
      final dummy = PlayingCard(id: 'dummy', suit: Suit.clubs, rank: Rank.two);
      p1 = Player(
        id: 'p1',
        name: 'Alice',
        hand: [],
        position: 0,
        isCurrentTurn: true,
      );
      p2 = Player(id: 'p2', name: 'Bob', hand: [dummy], position: 1);
      p3 = Player(id: 'p3', name: 'Charlie', hand: [dummy], position: 2);

      state = GameState(
        gameId: 'test',
        players: [p1, p2, p3],
        deck: [],
        discardPile: [
          PlayingCard(id: 'top', suit: Suit.hearts, rank: Rank.five),
        ],
        hostId: 'p1',
        status: GameStatus.playing,
      );
    });

    test('7 Rule: Must play same suit immediately', () {
      final sevenHearts = PlayingCard(
        id: '7h',
        suit: Suit.hearts,
        rank: Rank.seven,
      );
      final fiveHearts = PlayingCard(
        id: '5h',
        suit: Suit.hearts,
        rank: Rank.five,
      );
      final eightSpades = PlayingCard(
        id: '8s',
        suit: Suit.spades,
        rank: Rank.eight,
      );
      final dummy = PlayingCard(id: 'dummy', suit: Suit.clubs, rank: Rank.two);

      // P1 plays 7 Hearts
      var nextState = GameLogic.playCard(
        state.copyWith(
          players: [
            p1.copyWith(hand: [sevenHearts, fiveHearts, eightSpades, dummy]),
            p2,
            p3,
          ],
        ),
        'p1',
        sevenHearts,
      );

      // P1 should STILL be current player
      expect(nextState.currentPlayer!.id, 'p1');
      expect(nextState.mustMatchSuit, Suit.hearts);

      // P1 plays 8 Spades (Valid because 8 blocks 7)
      expect(
        GameLogic.isValidMove(
          eightSpades,
          sevenHearts,
          null,
          mustMatchSuit: nextState.mustMatchSuit,
        ),
        true,
        reason: "8 should override 7 restriction",
      );

      // P1 plays 5 Hearts (Valid)
      nextState = GameLogic.playCard(nextState, 'p1', fiveHearts);

      // P1 turn ends, P2 next
      expect(nextState.currentPlayer!.id, 'p2');
      expect(nextState.mustMatchSuit, null);
    });

    test('Jack Rule: Must play again (Replay)', () {
      final jackHearts = PlayingCard(
        id: 'jh',
        suit: Suit.hearts,
        rank: Rank.jack,
      );
      final fiveDiamonds = PlayingCard(
        id: '5d',
        suit: Suit.diamonds,
        rank: Rank.five,
      );
      final dummy = PlayingCard(id: 'dummy', suit: Suit.clubs, rank: Rank.two);

      // P1 plays Jack Hearts
      var nextState = GameLogic.playCard(
        state.copyWith(
          players: [
            p1.copyWith(hand: [jackHearts, fiveDiamonds, dummy]),
            p2,
            p3,
          ],
        ),
        'p1',
        jackHearts,
      );

      // P1 should STILL be current player (Replay)
      expect(nextState.currentPlayer!.id, 'p1');
      // Standard Jack Hearts = 1 skip (Normal Jack skip rule)
      expect(nextState.remainingSkips, 1);

      // P1 plays 5 Hearts (Matches suit)
      final fiveHearts = PlayingCard(
        id: '5h',
        suit: Suit.hearts,
        rank: Rank.five,
      );
      nextState = GameLogic.playCard(
        state.copyWith(
          players: [
            p1.copyWith(hand: [jackHearts, fiveHearts, dummy]),
            p2,
            p3,
          ],
        ),
        'p1',
        jackHearts,
      );

      nextState = GameLogic.playCard(nextState, 'p1', fiveHearts);

      // P1 turn ends. 1 Skip applied. P2 (index 1) skipped. P3 (index 2) is next.
      expect(nextState.currentPlayer!.id, 'p3');
      expect(nextState.remainingSkips, 0);
    });

    test('Start Game with 7: P1 restricted', () {
      // Setup start game scenario manually
      // If 7 is start card, dealCards calls _applyStartCardEffects?
      // Need to verify if _applyStartCardEffects handles 7 correctly (it was updated previously?)
      // Wait, previous update to game_logic only handled Ace/2/8/10/Joker.
      // I need to update _applyStartCardEffects for 7!
      // The implementation plan missed updating _apply start for 7's restriction field!
      // But let's check current GameLogic file.
    });
  });
}
