import 'package:flutter/material.dart';

enum ChifoumiMove {
  rock,
  paper,
  scissors;

  String get label {
    switch (this) {
      case ChifoumiMove.rock:
        return 'Pierre';
      case ChifoumiMove.paper:
        return 'Feuille';
      case ChifoumiMove.scissors:
        return 'Ciseaux';
    }
  }

  IconData get icon {
    switch (this) {
      case ChifoumiMove.rock:
        return Icons.circle; // Simplified Rock
      case ChifoumiMove.paper:
        return Icons.back_hand; // Flat hand
      case ChifoumiMove.scissors:
        return Icons.cut; // Scissors
    }
  }

  Color get color {
    switch (this) {
      case ChifoumiMove.rock:
        return Colors.grey;
      case ChifoumiMove.paper:
        return Colors.blue;
      case ChifoumiMove.scissors:
        return Colors.red;
    }
  }

  bool beats(ChifoumiMove other) {
    if (this == ChifoumiMove.rock) return other == ChifoumiMove.scissors;
    if (this == ChifoumiMove.paper) return other == ChifoumiMove.rock;
    if (this == ChifoumiMove.scissors) return other == ChifoumiMove.paper;
    return false;
  }
}
