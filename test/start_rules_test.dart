import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Start Rules (Dealer & Special Cards)', () {
    late Player dealer, p1;

    setUp(() {
      // Setup logic usually creates state.
      // We will manually construct state in each test to control the Deck/Discard.
      dealer = Player(
        id: 'dealer',
        name: 'Dealer',
        hand: [],
        position: 0,
        isCurrentTurn: true,
      );
      p1 = Player(id: 'p1', name: 'Alice', hand: [], position: 1);
    });

    test('Ace turned: First Player +1', () {
      final aceHearts = PlayingCard(
        id: 'ah',
        suit: Suit.hearts,
        rank: Rank.ace,
      );

      // Setup: 2 Players. Dealer (0), P1 (1).
      // Deal logic sets P1 as starts (Index 1).
      final startState = GameState(
        gameId: 'test',
        players: [dealer, p1],
        deck: [],
        discardPile: [aceHearts],
        hostId: 'dealer',
        currentPlayerIndex: 1, // P1 starts
        status: GameStatus.playing,
      );

      final nextState = GameLogic.applyStartCardEffectsForTest(startState);

      // P1 should be penalized (+1)
      expect(nextState.getPenaltyFor('p1'), 1);
      // P1 should still be current player (to play or defend)
      expect(nextState.currentPlayerIndex, 1);
    });

    test('Jack turned: Skips P1, Dealer plays (2 Players)', () {
      final jackHearts = PlayingCard(
        id: 'jh',
        suit: Suit.hearts,
        rank: Rank.jack,
      );

      // Setup: 2 Players. Dealer (0), P1 (1). Starts at P1 (1).
      final startState = GameState(
        gameId: 'test',
        players: [dealer, p1],
        deck: [],
        discardPile: [jackHearts],
        hostId: 'dealer',
        currentPlayerIndex: 1,
        status: GameStatus.playing,
      );

      final nextState = GameLogic.applyStartCardEffectsForTest(startState);

      // Skips 1 player (P1). Next = (1+1)%2 = 0 (Dealer).
      // Dealer should be current.
      expect(nextState.currentPlayer!.id, 'dealer');
    });

    test('Jack Spades turned: Skips P1, Dealer plays (2 Players)', () {
      final jackSpades = PlayingCard(
        id: 'js',
        suit: Suit.spades,
        rank: Rank.jack,
      );

      // Setup: 2 Players. Dealer (0), P1 (1). Starts at P1 (1).
      final startState = GameState(
        gameId: 'test',
        players: [dealer, p1],
        deck: [],
        discardPile: [jackSpades],
        hostId: 'dealer',
        currentPlayerIndex: 1,
        status: GameStatus.playing,
      );

      final nextState = GameLogic.applyStartCardEffectsForTest(startState);

      // Rule: "Exception à 2 joueurs : Le ♠J saute le 1er joueur, donc le 2e recommence"
      // Skips 1 player (P1). Next = (1+1)%2 = 0 (Dealer).
      // Dealer should be current.
      expect(nextState.currentPlayer!.id, 'dealer');
    });
  });
}
