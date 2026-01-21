import 'package:flutter/material.dart';

enum Puissance4Color { red, yellow }

enum PlayerType { human, bot }

class Puissance4Player {
  final String id;
  final String name;
  final Puissance4Color color;
  final PlayerType type;
  final int score;

  const Puissance4Player({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
    this.score = 0,
  });

  Puissance4Player copyWith({
    String? id,
    String? name,
    Puissance4Color? color,
    PlayerType? type,
    int? score,
  }) {
    return Puissance4Player(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      score: score ?? this.score,
    );
  }

  Color get uiColor {
    switch (color) {
      case Puissance4Color.red:
        return Colors.red;
      case Puissance4Color.yellow:
        return Colors.yellow;
    }
  }
}
