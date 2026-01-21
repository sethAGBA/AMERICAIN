import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card.dart';
import '../models/solitaire_card.dart';
import '../models/solitaire_state.dart';

final solitaireProvider =
    StateNotifierProvider<SolitaireNotifier, SolitaireState>((ref) {
      return SolitaireNotifier();
    });

class SolitaireNotifier extends StateNotifier<SolitaireState> {
  SolitaireNotifier() : super(SolitaireState.initial());

  void initGame() {
    // Create full deck
    List<PlayingCard> deck = [];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        if (rank != Rank.eight && rank != Rank.joker) {
          // Exclude special cards if needed, but standard 52 is Ace->King
          // Wait, Rank enum has 8? "eight" is special in Americain, but exists in standard deck.
          // Solitaire uses standard 52. Ace,2..10,J,Q,K.
          // Checking Rank enum: ace, two..eight..king, joker.
          // We just exclude Joker. 8 is a normal card in Solitaire.
          if (rank != Rank.joker) {
            deck.add(
              PlayingCard(
                id: '${rank.name}_${suit.name}',
                suit: suit,
                rank: rank,
              ),
            );
          }
        }
      }
    }

    deck.shuffle();

    // Deal Tableau
    // col 0: 1 card
    // col 1: 2 cards
    // ...
    // col 6: 7 cards
    // Last card of each col is face up.

    List<List<SolitaireCard>> tableau = List.generate(7, (_) => []);
    int cardIndex = 0;

    for (int i = 0; i < 7; i++) {
      for (int j = 0; j <= i; j++) {
        final card = deck[cardIndex++];
        final isTop = j == i;
        tableau[i].add(SolitaireCard(card: card, isFaceUp: isTop));
      }
    }

    // Remaining to Stock
    List<PlayingCard> stock = [];
    while (cardIndex < deck.length) {
      stock.add(deck[cardIndex++]);
    }

    state = SolitaireState(
      stock: stock,
      waste: [],
      foundation: {
        Suit.hearts: [],
        Suit.diamonds: [],
        Suit.clubs: [],
        Suit.spades: [],
      },
      tableau: tableau,
    );
  }

  // Stock -> Waste
  void drawCard() {
    if (state.stock.isEmpty) {
      // Recycle waste to stock
      if (state.waste.isEmpty) return;

      final newStock = List<PlayingCard>.from(state.waste.reversed);
      state = state.copyWith(stock: newStock, waste: []);
    } else {
      // Draw 1
      final card = state.stock.last;
      final newStock = List<PlayingCard>.from(state.stock)..removeLast();
      final newWaste = List<PlayingCard>.from(state.waste)..add(card);

      state = state.copyWith(stock: newStock, waste: newWaste);
    }
  }

  // Attempt to auto-move card to foundation (Foundation auto-stack)
  void tryAutoMoveToFoundation(PlayingCard card) {
    // Logic to check if this card can go to its suit foundation
    // Not strictly necessary for MVP but good UX.
    // We'll implement drag & drop mainly first.
  }

  bool canMoveToFoundation(PlayingCard card) {
    final pile = state.foundation[card.suit]!;
    if (pile.isEmpty) {
      return card.rank == Rank.ace;
    }
    final top = pile.last;
    return top.rank.index + 1 == card.rank.index;
    // Ace is 0 in index? Let's check Rank enum.
    // Rank: ace, two...
    // Yes, Ace index 0. Two index 1.
    // So if top is Ace (0), we need Two (1). 0+1 == 1. Correct.
  }

  bool canMoveToTableau(PlayingCard card, SolitaireCard? targetTop) {
    if (targetTop == null) {
      // Empty column accepts King
      return card.rank == Rank.king;
    }

    // Must be alternating color
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final targetIsRed =
        targetTop.card.suit == Suit.hearts ||
        targetTop.card.suit == Suit.diamonds;

    if (isRed == targetIsRed) return false;

    // Must be descending rank (e.g. 9 on 10)
    // Rank enum: ... nine(index 8), ten(index 9).
    // So target (10) index should be card(9) index + 1.
    return targetTop.card.rank.index == card.rank.index + 1;
  }

  // DRAG & DROP HANDLERS

  void moveWasteToFoundation(PlayingCard card) {
    if (!canMoveToFoundation(card)) return;

    // Remove from Waste
    final newWaste = List<PlayingCard>.from(state.waste)
      ..removeLast(); // assume it's the top one

    // Add to Foundation
    final newFoundation = Map<Suit, List<PlayingCard>>.from(state.foundation);
    newFoundation[card.suit] = List.from(newFoundation[card.suit]!)..add(card);

    state = state.copyWith(
      waste: newWaste,
      foundation: newFoundation,
      moves: state.moves + 1,
    );
    _checkWin();
  }

  void moveWasteToTableau(PlayingCard card, int colIndex) {
    final col = state.tableau[colIndex];
    final targetCard = col.isEmpty ? null : col.last;

    if (!canMoveToTableau(card, targetCard)) return;

    // Remove from Waste
    final newWaste = List<PlayingCard>.from(state.waste)..removeLast();

    // Add to Tableau
    final newTableau = List<List<SolitaireCard>>.from(state.tableau);
    newTableau[colIndex] = List.from(col)
      ..add(SolitaireCard(card: card, isFaceUp: true));

    state = state.copyWith(
      waste: newWaste,
      tableau: newTableau,
      moves: state.moves + 1,
    );
  }

  void moveTableauToFoundation(int colIndex, PlayingCard card) {
    if (!canMoveToFoundation(card)) return;

    final col = state.tableau[colIndex];
    // Only the top card (last) can move to foundation
    if (col.isEmpty || col.last.card != card) return;

    // Remove
    final newCol = List<SolitaireCard>.from(col)..removeLast();
    // Reveal new top if needed
    if (newCol.isNotEmpty && !newCol.last.isFaceUp) {
      newCol[newCol.length - 1] = newCol.last.flip();
    }

    final newTableau = List<List<SolitaireCard>>.from(state.tableau);
    newTableau[colIndex] = newCol;

    final newFoundation = Map<Suit, List<PlayingCard>>.from(state.foundation);
    newFoundation[card.suit] = List.from(newFoundation[card.suit]!)..add(card);

    state = state.copyWith(
      tableau: newTableau,
      foundation: newFoundation,
      moves: state.moves + 1,
    );
    _checkWin();
  }

  // Moving a stack within Tableau
  void moveTableauStack(int fromCol, int fromIndex, int toCol) {
    // fromIndex is where the stack starts
    final sourceCol = state.tableau[fromCol];
    final movingCards = sourceCol.sublist(fromIndex);
    final baseCard = movingCards.first.card;

    final destCol = state.tableau[toCol];
    final targetCard = destCol.isEmpty ? null : destCol.last;

    if (!canMoveToTableau(baseCard, targetCard)) return;

    // Execute Move
    final newSourceCol = List<SolitaireCard>.from(sourceCol)
      ..removeRange(fromIndex, sourceCol.length);
    // Reveal
    if (newSourceCol.isNotEmpty && !newSourceCol.last.isFaceUp) {
      newSourceCol[newSourceCol.length - 1] = newSourceCol.last.flip();
    }

    final newDestCol = List<SolitaireCard>.from(destCol)..addAll(movingCards);

    final newTableau = List<List<SolitaireCard>>.from(state.tableau);
    newTableau[fromCol] = newSourceCol;
    newTableau[toCol] = newDestCol;

    state = state.copyWith(tableau: newTableau, moves: state.moves + 1);
  }

  void moveFoundationToTableau(PlayingCard card, int toCol) {
    // Allow moving back from foundation? Standard rules allow it.
    final pile = state.foundation[card.suit]!;
    if (pile.isEmpty || pile.last != card) return; // Must be top

    final destCol = state.tableau[toCol];
    final targetCard = destCol.isEmpty ? null : destCol.last;

    if (!canMoveToTableau(card, targetCard)) return;

    // Move
    final newFoundation = Map<Suit, List<PlayingCard>>.from(state.foundation);
    newFoundation[card.suit] = List.from(pile)..removeLast();

    final newTableau = List<List<SolitaireCard>>.from(state.tableau);
    newTableau[toCol] = List.from(destCol)
      ..add(SolitaireCard(card: card, isFaceUp: true));

    state = state.copyWith(
      foundation: newFoundation,
      tableau: newTableau,
      moves: state.moves + 1,
    );
  }

  void _checkWin() {
    // Win if all 52 cards are in foundation (or stock/waste/tableau empty? essentially same)
    int totalFoundation = 0;
    state.foundation.forEach((_, list) => totalFoundation += list.length);

    if (totalFoundation == 52) {
      state = state.copyWith(isWon: true);
    }
  }
}
