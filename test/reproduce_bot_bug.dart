import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/services/game_logic.dart';
import 'package:jeu_8_americain/models/game_state.dart';
import 'package:jeu_8_americain/models/player.dart';
import 'package:jeu_8_americain/models/card.dart';

void main() {
  test('Bot chooses invalid card under penalty with current logic', () {
    // Setup
    final player1 = Player(id: 'p1', name: 'Human', hand: [], position: 0);
    final bot = Player(
      id: 'bot',
      name: 'Bot',
      hand: [const PlayingCard(id: 'c1', suit: Suit.hearts, rank: Rank.seven)],
      position: 1,
      isBot: true,
    );

    // Game state where bot is under penalty (+2) and top card is 2 of Hearts
    final state = GameState(
      gameId: 'test',
      players: [player1, bot],
      deck: [],
      discardPile: [
        const PlayingCard(id: 'top', suit: Suit.hearts, rank: Rank.two),
      ],
      hostId: 'p1',
      status: GameStatus.playing,
      currentPlayerIndex: 1, // Bot's turn
      pendingPenalties: {'bot': 2}, // Bot must draw 2 or defend
      activeAttackCard: const PlayingCard(
        id: 'top',
        suit: Suit.hearts,
        rank: Rank.two,
      ),
    );

    // Current Bot Logic (Simulated)
    final topCard = state.topCard!;
    final currentSuit = state.currentSuit;

    // This is the problematic logic in GameNotifier._handleBotTurn
    PlayingCard? cardToPlay;
    try {
      cardToPlay = bot.hand.firstWhere(
        (card) => card.canPlayOn(topCard, currentSuit: currentSuit),
      );
    } catch (_) {
      cardToPlay = null;
    }

    // Expectation: Bot finds 7 of Hearts because canPlayOn only checks suit/rank
    expect(cardToPlay, isNotNull);
    expect(cardToPlay!.rank, Rank.seven);

    // However, this move is INVALID according to GameLogic
    final isValid = GameLogic.isValidMove(
      cardToPlay,
      topCard,
      state.currentSuit,
      penalty: state.getPenaltyFor('bot'),
      activeAttackCard: state.activeAttackCard,
    );

    expect(
      isValid,
      isFalse,
      reason: "Move should be invalid due to active penalty",
    );

    // Attempting to play it should result in NO change
    final nextState = GameLogic.playCard(state, 'bot', cardToPlay);
    expect(
      nextState,
      equals(state),
      reason: "State should not change for invalid move",
    );

    // Verified Logic (What is now in GameNotifier)
    PlayingCard? fixedCardToPlay;
    try {
      fixedCardToPlay = bot.hand.firstWhere(
        (card) => GameLogic.isValidMove(
          card,
          topCard,
          state.currentSuit,
          penalty: state.getPenaltyFor('bot'),
          activeAttackCard: state.activeAttackCard,
        ),
      );
    } catch (_) {
      fixedCardToPlay = null;
    }

    // Expectation: Bot should NOT find a card to play (because it's invalid under penalty)
    // and thus will proceed to the 'else' block in GameNotifier to Draw.
    expect(
      fixedCardToPlay,
      isNull,
      reason:
          "Bot should properly identify that it cannot play any card and must draw",
    );
  });
}
