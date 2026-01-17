import 'package:equatable/equatable.dart';

/// Enum representing card suits
enum Suit {
  hearts,
  diamonds,
  clubs,
  spades;

  String get symbol {
    switch (this) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  String get label {
    switch (this) {
      case Suit.hearts:
        return 'Cœur';
      case Suit.diamonds:
        return 'Carreau';
      case Suit.clubs:
        return 'Trèfle';
      case Suit.spades:
        return 'Pique';
    }
  }

  String get color {
    return this == Suit.hearts || this == Suit.diamonds ? 'red' : 'black';
  }
}

/// Enum representing card ranks
enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight, // Special card in AMERICAIN
  nine,
  ten,
  jack,
  queen,
  king,
  joker;

  String get displayValue {
    switch (this) {
      case Rank.ace:
        return 'A';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'R';
      case Rank.joker:
        return '🃏';
      default:
        return (index + 1).toString();
    }
  }

  int get value => index + 1;
}

/// Card model representing a playing card
class PlayingCard extends Equatable {
  final String id;
  final Suit suit;
  final Rank rank;

  const PlayingCard({required this.id, required this.suit, required this.rank});

  /// Check if this is a wild card (8 or Joker)
  bool get isSpecial => rank == Rank.eight || rank == Rank.joker;

  /// Get point value of this card
  int get points {
    switch (rank) {
      case Rank.ace:
        return 1;
      case Rank.eight:
        return 64;
      case Rank.joker:
        return 50;
      case Rank.ten:
        return 10;
      case Rank.jack:
        return suit == Suit.spades ? 22 : 11;
      case Rank.two:
        return suit == Suit.spades ? 4 : 2;
      case Rank.seven:
        return 7;
      case Rank.king:
      case Rank.queen:
        return 1;
      default:
        return rank.value; // Rank.value is index + 1
    }
  }

  /// Check if this card can be played on another card
  bool canPlayOn(PlayingCard other, {Suit? currentSuit}) {
    // If there's a current suit override (from a previous 8), check against that
    final effectiveSuit = currentSuit ?? other.suit;

    // Can play if same suit or same rank
    return suit == effectiveSuit || rank == other.rank || isSpecial;
  }

  /// Convert to JSON for network transfer
  Map<String, dynamic> toJson() {
    return {'id': id, 'suit': suit.name, 'rank': rank.name};
  }

  /// Create from JSON
  factory PlayingCard.fromJson(Map<String, dynamic> json) {
    return PlayingCard(
      id: json['id'] as String,
      suit: Suit.values.firstWhere((s) => s.name == json['suit']),
      rank: Rank.values.firstWhere((r) => r.name == json['rank']),
    );
  }

  @override
  List<Object?> get props => [id, suit, rank];

  @override
  String toString() => '${rank.displayValue}${suit.symbol}';
}
