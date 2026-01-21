import 'package:equatable/equatable.dart';
import '../../models/card.dart';
import 'solitaire_card.dart';

class SolitaireState extends Equatable {
  final List<PlayingCard>
  stock; // PlayingCards as they are always face-down in stock until drawn
  final List<PlayingCard> waste; // PlayingCards, always face-up
  final Map<Suit, List<PlayingCard>> foundation; // 4 piles by suit
  final List<List<SolitaireCard>> tableau; // 7 columns
  final int score;
  final int moves;
  final bool isWon;

  const SolitaireState({
    required this.stock,
    required this.waste,
    required this.foundation,
    required this.tableau,
    this.score = 0,
    this.moves = 0,
    this.isWon = false,
  });

  factory SolitaireState.initial() {
    return const SolitaireState(
      stock: [],
      waste: [],
      foundation: {
        Suit.hearts: [],
        Suit.diamonds: [],
        Suit.clubs: [],
        Suit.spades: [],
      },
      tableau: [],
    );
  }

  SolitaireState copyWith({
    List<PlayingCard>? stock,
    List<PlayingCard>? waste,
    Map<Suit, List<PlayingCard>>? foundation,
    List<List<SolitaireCard>>? tableau,
    int? score,
    int? moves,
    bool? isWon,
  }) {
    return SolitaireState(
      stock: stock ?? this.stock,
      waste: waste ?? this.waste,
      foundation: foundation ?? this.foundation,
      tableau: tableau ?? this.tableau,
      score: score ?? this.score,
      moves: moves ?? this.moves,
      isWon: isWon ?? this.isWon,
    );
  }

  @override
  List<Object?> get props => [
    stock,
    waste,
    foundation,
    tableau,
    score,
    moves,
    isWon,
  ];
}
