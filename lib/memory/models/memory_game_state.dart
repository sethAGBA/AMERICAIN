import 'package:equatable/equatable.dart';
import 'memory_card.dart';

enum MemoryGameStatus { playing, won }

class MemoryGameState extends Equatable {
  final List<MemoryCard> cards;
  final int attempts;
  final bool isLocked;
  final MemoryGameStatus status;
  final bool isMultiplayer;
  final int currentPlayer;
  final List<int> playerScores;

  const MemoryGameState({
    required this.cards,
    required this.attempts,
    required this.isLocked,
    required this.status,
    this.isMultiplayer = false,
    this.currentPlayer = 0,
    this.playerScores = const [0, 0],
  });

  factory MemoryGameState.initial() {
    return const MemoryGameState(
      cards: [],
      attempts: 0,
      isLocked: false,
      status: MemoryGameStatus.playing,
    );
  }

  MemoryGameState copyWith({
    List<MemoryCard>? cards,
    int? attempts,
    bool? isLocked,
    MemoryGameStatus? status,
    bool? isMultiplayer,
    int? currentPlayer,
    List<int>? playerScores,
  }) {
    return MemoryGameState(
      cards: cards ?? this.cards,
      attempts: attempts ?? this.attempts,
      isLocked: isLocked ?? this.isLocked,
      status: status ?? this.status,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      playerScores: playerScores ?? this.playerScores,
    );
  }

  @override
  List<Object?> get props => [
    cards,
    attempts,
    isLocked,
    status,
    isMultiplayer,
    currentPlayer,
    playerScores,
  ];
}
