import 'package:equatable/equatable.dart';
import 'card.dart';

/// Player model representing a game player
class Player extends Equatable {
  final String id;
  final String name;
  final List<PlayingCard> hand;
  final bool isCurrentTurn;
  final bool isBot;
  final int position; // Position at the table (0-3 for 4 players)

  const Player({
    required this.id,
    required this.name,
    required this.hand,
    this.isCurrentTurn = false,
    this.isBot = false,
    this.position = 0,
  });

  /// Add a card to the player's hand
  Player addCard(PlayingCard card) {
    return copyWith(hand: [...hand, card]);
  }

  /// Remove a card from the player's hand
  Player removeCard(PlayingCard card) {
    return copyWith(hand: hand.where((c) => c.id != card.id).toList());
  }

  /// Check if player has a specific card
  bool hasCard(PlayingCard card) {
    return hand.any((c) => c.id == card.id);
  }

  /// Check if player has any playable cards
  bool hasPlayableCard(PlayingCard topCard, {Suit? currentSuit}) {
    return hand.any(
      (card) => card.canPlayOn(topCard, currentSuit: currentSuit),
    );
  }

  /// Get number of cards in hand
  int get cardCount => hand.length;

  /// Check if player has won (no cards left)
  bool get hasWon => hand.isEmpty;

  /// Get total points in hand
  int get handPoints => hand.fold(0, (sum, card) => sum + card.points);

  /// Sort hand by suit and rank
  Player sortHand() {
    final sortedHand = List<PlayingCard>.from(hand);
    sortedHand.sort((a, b) {
      // Sort by suit first
      final suitComparison = a.suit.index.compareTo(b.suit.index);
      if (suitComparison != 0) return suitComparison;
      // Then by rank (descending for easier play?) or ascending
      // Let's do ascending for now
      return a.rank.index.compareTo(b.rank.index);
    });
    return copyWith(hand: sortedHand);
  }

  /// Create a copy with updated fields
  Player copyWith({
    String? id,
    String? name,
    List<PlayingCard>? hand,
    bool? isCurrentTurn,
    bool? isBot,
    int? position,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      isCurrentTurn: isCurrentTurn ?? this.isCurrentTurn,
      isBot: isBot ?? this.isBot,
      position: position ?? this.position,
    );
  }

  /// Convert to JSON for network transfer
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hand': hand.map((card) => card.toJson()).toList(),
      'isCurrentTurn': isCurrentTurn,
      'isBot': isBot,
      'position': position,
    };
  }

  /// Create from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      hand: (json['hand'] as List)
          .map((cardJson) => PlayingCard.fromJson(cardJson))
          .toList(),
      isCurrentTurn: json['isCurrentTurn'] as bool? ?? false,
      isBot: json['isBot'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, hand, isCurrentTurn, isBot, position];

  @override
  String toString() => 'Player($name, ${hand.length} cards, bot: $isBot)';
}
