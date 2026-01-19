import 'package:uuid/uuid.dart';
import '../models/card.dart';
import '../models/player.dart';
import '../models/game_state.dart';

/// Service handling all game logic and rules
class GameLogic {
  static const int cardsPerPlayer = 8;
  static const _uuid = Uuid();

  /// Initialize a complete deck of 52 cards + 2 Jokers
  static List<PlayingCard> initializeDeck() {
    final deck = <PlayingCard>[];

    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        if (rank == Rank.joker) continue;
        deck.add(PlayingCard(id: _uuid.v4(), suit: suit, rank: rank));
      }
    }

    // Add 2 Jokers
    deck.add(PlayingCard(id: _uuid.v4(), suit: Suit.hearts, rank: Rank.joker));
    deck.add(PlayingCard(id: _uuid.v4(), suit: Suit.spades, rank: Rank.joker));

    return deck;
  }

  /// Shuffle a deck of cards
  static List<PlayingCard> shuffleDeck(List<PlayingCard> deck) {
    final shuffled = List<PlayingCard>.from(deck);
    shuffled.shuffle();
    return shuffled;
  }

  /// Deal cards to players and return updated game state
  static GameState dealCards(GameState gameState) {
    final shuffledDeck = shuffleDeck(gameState.deck);
    final updatedPlayers = <Player>[];
    var deckIndex = 0;

    for (var player in gameState.players) {
      final hand = <PlayingCard>[];
      for (var i = 0; i < cardsPerPlayer; i++) {
        if (deckIndex < shuffledDeck.length) {
          hand.add(shuffledDeck[deckIndex]);
          deckIndex++;
        }
      }
      updatedPlayers.add(player.copyWith(hand: hand).sortHand());
    }

    final discardPile = <PlayingCard>[];
    if (deckIndex < shuffledDeck.length) {
      discardPile.add(shuffledDeck[deckIndex]);
      deckIndex++;
    }

    final remainingDeck = shuffledDeck.sublist(deckIndex);

    // Set starting player to the one AFTER the dealer (Host/Index 0)
    final numPlayers = updatedPlayers.length;
    final startingPlayerIndex = (gameState.currentPlayerIndex + 1) % numPlayers;

    // Update players so strict "isCurrentTurn" is correct
    final playersWithTurn = updatedPlayers.map((p) {
      return p.copyWith(isCurrentTurn: p.position == startingPlayerIndex);
    }).toList();

    final initialState = gameState.copyWith(
      players: playersWithTurn,
      deck: remainingDeck,
      discardPile: discardPile,
      status: GameStatus.playing,
      currentPlayerIndex: startingPlayerIndex,
    );

    // Apply effects of the first card (Start Card)
    return _applyStartCardEffects(initialState);
  }

  /// Apply effects based on the first card turned over (Start of Game)
  static GameState _applyStartCardEffects(GameState state) {
    if (state.discardPile.isEmpty) return state;

    final startCard = state.discardPile.last;
    final numPlayers = state.players.length;

    // Copy mutable structures
    var newState = state;
    final newPendingPenalties = Map<String, int>.from(state.pendingPenalties);
    bool directionChanged = false;
    int skipCount = 0;
    Suit? newSuit;
    PlayingCard? newActiveAttackCard;

    // Helper to get ID relative to CURRENT player (The First Player)
    String getIdAt(int offset) {
      final index = (state.currentPlayerIndex + offset) % numPlayers;
      // Handle negative wrap if needed (though addition usually safe)
      return state.players[index].id;
    }

    if (startCard.rank == Rank.ace) {
      // Ace: P1 draws 1 (or defends)
      addPenalty(newPendingPenalties, getIdAt(0), 1);
      newActiveAttackCard = startCard;
    } else if (startCard.rank == Rank.two) {
      newActiveAttackCard = startCard;
      if (startCard.suit == Suit.spades) {
        // 2 Spades: 4 (P1) -> 2 (P2) -> 1 (P3/P1)
        addPenalty(newPendingPenalties, getIdAt(0), 4);
        if (numPlayers > 1) {
          newState = newState.copyWith(nextCascadeLevels: [2, 1]);
        }
      } else {
        // 2 Normal: 2 (P1) -> 1 (P2/P1)
        addPenalty(newPendingPenalties, getIdAt(0), 2);
        if (numPlayers > 1) {
          newState = newState.copyWith(nextCascadeLevels: [1]);
        }
      }
    } else if (startCard.rank == Rank.eight) {
      // 8: Dealer (Host? or Arbitre) announces suit.
      // For MVP/Bot compatibility, we set it to the card's suit.
      newSuit = startCard.suit;
    } else if (startCard.rank == Rank.ten) {
      // 10: Reverse direction
      directionChanged = true;
      // Note: If direction reverses, does "First Player" change?
      // Rules: "Le 1er joueur commence... Sens s'inverse".
      // Usually P1 still starts, but play goes backwards.
    } else if (startCard.rank == Rank.jack) {
      // Jack: Skip
      if (startCard.suit == Suit.spades) {
        skipCount = 2; // Skip P1 and P2
      } else {
        skipCount = 1; // Skip P1
      }
    } else if (startCard.rank == Rank.joker) {
      // Joker: No penalty at start
    } else if (startCard.rank == Rank.seven) {
      // 7: P1 must play same suit.
      newState = newState.copyWith(mustMatchSuit: startCard.suit);
    }

    // Calculate final index if skipped
    // Note: direction changes affect "next" calculation in subsequent turns,
    // but skip computation here is effectively "How many steps to jump".

    int finalIndex = newState.currentPlayerIndex;
    if (skipCount > 0) {
      if (numPlayers == 2 && skipCount == 2) {
        // Special case: 1v1 Jack of Spades skips 1 player at start
        // per rule: "Exception à 2 joueurs : Le ♠J saute le 1er joueur, donc le 2e recommence"
        finalIndex = (finalIndex + 1) % 2;
      } else {
        finalIndex = (finalIndex + skipCount) % numPlayers;
      }
    }

    // Apply updates
    // Update players for turn
    final updatedPlayers = newState.players.map((p) {
      return p.copyWith(isCurrentTurn: p.position == finalIndex);
    }).toList();

    newState = newState.copyWith(
      pendingPenalties: newPendingPenalties,
      activeAttackCard: newActiveAttackCard,
      currentSuit: newSuit,
      isClockwise: directionChanged ? !state.isClockwise : state.isClockwise,
      mustMatchSuit: newState.mustMatchSuit,
      currentPlayerIndex: finalIndex,
      players: updatedPlayers,
    );

    // --- NEW: Force resolution of start penalties (Ace, 2, Joker) ---
    // User: "au début... ils ne peuvent ni bloquer... ni glisser ils ne peuvent que prendre la sanction"
    while (newState.pendingPenalties.isNotEmpty ||
        newState.nextCascadeLevels.isNotEmpty) {
      final targetId = newState.currentPlayer?.id;
      if (targetId == null) break;

      // Check if the current player has a penalty to take
      if (newState.getPenaltyFor(targetId) > 0) {
        newState = drawCard(newState, targetId);
      } else if (newState.nextCascadeLevels.isNotEmpty) {
        // This might happen if cascade didn't target anyone yet (not typical for start card logic, but safe)
        // In start effects, we added penalty to getIdAt(0) and cascade for later.
        // drawCard handles moving the cascade to the next player.
        // If current player has no penalty but cascade exists, we need to pass until someone takes it or it's resolved.
        // But normally drawCard(penalty) triggers cascade.
        // If we get here, it means we are in a state where a cascade is pending but no active penalty is on the current player yet.
        // This shouldn't happen with current _applyStartCardEffects logic, but if it does, we stop to avoid infinite loop.
        break;
      } else {
        break;
      }
    }

    return newState;
  }

  /// Check if a move is valid
  static bool isValidMove(
    PlayingCard cardToPlay,
    PlayingCard topCard,
    Suit? currentSuit, {
    int? penalty,
    PlayingCard? activeAttackCard,
    Suit? mustMatchSuit,
    bool lastTurnWasForcedDraw = false,
    List<PlayingCard>? playerHand,
  }) {
    // 1. If under penalty, MUST Defend/Block OR Draw
    // This check MUST come first to prevent other rules (like 7 suit restriction) from allowing invalid moves.
    if (penalty != null && penalty > 0) {
      // 2♠ Rule: Can only be blocked by another 2♠ or Joker (Transfer)
      if (activeAttackCard?.rank == Rank.two &&
          activeAttackCard?.suit == Suit.spades) {
        if (cardToPlay.rank == Rank.joker ||
            (cardToPlay.rank == Rank.two && cardToPlay.suit == Suit.spades)) {
          return true;
        }
        return false;
      }

      // Ace Rule: Can ONLY be blocked by another Ace, an 8, or Joker (Transfer)
      if (activeAttackCard?.rank == Rank.ace) {
        if (cardToPlay.rank == Rank.ace ||
            cardToPlay.rank == Rank.eight ||
            cardToPlay.rank == Rank.joker) {
          return true;
        }
        return false;
      }

      // Normal Defense: 2 Normal or Joker or 8
      if (cardToPlay.rank == Rank.eight || cardToPlay.rank == Rank.joker) {
        return true;
      }

      // If we are here, activeAttackCard is likely a 2 normal (or null with penalty)
      if (cardToPlay.rank == Rank.two && activeAttackCard?.rank != Rank.ace) {
        return true;
      }

      return false; // Cannot play standard cards (like 7) or mismatched defense
    }

    // 2. 7 - Single Suit Restriction (Companion card)
    if (mustMatchSuit != null) {
      // You can only play a card of the exact same suit
      // OR another 7 (which overrides restriction)
      // OR a Joker (transfer/universal)
      // OR an 8 (Universal Blocker/Suit Change)
      if (cardToPlay.rank == Rank.joker ||
          cardToPlay.rank == Rank.eight ||
          cardToPlay.rank == Rank.seven ||
          cardToPlay.suit == mustMatchSuit) {
        return true;
      }
      return false;
    }

    // Joker always playable
    if (cardToPlay.rank == Rank.joker) return true;

    // Aces and 2s must match suit or rank (unless defending, handled above)

    // --- ANTI-CARD CHANGE RULE ---
    // If the previous turn was a forced draw (Ace, 2, Joker penalty taken),
    // the next player cannot play an 8 to "help" if they have a standard legal move.
    if (lastTurnWasForcedDraw &&
        cardToPlay.rank == Rank.eight &&
        playerHand != null) {
      final effectiveSuit = currentSuit ?? topCard.suit;
      bool hasLegalStandardMove = playerHand.any((c) {
        if (c.id == cardToPlay.id) return false; // Ignore current card
        // Check if we have a card of the same suit or same rank
        return c.suit == effectiveSuit || c.rank == topCard.rank;
      });

      if (hasLegalStandardMove) {
        return false; // Forbidden: "Il ne peut PAS changer la couleur si ce n'est pas légitime"
      }
    }

    return cardToPlay.canPlayOn(topCard, currentSuit: currentSuit);
  }

  /// Apply a card play to the game state
  static GameState playCard(
    GameState gameState,
    String playerId,
    PlayingCard card, {
    Suit? chosenSuit,
  }) {
    final playerIndex = gameState.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) return gameState;

    final player = gameState.players[playerIndex];
    if (!player.hasCard(card)) return gameState;

    // Verify it's the player's turn
    if (playerIndex != gameState.currentPlayerIndex) {
      return gameState;
    }

    final myPenalty = gameState.getPenaltyFor(playerId);
    final topCard = gameState.topCard;

    if (topCard != null &&
        !isValidMove(
          card,
          topCard,
          gameState.currentSuit,
          penalty: myPenalty,
          activeAttackCard: gameState.activeAttackCard,
          mustMatchSuit: gameState.mustMatchSuit,
          lastTurnWasForcedDraw: gameState.lastTurnWasForcedDraw,
          playerHand: player.hand,
        )) {
      return gameState;
    }

    // Remove card and update discard
    final updatedPlayer = player.removeCard(card);
    final updatedPlayers = List<Player>.from(gameState.players);
    updatedPlayers[playerIndex] = updatedPlayer;

    // --- EFFECT LOGIC ---
    Suit? newCurrentSuit;
    bool clearSuit = false;
    bool toggleDirection = false;

    // Accompaniment States
    int pendingSkips = gameState.remainingSkips;
    Suit? pendingMatchSuit = gameState.mustMatchSuit;
    bool turnPasses = true;

    Map<String, int> newPendingPenalties = Map.from(gameState.pendingPenalties);
    PlayingCard? newActiveAttackCard = gameState.activeAttackCard;
    List<int> pendingCascade = List.from(gameState.nextCascadeLevels);

    bool isDefense = myPenalty > 0;

    // Determine Discard Pile Update (Handle Joker Glide)
    List<PlayingCard> updatedDiscardPile;
    if (card.rank == Rank.joker && gameState.discardPile.isNotEmpty) {
      // Joker Glide: Insert Joker UNDER the top card so the Attack Card remains visible/active
      // Applies to both Defense and Neutral play
      updatedDiscardPile = [
        ...gameState.discardPile.sublist(0, gameState.discardPile.length - 1),
        card,
        gameState.discardPile.last,
      ];
    } else {
      // Standard Play: Add to top
      updatedDiscardPile = [...gameState.discardPile, card];
    }

    // Helper for circular target calculation
    int direction = gameState.isClockwise ? 1 : -1;
    int numPlayers = gameState.players.length;
    String getIdAt(int offset) {
      int idx = (playerIndex + (offset * direction)) % numPlayers;
      if (idx < 0) idx += numPlayers;
      return gameState.players[idx].id;
    }

    // Defense Resolution & Clearing
    // Defense Resolution & Clearing
    if (isDefense) {
      if (card.rank == Rank.joker) {
        // Joker Transfer (Glide)
        // Restored Transfer logic per user request
        int penaltyAmount = newPendingPenalties.remove(playerId) ?? 0;
        addPenalty(newPendingPenalties, getIdAt(1), penaltyAmount);
        // newActiveAttackCard remains unchanged (e.g. 2 Spades)
      } else if (card.rank == Rank.two ||
          card.rank == Rank.eight ||
          card.rank == Rank.ace) {
        if (card.rank == Rank.ace && newActiveAttackCard?.rank == Rank.ace) {
          // Ace on Ace -> Cancel Total
          newPendingPenalties.clear();
          newActiveAttackCard = null;
          pendingCascade.clear();
          // Turn passes normally (Standard rule refined)
        } else if (card.rank == Rank.eight &&
            newActiveAttackCard?.rank == Rank.ace) {
          // 8 on Ace -> Cancel + Change Suit (handled later)
          newPendingPenalties.clear();
          newActiveAttackCard = null;
          pendingCascade.clear();
        } else if (card.rank == Rank.two &&
            newActiveAttackCard?.rank == Rank.two) {
          // 2 on 2 -> Cancel + Forced Accompaniment
          newPendingPenalties.clear();
          newActiveAttackCard = null;
          pendingCascade.clear();
          turnPasses =
              false; // Rule: "Après le blocage, vous devez jouer soit..."
          pendingMatchSuit = card.suit;
        } else if (card.rank == Rank.eight &&
            newActiveAttackCard?.rank == Rank.two) {
          // 8 on 2 -> Cancel
          newPendingPenalties.clear();
          newActiveAttackCard = null;
          pendingCascade.clear();
        }
      }
    }

    // Suit Satisfaction Logic:
    // If an 8 called a suit, and we play a matching non-8/non-Joker card, clear the override.
    if (gameState.currentSuit != null &&
        card.rank != Rank.eight &&
        card.rank != Rank.joker &&
        card.suit == gameState.currentSuit) {
      clearSuit = true;
    }

    // If we were in a restricted mode, normal cards clear it?
    // Rules: "Accompagnez-le immédiatement d'une autre carte... n'importe laquelle, ou même couleur".
    // 7: Must match suit. If I play 7, I stay.
    // If I play matching non-7, I pass.
    // If I play 7, I stay (and restriction updates).
    // Basically: 7 & Jack -> Turn STAYS. Everything else -> Turn PASSES.

    if (card.rank == Rank.seven) {
      turnPasses = false;
      // Constraint for NEXT card
      pendingMatchSuit = card.suit;
    }

    if (card.rank == Rank.jack) {
      clearSuit = true;

      // Jack Rules:
      // Normal Jack: skips 1 player
      // Jack Spades: skips 2 players

      if (card.suit == Suit.spades) {
        pendingSkips += 2;
        // Exception: In 1v1, Jack of Spades does NOT require accompaniment
        if (numPlayers == 2) {
          turnPasses = true;
        } else {
          turnPasses = false;
        }
      } else {
        pendingSkips += 1;
        turnPasses = false;
      }

      pendingMatchSuit = null;
    }

    // Normal Card behavior (terminates chain)
    if (card.rank != Rank.seven && card.rank != Rank.jack && turnPasses) {
      // If I played a normal card, I am done.
      // Clear any restriction only if turn is passing.
      pendingMatchSuit = null;
    }

    // Effects for other cards (8, 10, Ace, 2, Joker)
    // Only apply if not defending (or if effect applies anyway)

    // Note: If I played 7 on 7, I didn't defend (7 isn't defense).
    // If I played 8 to defend +2?
    // Rules say 8 blocks 2.
    // 8 always changes suit -> turn passes.

    bool appliesEffect = !isDefense;
    bool startsNewPenalty = card.rank == Rank.two || card.rank == Rank.ace;

    if (card.rank == Rank.eight) {
      newCurrentSuit = chosenSuit ?? card.suit;
    } else if (appliesEffect || startsNewPenalty) {
      if (card.rank == Rank.two) {
        clearSuit = true;
        // Defensive 2s don't start new penalties themselves (accompaniment does)
        if (!isDefense) {
          newActiveAttackCard = card;
          if (card.suit == Suit.spades) {
            // 4 -> 2 -> 1
            addPenalty(newPendingPenalties, getIdAt(1), 4);
            if (numPlayers > 1) {
              pendingCascade = [2, 1];
            }
          } else {
            // 2 -> 1
            addPenalty(newPendingPenalties, getIdAt(1), 2);
            if (numPlayers > 1) {
              pendingCascade = [1];
            }
          }
        }
      } else if (card.rank == Rank.joker) {
        // Neutral Joker Rule: Just slides. No penalty.
      } else if (card.rank == Rank.ace) {
        clearSuit = true;
        // Defensive Aces don't start new penalties themselves (accompaniment does)
        if (!isDefense) {
          newActiveAttackCard = card;
          addPenalty(newPendingPenalties, getIdAt(1), 1);
        }
      }
    }

    if (card.rank == Rank.ten) {
      toggleDirection = true;
      clearSuit = true;
    }

    String? winnerId;
    GameStatus status = gameState.status;
    if (updatedPlayer.hasWon) {
      winnerId = playerId;
      status = GameStatus.finished;
    }

    var newState = gameState.copyWith(
      players: updatedPlayers,
      discardPile: updatedDiscardPile,
      currentSuit: newCurrentSuit,
      clearCurrentSuit: clearSuit,
      winnerId: winnerId,
      status: status,
      pendingPenalties: newPendingPenalties,
      activeAttackCard: newActiveAttackCard,
      clearActiveAttack:
          newActiveAttackCard == null && newPendingPenalties.isEmpty,
      isClockwise: toggleDirection
          ? !gameState.isClockwise
          : gameState.isClockwise,
      mustMatchSuit: pendingMatchSuit,
      clearMustMatchSuit: pendingMatchSuit == null,
      remainingSkips: pendingSkips,
      nextCascadeLevels: pendingCascade,
      lastTurnWasForcedDraw: false, // Reset flag on play
    );

    if (!newState.isGameOver && turnPasses) {
      // Move to next player
      newState = newState.nextPlayer();

      // Apply accumulated Skips
      for (int i = 0; i < pendingSkips; i++) {
        newState = newState.nextPlayer();
      }

      // Reset skips after applying
      newState = newState.copyWith(remainingSkips: 0);
    }

    return newState;
  }

  static void addPenalty(Map<String, int> map, String pid, int amount) {
    map[pid] = (map[pid] ?? 0) + amount;
  }

  /// Draw a card from the deck
  static GameState drawCard(GameState gameState, String playerId) {
    int penalty = gameState.getPenaltyFor(playerId);
    int cardsToDrawCount = penalty > 0 ? penalty : 1;

    if (gameState.deck.length < cardsToDrawCount) {
      if (gameState.discardPile.length > 1) {
        final topCard = gameState.discardPile.last;
        final cardsToShuffle = gameState.discardPile.sublist(
          0,
          gameState.discardPile.length - 1,
        );
        final newDeck = shuffleDeck(cardsToShuffle);
        gameState = gameState.copyWith(deck: newDeck, discardPile: [topCard]);
      } else {
        cardsToDrawCount = gameState.deck.length; // Draw what's left
      }
    }

    var currentDeck = gameState.deck;
    final drawnCards = <PlayingCard>[];
    for (var i = 0; i < cardsToDrawCount; i++) {
      if (currentDeck.isNotEmpty) {
        drawnCards.add(currentDeck.first);
        currentDeck = currentDeck.sublist(1);
      }
    }

    final playerIndex = gameState.players.indexWhere((p) => p.id == playerId);
    final player = gameState.players[playerIndex];
    var updatedPlayer = player;
    for (final card in drawnCards) {
      updatedPlayer = updatedPlayer.addCard(card);
    }
    updatedPlayer = updatedPlayer.sortHand();

    final updatedPlayers = List<Player>.from(gameState.players);
    updatedPlayers[playerIndex] = updatedPlayer;

    Map<String, int> newPendingPenalties = Map.from(gameState.pendingPenalties);
    List<int> updatedCascade = List<int>.from(gameState.nextCascadeLevels);
    bool shouldPassTurn = penalty == 0;

    if (penalty > 0) {
      newPendingPenalties.remove(playerId);

      if (updatedCascade.isNotEmpty) {
        // Cascade triggered: next player gets next amount
        final nextLevel = updatedCascade.removeAt(0);
        int direction = gameState.isClockwise ? 1 : -1;
        int nextTargetIdx =
            (playerIndex + direction) % gameState.players.length;
        if (nextTargetIdx < 0) nextTargetIdx += gameState.players.length;
        final targetId = gameState.players[nextTargetIdx].id;

        newPendingPenalties[targetId] =
            (newPendingPenalties[targetId] ?? 0) + nextLevel;
        shouldPassTurn = true;
      } else {
        // Just a normal penalty (Ace/Joker) or end of cascade
        // Rule: After penalty draw, turn passes to the next player.
        shouldPassTurn = true;
      }
    }

    var newState = gameState.copyWith(
      players: updatedPlayers,
      deck: currentDeck,
      pendingPenalties: newPendingPenalties,
      nextCascadeLevels: updatedCascade,
      clearActiveAttack: newPendingPenalties.isEmpty && updatedCascade.isEmpty,
      clearMustMatchSuit: true,
      lastTurnWasForcedDraw: penalty > 0,
    );

    var finalState = newState;
    if (shouldPassTurn) {
      finalState = finalState.nextPlayer();
    }

    // Apply accumulated Skips (from Jacks)
    if (newState.remainingSkips > 0) {
      for (int i = 0; i < newState.remainingSkips; i++) {
        finalState = finalState.nextPlayer();
      }
      finalState = finalState.copyWith(remainingSkips: 0);
    }

    return finalState;
  }

  /// Check if current player must draw (has no playable cards)
  static bool mustDraw(GameState gameState) {
    final currentPlayer = gameState.currentPlayer;
    final topCard = gameState.topCard;
    if (currentPlayer == null || topCard == null) return false;

    return !currentPlayer.hand.any(
      (c) => isValidMove(
        c,
        topCard,
        gameState.currentSuit,
        penalty: gameState.getPenaltyFor(currentPlayer.id),
        activeAttackCard: gameState.activeAttackCard,
        mustMatchSuit: gameState.mustMatchSuit,
      ),
    );
  }

  /// Create a new game
  static GameState createGame(String gameId, String hostId, String hostName) {
    final host = Player(
      id: hostId,
      name: hostName,
      hand: [],
      position: 0,
      isCurrentTurn: true,
    );
    return GameState(
      gameId: gameId,
      players: [host],
      deck: initializeDeck(),
      discardPile: [],
      hostId: hostId,
      status: GameStatus.waiting,
    );
  }

  static GameState addPlayer(
    GameState gameState,
    String playerId,
    String playerName, {
    bool isBot = false,
  }) {
    if (gameState.status != GameStatus.waiting) return gameState;
    final newPlayer = Player(
      id: playerId,
      name: playerName,
      hand: [],
      position: gameState.players.length,
      isBot: isBot,
    );
    return gameState.copyWith(players: [...gameState.players, newPlayer]);
  }

  /// @visibleForTesting
  static GameState applyStartCardEffectsForTest(GameState state) {
    return _applyStartCardEffects(state);
  }
}
