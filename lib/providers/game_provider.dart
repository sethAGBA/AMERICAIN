import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/game_state.dart';
import '../models/card.dart';
import '../services/game_logic.dart';
import '../services/socket_service.dart';
import '../services/sound_service.dart';

const _uuid = Uuid();

// Provider for the socket service
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

// Provider for current player ID
final currentPlayerIdProvider = StateProvider<String?>((ref) => null);

// Provider for current player name
final currentPlayerNameProvider = StateProvider<String?>((ref) => null);

// Provider for game state
final gameStateProvider = StateProvider<GameState?>((ref) => null);

// Game notifier for managing game actions
final gameNotifierProvider = StateNotifierProvider<GameNotifier, void>((ref) {
  return GameNotifier(ref);
});

class GameNotifier extends StateNotifier<void> {
  final Ref ref;
  bool _isHandlingBotTurn = false;

  GameNotifier(this.ref) : super(null);

  /// Create a new game (offline mode for now)
  void createGame(String gameCode, String playerName) {
    final playerId = _uuid.v4();

    // Store player info
    ref.read(currentPlayerIdProvider.notifier).state = playerId;
    ref.read(currentPlayerNameProvider.notifier).state = playerName;

    // Create game state
    final gameState = GameLogic.createGame(gameCode, playerId, playerName);
    ref.read(gameStateProvider.notifier).state = gameState;
  }

  /// Join an existing game (offline mode - just creates a local game for demo)
  void joinGame(String gameCode, String playerName) {
    final playerId = _uuid.v4();

    // Store player info
    ref.read(currentPlayerIdProvider.notifier).state = playerId;
    ref.read(currentPlayerNameProvider.notifier).state = playerName;

    // For demo purposes, create a new game
    // In production, this would connect to an existing game via socket
    final gameState = GameLogic.createGame(gameCode, playerId, playerName);
    ref.read(gameStateProvider.notifier).state = gameState;
  }

  /// Add a player to the game (for testing)
  void addPlayer(String playerName) {
    final currentState = ref.read(gameStateProvider);
    if (currentState == null) return;

    final playerId = _uuid.v4();
    final updatedState = GameLogic.addPlayer(
      currentState,
      playerId,
      playerName,
    );
    ref.read(gameStateProvider.notifier).state = updatedState;
  }

  /// Start the game
  void startGame() {
    var currentState = ref.read(gameStateProvider);
    if (currentState == null) return;

    // If only 1 player, add a Bot
    if (currentState.players.length == 1) {
      final botId = _uuid.v4();
      currentState = GameLogic.addPlayer(
        currentState,
        botId,
        'Robot 🤖',
        isBot: true,
      );
    }

    // Deal cards to all players
    final updatedState = GameLogic.dealCards(currentState);
    ref.read(gameStateProvider.notifier).state = updatedState;

    // Check if first player is bot (unlikely as host starts, but good to check)
    if (updatedState.currentPlayer?.isBot == true) {
      _handleBotTurn();
    }
  }

  /// Play a card
  void playCard(PlayingCard card, {Suit? chosenSuit}) {
    final currentState = ref.read(gameStateProvider);
    final playerId = ref.read(currentPlayerIdProvider);

    if (currentState == null || playerId == null) return;

    final updatedState = GameLogic.playCard(
      currentState,
      playerId,
      card,
      chosenSuit: chosenSuit,
    );

    ref.read(gameStateProvider.notifier).state = updatedState;
    SoundService.playCard();

    // Check if next player is bot
    if (!updatedState.isGameOver && updatedState.currentPlayer?.isBot == true) {
      _handleBotTurn();
    }
  }

  /// Draw a card from the deck
  void drawCard() {
    final currentState = ref.read(gameStateProvider);
    final playerId = ref.read(currentPlayerIdProvider);

    if (currentState == null || playerId == null) return;

    SoundService.drawCard();

    var updatedState = GameLogic.drawCard(currentState, playerId);

    ref.read(gameStateProvider.notifier).state = updatedState;

    // Check if next player is bot
    if (!updatedState.isGameOver && updatedState.currentPlayer?.isBot == true) {
      _handleBotTurn();
    }
  }

  /// Handle Bot turn with artificial delay
  Future<void> _handleBotTurn() async {
    if (_isHandlingBotTurn) return;
    _isHandlingBotTurn = true;

    try {
      // Artificial delay for realism
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

      final currentState = ref.read(gameStateProvider);
      if (currentState == null || currentState.currentPlayer?.isBot != true) {
        _isHandlingBotTurn = false;
        return;
      }

      final bot = currentState.currentPlayer!;
      final topCard = currentState.topCard;

      if (topCard == null) {
        _isHandlingBotTurn = false;
        return;
      }

      // Logic: Find first playable card
      PlayingCard? cardToPlay;
      Suit? chosenSuit; // For 8s

      try {
        cardToPlay = bot.hand.firstWhere(
          (card) => GameLogic.isValidMove(
            card,
            topCard,
            currentState.currentSuit,
            penalty: currentState.getPenaltyFor(bot.id),
            activeAttackCard: currentState.activeAttackCard,
            mustMatchSuit: currentState.mustMatchSuit,
          ),
        );

        // If playing an 8, choose a random suit (or smart suit based on hand)
        if (cardToPlay.isSpecial) {
          // Simple AI: choose suit of next card in hand, or random
          final suits = Suit.values;
          chosenSuit = suits[Random().nextInt(suits.length)];
        }
      } catch (_) {
        // No playable card found
        cardToPlay = null;
      }

      if (cardToPlay != null) {
        // Play the card
        final updatedState = GameLogic.playCard(
          currentState,
          bot.id,
          cardToPlay,
          chosenSuit: chosenSuit,
        );
        ref.read(gameStateProvider.notifier).state = updatedState;

        _isHandlingBotTurn = false;

        // If Bot is STILL current player (Accompaniment rule or penalty draw satisfied), check again
        if (!updatedState.isGameOver &&
            updatedState.currentPlayer?.isBot == true) {
          _handleBotTurn();
        }
      } else {
        // Draw card
        var updatedState = GameLogic.drawCard(currentState, bot.id);
        ref.read(gameStateProvider.notifier).state = updatedState;

        _isHandlingBotTurn = false;

        // Check if next/still is bot
        if (!updatedState.isGameOver &&
            updatedState.currentPlayer?.isBot == true) {
          _handleBotTurn();
        }
      }
    } catch (e) {
      debugPrint('Error in bot turn: $e');
      _isHandlingBotTurn = false;
    }
  }

  /// Leave the current game
  void leaveGame() {
    ref.read(gameStateProvider.notifier).state = null;
    ref.read(currentPlayerIdProvider.notifier).state = null;
    ref.read(currentPlayerNameProvider.notifier).state = null;
  }

  /// Reset game state
  void resetGame() {
    ref.read(gameStateProvider.notifier).state = null;
  }
}
