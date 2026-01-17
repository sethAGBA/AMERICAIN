import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/card.dart';

/// Widget to display a single playing card
class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool faceUp;
  final bool isPlayable;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    required this.card,
    this.faceUp = true,
    this.isPlayable = false,
    this.onTap,
    this.width = 70,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: isPlayable ? onTap : null,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: faceUp ? Colors.white : Colors.blue.shade800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPlayable ? Colors.green : Colors.grey.shade300,
                width: isPlayable ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: faceUp ? _buildFaceUp() : _buildFaceDown(),
          ),
        )
        .animate(target: isPlayable ? 1 : 0)
        .shimmer(duration: 1500.ms, color: Colors.green.withValues(alpha: 0.3))
        .then()
        .shimmer(duration: 1500.ms, color: Colors.green.withValues(alpha: 0.3));
  }

  Widget _buildFaceUp() {
    final isRed = card.suit.color == 'red';
    final color = isRed ? Colors.red : Colors.black;
    final isJoker = card.rank == Rank.joker;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height after padding
        // Uses width < 60 as small card threshold
        final isSmall = constraints.maxWidth < 60;
        final padding = isSmall ? 2.0 : 8.0;

        // Define text styles based on size
        final rankStyle = TextStyle(
          fontSize: isSmall ? 12 : 18,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.0,
        );
        final suitStyle = TextStyle(
          fontSize: isSmall ? 10 : 16,
          color: color,
          height: 1.0,
        );

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top corner
              Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(card.rank.displayValue, style: rankStyle),
                    if (!isJoker) Text(card.suit.symbol, style: suitStyle),
                  ],
                ),
              ),

              // Center suit symbol - Use nice big symbol if space permits
              // Use Expanded + FittedBox to fill available space without overflow
              if (constraints.maxHeight > 50)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        isJoker ? card.rank.displayValue : card.suit.symbol,
                        style: TextStyle(color: color),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(), // Just fill space if too small for center symbol
              // Bottom corner (rotated)
              Align(
                alignment: Alignment.bottomRight,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(card.rank.displayValue, style: rankStyle),
                      if (!isJoker) Text(card.suit.symbol, style: suitStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaceDown() {
    return Center(
      child: Icon(
        Icons.style,
        size: 40,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}
