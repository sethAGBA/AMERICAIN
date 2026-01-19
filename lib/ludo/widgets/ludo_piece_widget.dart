import 'package:flutter/material.dart';
import '../models/ludo_piece.dart'; // For LudoColor

class LudoPieceWidget extends StatelessWidget {
  final LudoColor color;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;
  final double size;

  const LudoPieceWidget({
    super.key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
    this.count = 1,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color
    Color pieceColor;
    switch (color) {
      case LudoColor.red:
        pieceColor = Colors.red;
        break;
      case LudoColor.green:
        pieceColor = Colors.green;
        break;
      case LudoColor.yellow:
        pieceColor = Colors.yellow;
        break;
      case LudoColor.blue:
        pieceColor = Colors.blue;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: pieceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.5),
                width: isSelected ? 3.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: size * 0.4,
                      height: size * 0.4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          if (count > 1)
            Positioned(
              right: -size * 0.1,
              top: -size * 0.1,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  minWidth: size * 0.4,
                  minHeight: size * 0.4,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
