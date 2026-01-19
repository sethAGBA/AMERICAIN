import 'package:flutter/material.dart';

enum PatternType { suits, dice, board, circles }

class GenericPattern extends StatelessWidget {
  final double opacity;
  final int crossAxisCount;
  final PatternType type;
  final Color? color;

  const GenericPattern({
    super.key,
    this.opacity = 0.05,
    this.crossAxisCount = 8,
    this.type = PatternType.circles,
    this.color,
  });

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
          return Center(child: _buildIcon(index));
        },
      ),
    );
  }

  Widget _buildIcon(int index) {
    switch (type) {
      case PatternType.suits:
        final suitSymbols = ['♠', '♥', '♣', '♦'];
        final symbol = suitSymbols[index % 4];
        return Text(
          symbol,
          style: TextStyle(fontSize: 30, color: color ?? Colors.white),
        );
      case PatternType.dice:
        final diceIcons = [
          Icons.casino_outlined,
          Icons.filter_1_outlined,
          Icons.filter_2_outlined,
          Icons.filter_3_outlined,
          Icons.filter_4_outlined,
          Icons.filter_5_outlined,
          Icons.filter_6_outlined,
        ];
        return Icon(
          diceIcons[index % diceIcons.length],
          size: 30,
          color: color ?? Colors.white,
        );
      case PatternType.board:
        return Icon(
          index % 2 == (index ~/ crossAxisCount) % 2
              ? Icons.square
              : Icons.square_outlined,
          size: 30,
          color: color ?? Colors.white,
        );
      case PatternType.circles:
        return Icon(
          index % 2 == 0 ? Icons.circle_outlined : Icons.circle,
          size: 20,
          color: color ?? Colors.white,
        );
    }
  }
}
