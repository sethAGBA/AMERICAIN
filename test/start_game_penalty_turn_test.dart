import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/services/game_logic.dart';

void main() {
  group('Start Game Penalty Turn Transition Bug', () {
    late Player dealer, p1;

    setUp(() {
      dealer = Player(
        id: 'dealer',
        name: 'Dealer',
        hand: [],
        position: 0,
        isCurrentTurn: true,
      );
      p1 = Player(id: 'p1', name: 'Alice', hand: [], position: 1);
    });

    test('Ace Start: P1 takes penalty, Turn SHOULD pass to Dealer (P2)', () {
      final aceHearts = PlayingCard(
        id: 'ah',
        suit: Suit.hearts,
        rank: Rank.ace,
      );

      // Setup: 2 Players. Dealer (0), P1 (1).
      // Start card is Ace. P1 starts (Index 1).
      final startState = GameState(
        gameId: 'test',
        players: [dealer, p1],
        deck: [
          const PlayingCard(id: 'd1', suit: Suit.clubs, rank: Rank.three),
          const PlayingCard(id: 'd2', suit: Suit.clubs, rank: Rank.four),
        ],
        discardPile: [aceHearts],
        hostId: 'dealer',
        currentPlayerIndex: 1, // P1 starts
        status: GameStatus.playing,
      );

      final nextState = GameLogic.applyStartCardEffectsForTest(startState);

      // P1 should have drawn 1 card
      expect(
        nextState.players[1].hand.length,
        1,
        reason: "P1 should draw 1 card for Ace",
      );
      expect(
        nextState.getPenaltyFor('p1'),
        0,
        reason: "Penalty should be resolved",
      );

      // BUG REPRODUCTION ASSERTION:
      // Current behavior: currentPlayerIndex stays 1 (P1).
      // Desired behavior: currentPlayerIndex becomes 0 (Dealer).
      // This test expects desired behavior, so it should FAIL currently.
      expect(
        nextState.currentPlayerIndex,
        0,
        reason: "Turn should pass to next player after penalty draw",
      );
      expect(nextState.currentPlayer!.id, 'dealer');
    });

    test('2 Start: P1 takes penalty, Turn SHOULD pass to Dealer (P2)', () {
      final twoHearts = PlayingCard(
        id: '2h',
        suit: Suit.hearts,
        rank: Rank.two,
      );

      // Setup: 2 Players. Dealer (0), P1 (1).
      // Start card is 2. P1 starts.
      final startState = GameState(
        gameId: 'test',
        players: [dealer, p1],
        deck: [
          const PlayingCard(id: 'd1', suit: Suit.clubs, rank: Rank.three),
          const PlayingCard(id: 'd2', suit: Suit.clubs, rank: Rank.four),
          const PlayingCard(id: 'd3', suit: Suit.clubs, rank: Rank.five),
        ],
        discardPile: [twoHearts],
        hostId: 'dealer',
        currentPlayerIndex: 1, // P1 starts
        status: GameStatus.playing,
      );

      final nextState = GameLogic.applyStartCardEffectsForTest(startState);

      // P1 draws 2. Dealer draws 1 (Cascade resolved).
      expect(nextState.players[1].hand.length, 2, reason: "P1 should draw 2");
      expect(
        nextState.players[0].hand.length,
        1,
        reason: "Dealer should draw 1",
      );

      // After everyone draws, who plays?
      // P1 drew (lost turn). Dealer drew (lost turn).
      // Logic for 2 Normal: P1 draws, P2 draws.
      // If P2 drew, their turn effectively passed too?
      // Or does P2 get to play?
      // Rules: "Alice joue 2... Bob pioche 2... Charlie pioche 1... Le jeu continue avec le joueur suivant"
      // Applied to start: P1 draws 2... P2 draws 1... Next player plays.
      // Next player is... P1 again? (in 2 player game).
      // (P1 -> P2 -> P1).

      expect(
        nextState.currentPlayerIndex,
        1,
        reason: "Turn should cycle back to P1 after P2 draws penalty",
      );
    });
  });
}
