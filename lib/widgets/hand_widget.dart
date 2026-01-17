import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/card.dart';
import '../models/player.dart';
import '../services/game_logic.dart';
import 'card_widget.dart';

/// Widget to display a player's hand of cards
class HandWidget extends StatelessWidget {
  final Player player;
  final PlayingCard? topCard;
  final Suit? currentSuit;
  final Function(PlayingCard)? onCardTap;
  final bool isCurrentPlayer;
  final int penalty;
  final PlayingCard? activeAttackCard;
  final Suit? mustMatchSuit;

  const HandWidget({
    super.key,
    required this.player,
    this.topCard,
    this.currentSuit,
    this.onCardTap,
    this.isCurrentPlayer = false,
    this.penalty = 0,
    this.activeAttackCard,
    this.mustMatchSuit,
  });

  @override
  Widget build(BuildContext context) {
    if (player.hand.isEmpty) {
      return const Center(
        child: Text(
          'Aucune carte',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 160, // Increased height to allow pop-up animation
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: player.hand.length,
        itemBuilder: (context, index) {
          final card = player.hand[index];

          bool isPlayable = isCurrentPlayer && topCard != null;
          if (isPlayable) {
            isPlayable = GameLogic.isValidMove(
              card,
              topCard!,
              currentSuit,
              penalty: penalty,
              activeAttackCard: activeAttackCard,
              mustMatchSuit: mustMatchSuit,
              playerHand: player.hand,
            );
          }

          return Align(
                alignment: Alignment
                    .bottomCenter, // Align to bottom so pop-up goes up into empty space
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  transform: Matrix4.translationValues(
                    0,
                    isPlayable ? -30 : 0, // Increased pop-up distance slightly
                    0,
                  ),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 0, // Padding handled by ListView
                    right: 8,
                    bottom: 10, // Base padding from bottom
                  ),
                  child: CardWidget(
                    card: card,
                    faceUp: isCurrentPlayer,
                    isPlayable: isPlayable,
                    onTap: isPlayable && onCardTap != null
                        ? () => onCardTap!(card)
                        : null,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (100 * index).ms)
              .slide(
                begin: const Offset(0, -1), // Slide from top
                end: Offset.zero,
                duration: 500.ms,
                delay: (100 * index).ms,
                curve: Curves.easeOutQuad,
              );
        },
      ),
    );
  }
}
