import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_card.dart';
import '../models/memory_game_state.dart';

class MemoryNotifier extends StateNotifier<MemoryGameState> {
  MemoryNotifier() : super(MemoryGameState.initial());

  Timer? _timer;

  // List of icons to use for pairs
  static const List<IconData> _availableIcons = [
    Icons.pets,
    Icons.ac_unit,
    Icons.access_alarm,
    Icons.accessibility_new,
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.add_shopping_cart,
    Icons.airport_shuttle,
    Icons.all_inclusive,
    Icons.beach_access,
    Icons.cake,
    Icons.camera_alt,
    Icons.directions_bike,
    Icons.directions_boat,
    Icons.directions_bus,
    Icons.directions_car,
    Icons.emoji_events,
    Icons.emoji_food_beverage,
    Icons.emoji_nature,
    Icons.emoji_objects,
  ];

  void startGame({int gridSize = 16, bool multiplayer = false}) {
    // Ensure even number
    if (gridSize % 2 != 0) gridSize = 16;

    final int pairCount = gridSize ~/ 2;
    // Shuffle and pick icons
    final List<IconData> icons = List.from(_availableIcons)..shuffle();
    final List<IconData> selectedIcons = icons.take(pairCount).toList();

    // Create pairs (2 cards per icon)
    final List<MemoryCard> cards = [];
    final uuid = Uuid();

    for (var icon in selectedIcons) {
      cards.add(MemoryCard(id: uuid.v4(), icon: icon));
      cards.add(MemoryCard(id: uuid.v4(), icon: icon));
    }

    // Shuffle cards
    cards.shuffle();

    state = MemoryGameState(
      cards: cards,
      attempts: 0,
      isLocked: false,
      status: MemoryGameStatus.playing,
      isMultiplayer: multiplayer,
      currentPlayer: 0,
      playerScores: const [0, 0],
    );
  }

  void flipCard(String cardId) {
    if (state.isLocked || state.status != MemoryGameStatus.playing) return;

    final cardIndex = state.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = state.cards[cardIndex];
    if (card.isFlipped || card.isMatched) return;

    // Flip the card
    final newCards = List<MemoryCard>.from(state.cards);
    newCards[cardIndex] = card.copyWith(isFlipped: true);

    state = state.copyWith(cards: newCards);

    _checkForMatch();
  }

  void _checkForMatch() {
    final flippedCards = state.cards
        .where((c) => c.isFlipped && !c.isMatched)
        .toList();

    if (flippedCards.length == 2) {
      // Lock board to prevent 3rd flip
      state = state.copyWith(isLocked: true, attempts: state.attempts + 1);

      final card1 = flippedCards[0];
      final card2 = flippedCards[1];

      if (card1.icon == card2.icon) {
        // Match found
        final newCards = List<MemoryCard>.from(state.cards);

        // Mark both as matched
        for (var i = 0; i < newCards.length; i++) {
          if (newCards[i].id == card1.id || newCards[i].id == card2.id) {
            newCards[i] = newCards[i].copyWith(isMatched: true);
          }
        }

        if (state.isMultiplayer) {
          final newScores = List<int>.from(state.playerScores);
          newScores[state.currentPlayer] += 1;
          state = state.copyWith(
            cards: newCards,
            playerScores: newScores,
            isLocked: false,
          );
        } else {
          state = state.copyWith(cards: newCards, isLocked: false);
        }
        _checkWinCondition();
      } else {
        // No match - Wait and flip back
        _timer = Timer(const Duration(seconds: 1), () {
          if (!mounted) return;

          final newCards = List<MemoryCard>.from(state.cards);

          // Flip back
          for (var i = 0; i < newCards.length; i++) {
            if (newCards[i].id == card1.id || newCards[i].id == card2.id) {
              newCards[i] = newCards[i].copyWith(isFlipped: false);
            }
          }

          if (state.isMultiplayer) {
            state = state.copyWith(
              cards: newCards,
              isLocked: false,
              currentPlayer: (state.currentPlayer + 1) % 2,
            );
          } else {
            state = state.copyWith(cards: newCards, isLocked: false);
          }
        });
      }
    }
  }

  void _checkWinCondition() {
    final allMatched = state.cards.every((c) => c.isMatched);
    if (allMatched) {
      state = state.copyWith(status: MemoryGameStatus.won);
    }
  }

  void restartGame() {
    _timer?.cancel();
    startGame(gridSize: state.cards.length, multiplayer: state.isMultiplayer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final memoryProvider = StateNotifierProvider<MemoryNotifier, MemoryGameState>((
  ref,
) {
  return MemoryNotifier();
});
