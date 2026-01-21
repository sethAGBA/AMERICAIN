import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class MemoryCard extends Equatable {
  final String id;
  final IconData icon;
  final bool isFlipped;
  final bool isMatched;

  const MemoryCard({
    required this.id,
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });

  MemoryCard copyWith({bool? isFlipped, bool? isMatched}) {
    return MemoryCard(
      id: id,
      icon: icon,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  List<Object?> get props => [id, icon, isFlipped, isMatched];
}
