import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/solitaire_provider.dart';
import '../models/solitaire_state.dart';
import '../models/solitaire_card.dart';
import '../../models/card.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_exit_dialog.dart';

class SolitaireGameScreen extends ConsumerStatefulWidget {
  const SolitaireGameScreen({super.key});

  @override
  ConsumerState<SolitaireGameScreen> createState() =>
      _SolitaireGameScreenState();
}

class _SolitaireGameScreenState extends ConsumerState<SolitaireGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    if (settings.musicEnabled) {
      SoundService.playBGM(settings.gameMusicPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solitaireProvider);

    ref.listen(solitaireProvider.select((s) => s.isWon), (prev, won) {
      if (won == true) {
        _showWinDialog(context);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Standard felt green
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Top Row: Stock, Waste, Spacers, Foundations
                    SizedBox(
                      height: _cardHeight(context),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStock(state),
                          const SizedBox(width: 8),
                          _buildWaste(state),
                          const Spacer(),
                          _buildFoundations(state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tableau Area
                    Expanded(child: _buildTableau(state)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SolitaireState state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(solitaireProvider.notifier).initGame();
            },
          ),
          Text(
            'COUPS: ${state.moves}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _confirmExit(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStock(SolitaireState state) {
    return GestureDetector(
      onTap: () {
        ref.read(solitaireProvider.notifier).drawCard();
      },
      child: state.stock.isEmpty
          ? _buildEmptyPlaceholder(label: '↺') // Refresh symbol
          : _buildCardBack(),
    );
  }

  Widget _buildWaste(SolitaireState state) {
    if (state.waste.isEmpty) return const SizedBox();

    final card = state.waste.last;

    return Draggable<Map<String, dynamic>>(
      data: {'card': card, 'source': 'waste'},
      feedback: Transform.scale(scale: 1.1, child: _buildCardFront(card)),
      childWhenDragging: state.waste.length > 1
          ? _buildCardFront(
              state.waste[state.waste.length - 2],
            ) // Show card underneath
          : SizedBox(width: _cardWidth(context), height: _cardHeight(context)),
      child: _buildCardFront(card),
    );
  }

  Widget _buildFoundations(SolitaireState state) {
    return Row(
      children: Suit.values.map((suit) {
        final pile = state.foundation[suit]!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) {
              if (data == null) return false;
              final card = data['card'] as PlayingCard;
              return ref
                  .read(solitaireProvider.notifier)
                  .canMoveToFoundation(card);
            },
            onAccept: (data) {
              final card = data['card'] as PlayingCard;
              final source = data['source'] as String;
              final notifier = ref.read(solitaireProvider.notifier);

              if (source == 'waste') {
                notifier.moveWasteToFoundation(card);
              } else if (source == 'tableau') {
                final fromCol = data['colIndex'] as int;
                notifier.moveTableauToFoundation(fromCol, card);
              }
            },
            builder: (context, candidates, rejects) {
              if (pile.isEmpty) {
                return _buildEmptyPlaceholder(
                  icon: Text(
                    suit.symbol,
                    style: TextStyle(
                      fontSize: 24,
                      color: (suit == Suit.hearts || suit == Suit.diamonds)
                          ? Colors.red.withOpacity(0.3)
                          : Colors.black.withOpacity(0.3),
                    ),
                  ),
                );
              }
              return _buildCardFront(pile.last);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableau(SolitaireState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(7, (colIndex) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: DragTarget<Map<String, dynamic>>(
              // We accept a Map for tableau moves because we need to know:
              // 1. Is it a single card or stack?
              // 2. From where?
              // For Waste -> Tableau, maybe pass simple structure.
              // Let's standardize DragData.
              onWillAccept: (data) {
                if (data == null) return false;
                final card = data['card'] as PlayingCard;

                final col = state.tableau[colIndex];
                final targetCard = col.isEmpty ? null : col.last;

                return ref
                    .read(solitaireProvider.notifier)
                    .canMoveToTableau(card, targetCard);
              },
              onAccept: (data) {
                final card = data['card'] as PlayingCard;
                final source = data['source'] as String; // 'waste', 'tableau'
                final notifier = ref.read(solitaireProvider.notifier);

                if (source == 'waste') {
                  notifier.moveWasteToTableau(card, colIndex);
                } else if (source == 'tableau') {
                  final fromCol = data['colIndex'] as int;
                  final fromCardIndex =
                      data['cardIndex'] as int; // index within that column
                  // Check if it's the top card or a stack?
                  // Provider `moveTableauStack` handles stack.
                  notifier.moveTableauStack(fromCol, fromCardIndex, colIndex);
                } else if (source == 'foundation') {
                  notifier.moveFoundationToTableau(card, colIndex);
                }
              },
              builder: (context, candidates, rejects) {
                return Stack(
                  children: _buildTableauStack(
                    state.tableau[colIndex],
                    colIndex,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildTableauStack(List<SolitaireCard> cards, int colIndex) {
    if (cards.isEmpty) {
      return [_buildEmptyPlaceholder()];
    }

    return List.generate(cards.length, (index) {
      final sCard = cards[index];
      // We apply an offset.
      // Face down cards closer together? Or standard offset.
      double offset = index * 30.0; // Basic offset

      Widget cardWidget = sCard.isFaceUp
          ? _buildCardFront(sCard.card)
          : _buildCardBack();

      if (sCard.isFaceUp) {
        // Draggable
        cardWidget = Draggable<Map<String, dynamic>>(
          data: {
            'card': sCard.card,
            'source': 'tableau',
            'colIndex': colIndex,
            'cardIndex': index,
          },
          feedback: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                _buildCardFront(sCard.card),
                // Verify if dragging a stack, should show stack in feedback?
                // For MVP just show the lead card is fine, or refine later.
                if (index < cards.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      width: 50,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ), // visual hint of stack
                  ),
              ],
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: cardWidget),
          child: cardWidget,
        );
      }

      return Positioned(top: offset, left: 0, right: 0, child: cardWidget);
    });
  }

  // Also enable dragging FROM waste with the new Map format
  // Re-define _buildWaste logic slightly to match.
  // Wait, _buildWaste uses Draggable<PlayingCard>. _buildTableau uses Draggable<Map>.
  // Tableau DragTarget accepts Map.
  // I need to update _buildWaste to use Map or update Tableau DragTarget to handle PlayingCard (and assume Waste).
  // Best to update Waste to use Map so it's consistent.
  // Actually, Foundation DragTarget accepted PlayingCard.
  // I should update Foundation DragTarget to accept Map too or handle checks.
  // Let's refactor Foundation DragTarget to accept Map.

  // ... refactoring helpers ...

  // UI Helpers

  double _cardWidth(BuildContext context) {
    // 7 columns + 8 gaps + margins.
    // width = (screen - margins) / 7
    return (MediaQuery.of(context).size.width - 24) / 7;
  }

  double _cardHeight(BuildContext context) {
    return _cardWidth(context) * 1.45;
  }

  Widget _buildCardBack() {
    return Container(
      width: _cardWidth(context),
      height: _cardHeight(context),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Center(child: Icon(Icons.grid_3x3, color: Colors.white24)),
    );
  }

  Widget _buildCardFront(PlayingCard card) {
    return Container(
      width: _cardWidth(context),
      height: _cardHeight(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive font sizes
          final rankSize = constraints.maxHeight * 0.18;
          final smallSuitSize = constraints.maxHeight * 0.15;
          final centerSuitSize = constraints.maxHeight * 0.35;

          return Stack(
            children: [
              // Top Left Corner
              Positioned(
                top: 4,
                left: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.rank.displayValue,
                      style: TextStyle(
                        color: _getCardColor(card.suit),
                        fontWeight: FontWeight.bold,
                        fontSize: rankSize,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      card.suit.symbol,
                      style: TextStyle(
                        color: _getCardColor(card.suit),
                        fontSize: smallSuitSize,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Center Suit
              Center(
                child: Text(
                  card.suit.symbol,
                  style: TextStyle(
                    color: _getCardColor(card.suit),
                    fontSize: centerSuitSize,
                  ),
                ),
              ),

              // Bottom Right Corner (Rotated)
              Positioned(
                bottom: 4,
                right: 4,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.rank.displayValue,
                        style: TextStyle(
                          color: _getCardColor(card.suit),
                          fontWeight: FontWeight.bold,
                          fontSize: rankSize,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        card.suit.symbol,
                        style: TextStyle(
                          color: _getCardColor(card.suit),
                          fontSize: smallSuitSize,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlaceholder({Widget? icon, String? label}) {
    return Container(
      width: _cardWidth(context),
      height: _cardHeight(context),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child:
            icon ??
            (label != null
                ? Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 20),
                  )
                : null),
      ),
    );
  }

  Color _getCardColor(Suit suit) {
    return (suit == Suit.hearts || suit == Suit.diamonds)
        ? Colors.red
        : Colors.black;
  }

  void _showWinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Gagné !"),
        content: const Text("Bravo, vous avez terminé le Solitaire."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              ref.read(solitaireProvider.notifier).initGame(); // restart
            },
            child: const Text("Rejouer"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // exit
            },
            child: const Text("Quitter"),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GameExitDialog(
        title: 'Quitter ?',
        content: 'Voulez-vous vraiment quitter la partie ?',
        backgroundColor: const Color(0xFF1B5E20),
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}
