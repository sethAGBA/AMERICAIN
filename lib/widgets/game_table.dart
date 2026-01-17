import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/card.dart';
import 'card_widget.dart';

/// Widget to display the game table with deck and discard pile
class GameTable extends StatelessWidget {
  final GameState gameState;
  final String currentPlayerId;
  final VoidCallback? onDrawCard;

  const GameTable({
    super.key,
    required this.gameState,
    required this.currentPlayerId,
    this.onDrawCard,
  });

  @override
  Widget build(BuildContext context) {
    final topCard = gameState.topCard;
    final isCurrentPlayerTurn = gameState.currentPlayer?.id == currentPlayerId;

    return Column(
      children: [
        // Other players
        _buildOtherPlayers(context),

        const SizedBox(height: 20),

        // Game table center
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Deck
            _buildDeck(context, isCurrentPlayerTurn),

            const SizedBox(width: 40),

            // Discard pile
            _buildDiscardPile(context, topCard),
          ],
        ),

        const SizedBox(height: 20),

        // Current suit indicator
        if (gameState.currentSuit != null) _buildCurrentSuitIndicator(context),
      ],
    );
  }

  Widget _buildOtherPlayers(BuildContext context) {
    final otherPlayers = gameState.players
        .where((p) => p.id != currentPlayerId)
        .toList();

    if (otherPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: otherPlayers.length,
        itemBuilder: (context, index) {
          final player = otherPlayers[index];
          return _buildPlayerInfo(context, player);
        },
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context, Player player) {
    final isCurrentTurn = player.id == gameState.currentPlayer?.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentTurn ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentTurn ? Colors.green.shade900 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, size: 16),
              const SizedBox(width: 4),
              Text(
                '${player.cardCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeck(BuildContext context, bool canDraw) {
    final hasCards = gameState.deck.isNotEmpty;
    // Allow refill if deck is empty but discard pile has cards (top card stays, so need > 1)
    final canRefill = !hasCards && gameState.discardPile.length > 1;
    final isInteractive = canDraw && (hasCards || canRefill);

    return Column(
      children: [
        Text(
          canRefill ? 'Refaire pioche' : 'Pioche',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isInteractive ? onDrawCard : null,
          child: Stack(
            children: [
              // Show stacked cards effect
              if (hasCards || canRefill) ...[
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  color: hasCards || canRefill
                      ? Colors.blue.shade800
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isInteractive ? Colors.yellow : Colors.grey,
                    width: isInteractive ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    hasCards
                        ? Icons.style
                        : (canRefill ? Icons.refresh : Icons.block),
                    size: 40,
                    color: hasCards || canRefill
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${gameState.deck.length} cartes',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDiscardPile(BuildContext context, PlayingCard? topCard) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Défausse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (gameState.isClockwise)
              const Icon(Icons.rotate_right, color: Colors.green)
            else
              const Icon(Icons.rotate_left, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            topCard != null
                ? CardWidget(card: topCard, faceUp: true)
                : Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Icon(Icons.layers_clear, color: Colors.grey),
                    ),
                  ),
            // Penalty Indicator
            if (gameState.getPenaltyFor(gameState.currentPlayer?.id ?? '') > 0)
              Positioned(
                top: -10,
                right: -10,
                child:
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '+${gameState.getPenaltyFor(gameState.currentPlayer?.id ?? '')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                        ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentSuitIndicator(BuildContext context) {
    // Only show prominent indicator if top card is special (8)
    // Otherwise it's obvious from the card itself
    if (gameState.topCard?.isSpecial != true) return const SizedBox.shrink();

    final suit = gameState.currentSuit!;
    final isRed = suit.color == 'red';

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isRed ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isRed ? Colors.red : Colors.blue.shade800,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isRed ? Colors.red : Colors.blue).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'COULEUR DEMANDÉE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                        suit.symbol,
                        style: TextStyle(
                          fontSize: 48,
                          color: isRed ? Colors.red : Colors.blue.shade900,
                          height: 1,
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 800.ms,
                      ),
                  const SizedBox(width: 12),
                  Text(
                    suit.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isRed ? Colors.red : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms);
  }
}
