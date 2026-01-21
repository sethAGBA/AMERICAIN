import 'package:equatable/equatable.dart';
import '../../models/card.dart';

class SolitaireCard extends Equatable {
  final PlayingCard card;
  final bool isFaceUp;

  const SolitaireCard({required this.card, this.isFaceUp = false});

  /// Creates a copy of this SolitaireCard with the given fields replaced with the new values.
  SolitaireCard copyWith({PlayingCard? card, bool? isFaceUp}) {
    return SolitaireCard(
      card: card ?? this.card,
      isFaceUp: isFaceUp ?? this.isFaceUp,
    );
  }

  /// Flip the card
  SolitaireCard flip() {
    return copyWith(isFaceUp: !isFaceUp);
  }

  /// Force face up
  SolitaireCard get faceUp => copyWith(isFaceUp: true);

  /// Force face down
  SolitaireCard get faceDown => copyWith(isFaceUp: false);

  @override
  List<Object?> get props => [card, isFaceUp];

  @override
  String toString() => '${card.toString()}(${isFaceUp ? 'UP' : 'DOWN'})';
}
