import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Jack of Spades 1v1 Logic (Regression)', () {
    test('Human plays Jack Spades: Turn passes to Bot, No Accompaniment', () {
      final p1 = Player(
        id: 'p1',
        name: 'Human',
        position: 0,
        hand: [
          const PlayingCard(id: 'js', suit: Suit.spades, rank: Rank.jack),
          const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two),
        ],
        isCurrentTurn: true,
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bot',
        position: 1,
        hand: [
          const PlayingCard(id: 'c5', suit: Suit.clubs, rank: Rank.five),
          const PlayingCard(id: 'c6', suit: Suit.clubs, rank: Rank.six),
        ],
        isBot: true,
      );

      final state = GameState(
        gameId: 'test',
        players: [p1, p2],
        currentPlayerIndex: 0,
        deck: [],
        discardPile: [
          const PlayingCard(id: 's10', suit: Suit.spades, rank: Rank.ten),
        ],
        hostId: 'p1',
      );

      // Play J-Spades
      final nextState = GameLogic.playCard(state, 'p1', p1.hand[0]);

      // Expectation:
      // 1. P1 played standard card (Js special in 1v1 ends turn).
      // 2. Turn passes to P2 (Bot).
      // 3. No "mustMatchSuit" (accompaniment not required).

      expect(
        nextState.currentPlayerIndex,
        1,
        reason: "Turn should pass to Bot (P2)",
      );
      expect(nextState.currentPlayer!.id, 'p2');
      expect(
        nextState.mustMatchSuit,
        isNull,
        reason: "No accompaniment required for J-Spades in 1v1",
      );

      // Ensure P1 has 1 card left
      expect(nextState.players[0].hand.length, 1);
    });

    test('Bot plays Jack Spades: Turn passes to Human, No Accompaniment', () {
      final p1 = Player(
        id: 'p1',
        name: 'Human',
        position: 0,
        hand: [const PlayingCard(id: 'h2', suit: Suit.hearts, rank: Rank.two)],
      );
      final p2 = Player(
        id: 'p2',
        name: 'Bot',
        position: 1,
        hand: [
          const PlayingCard(id: 'js', suit: Suit.spades, rank: Rank.jack),
          const PlayingCard(id: 'c2', suit: Suit.clubs, rank: Rank.two),
        ],
        isBot: true,
      );

      final state = GameState(
        gameId: 'test',
        players: [p1, p2],
        currentPlayerIndex: 1, // Bot starts
        deck: [],
        discardPile: [
          const PlayingCard(id: 's10', suit: Suit.spades, rank: Rank.ten),
        ],
        hostId: 'p1',
      );

      // Bot plays J-Spades
      final nextState = GameLogic.playCard(state, 'p2', p2.hand[0]);

      // Expectation:
      // 1. Turn passes to P1 (Human).
      // 2. No "mustMatchSuit".

      expect(
        nextState.currentPlayerIndex,
        0,
        reason: "Turn should pass to Human (P1)",
      );
      expect(nextState.currentPlayer!.id, 'p1');
      expect(
        nextState.mustMatchSuit,
        isNull,
        reason: "No accompaniment required",
      );

      // Ensure Bot has 1 card left
      expect(nextState.players[1].hand.length, 1);
    });
  });
}
