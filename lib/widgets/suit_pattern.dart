import 'package:flutter/material.dart';

/// A subtle background pattern of card suits
class SuitPattern extends StatelessWidget {
  final double opacity;
  final int crossAxisCount;

  const SuitPattern({super.key, this.opacity = 0.1, this.crossAxisCount = 6});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        itemBuilder: (context, index) {
          final suitSymbols = ['♠', '♥', '♣', '♦'];
          final symbol = suitSymbols[index % 4];
          final isRed = symbol == '♥' || symbol == '♦';

          return Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 40,
                color: isRed ? Colors.red : Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }
}
