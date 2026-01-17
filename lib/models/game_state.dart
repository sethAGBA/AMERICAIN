import 'package:equatable/equatable.dart';
import 'card.dart';
import 'player.dart';

/// Enum representing the current game status
enum GameStatus {
  waiting, // Waiting for players to join
  playing, // Game in progress
  finished, // Game completed
}

/// GameState model representing the complete state of a game
class GameState extends Equatable {
  final String gameId;
  final List<Player> players;
  final List<PlayingCard> deck;
  final List<PlayingCard> discardPile;
  final int currentPlayerIndex;
  final Suit? currentSuit; // Override suit when an 8 is played
  final GameStatus status;
  final String? winnerId;
  final String hostId; // Player who created the game
  final Map<String, int>
  pendingPenalties; // Penalties for specific players (PlayerID -> Count)
  final PlayingCard?
  activeAttackCard; // The card causing the current penalty chain (for defense rules)
  final bool isClockwise; // Direction of play
  // Accompaniment Fields
  final Suit? mustMatchSuit; // For 7 rule (must play same suit)
  final int remainingSkips; // Accumulated skips from Jacks
  final bool lastTurnWasForcedDraw; // Flag for Anti-Card Change Rule
  final List<int>
  nextCascadeLevels; // Remaining penalties in a sequence (e.g. [2, 1])

  const GameState({
    required this.gameId,
    required this.players,
    required this.deck,
    required this.discardPile,
    this.currentPlayerIndex = 0,
    this.currentSuit,
    this.status = GameStatus.waiting,
    this.winnerId,
    required this.hostId,
    this.pendingPenalties = const {},
    this.activeAttackCard,
    this.isClockwise = true,
    this.mustMatchSuit,
    this.remainingSkips = 0,
    this.lastTurnWasForcedDraw = false,
    this.nextCascadeLevels = const [],
  });

  /// Get the current player
  Player? get currentPlayer {
    if (players.isEmpty || currentPlayerIndex >= players.length) {
      return null;
    }
    return players[currentPlayerIndex];
  }

  /// Get penalty for a specific player
  int getPenaltyFor(String playerId) => pendingPenalties[playerId] ?? 0;

  /// Get the top card of the discard pile
  PlayingCard? get topCard {
    return discardPile.isEmpty ? null : discardPile.last;
  }

  /// Move to the next player's turn
  GameState nextPlayer() {
    // Calculate next index based on direction
    final direction = isClockwise ? 1 : -1;
    var nextIndex = (currentPlayerIndex + direction) % players.length;
    // Handle negative modulo in Dart
    if (nextIndex < 0) nextIndex += players.length;

    final updatedPlayers = players.map((player) {
      return player.copyWith(isCurrentTurn: player.position == nextIndex);
    }).toList();

    return copyWith(currentPlayerIndex: nextIndex, players: updatedPlayers);
  }

  /// Check if the game is over
  bool get isGameOver {
    return status == GameStatus.finished ||
        players.any((player) => player.hasWon);
  }

  /// Get the winner if game is over
  Player? get winner {
    if (winnerId != null) {
      return players.firstWhere((p) => p.id == winnerId);
    }
    try {
      return players.firstWhere((player) => player.hasWon);
    } catch (e) {
      return null;
    }
  }

  /// Create a copy with updated fields
  GameState copyWith({
    String? gameId,
    List<Player>? players,
    List<PlayingCard>? deck,
    List<PlayingCard>? discardPile,
    int? currentPlayerIndex,
    Suit? currentSuit,
    bool clearCurrentSuit = false,
    GameStatus? status,
    String? winnerId,
    String? hostId,
    Map<String, int>? pendingPenalties,
    PlayingCard? activeAttackCard,
    bool clearActiveAttack = false,
    bool? isClockwise,
    Suit? mustMatchSuit,
    bool clearMustMatchSuit = false,
    int? remainingSkips,
    bool? lastTurnWasForcedDraw,
    List<int>? nextCascadeLevels,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentSuit: clearCurrentSuit ? null : (currentSuit ?? this.currentSuit),
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      hostId: hostId ?? this.hostId,
      pendingPenalties: pendingPenalties ?? this.pendingPenalties,
      activeAttackCard: clearActiveAttack
          ? null
          : (activeAttackCard ?? this.activeAttackCard),
      isClockwise: isClockwise ?? this.isClockwise,
      mustMatchSuit: clearMustMatchSuit
          ? null
          : (mustMatchSuit ?? this.mustMatchSuit),
      remainingSkips: remainingSkips ?? this.remainingSkips,
      lastTurnWasForcedDraw:
          lastTurnWasForcedDraw ?? this.lastTurnWasForcedDraw,
      nextCascadeLevels: nextCascadeLevels ?? this.nextCascadeLevels,
    );
  }

  /// Convert to JSON for network transfer
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'players': players.map((p) => p.toJson()).toList(),
      'deck': deck.map((c) => c.toJson()).toList(),
      'discardPile': discardPile.map((c) => c.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'currentSuit': currentSuit?.name,
      'status': status.name,
      'winnerId': winnerId,
      'hostId': hostId,
      'pendingPenalties': pendingPenalties,
      'activeAttackCard': activeAttackCard?.toJson(),
      'isClockwise': isClockwise,
      'mustMatchSuit': mustMatchSuit?.name,
      'remainingSkips': remainingSkips,
      'lastTurnWasForcedDraw': lastTurnWasForcedDraw,
      'nextCascadeLevels': nextCascadeLevels,
    };
  }

  /// Create from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      gameId: json['gameId'] as String,
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      deck: (json['deck'] as List).map((c) => PlayingCard.fromJson(c)).toList(),
      discardPile: (json['discardPile'] as List)
          .map((c) => PlayingCard.fromJson(c))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex'] as int? ?? 0,
      currentSuit: json['currentSuit'] != null
          ? Suit.values.firstWhere((s) => s.name == json['currentSuit'])
          : null,
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.waiting,
      ),
      winnerId: json['winnerId'] as String?,
      hostId: json['hostId'] as String,
      pendingPenalties:
          (json['pendingPenalties'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      activeAttackCard: json['activeAttackCard'] != null
          ? PlayingCard.fromJson(json['activeAttackCard'])
          : null,
      isClockwise: json['isClockwise'] as bool? ?? true,
      mustMatchSuit: json['mustMatchSuit'] != null
          ? Suit.values.firstWhere((s) => s.name == json['mustMatchSuit'])
          : null,
      remainingSkips: json['remainingSkips'] as int? ?? 0,
      lastTurnWasForcedDraw: json['lastTurnWasForcedDraw'] as bool? ?? false,
      nextCascadeLevels:
          (json['nextCascadeLevels'] as List?)?.map((e) => e as int).toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
    gameId,
    players,
    deck,
    discardPile,
    currentPlayerIndex,
    currentSuit,
    status,
    winnerId,
    hostId,
    pendingPenalties,
    activeAttackCard,
    isClockwise,
    mustMatchSuit,
    remainingSkips,
    lastTurnWasForcedDraw,
    nextCascadeLevels,
  ];
}
