import 'package:equatable/equatable.dart';
import 'chifoumi_move.dart';

class ChifoumiState extends Equatable {
  final ChifoumiMove? playerMove;
  final ChifoumiMove? botMove;
  final int playerScore;
  final int botScore;
  final bool isRevealing; // True when showing the result animation
  final String? resultMessage; // "Gagné !", "Perdu", "Égalité"

  const ChifoumiState({
    this.playerMove,
    this.botMove,
    this.playerScore = 0,
    this.botScore = 0,
    this.isRevealing = false,
    this.resultMessage,
  });

  factory ChifoumiState.initial() {
    return const ChifoumiState();
  }

  ChifoumiState copyWith({
    ChifoumiMove? playerMove,
    ChifoumiMove? botMove,
    int? playerScore,
    int? botScore,
    bool? isRevealing,
    String? resultMessage,
  }) {
    return ChifoumiState(
      playerMove: playerMove ?? this.playerMove,
      botMove: botMove ?? this.botMove,
      playerScore: playerScore ?? this.playerScore,
      botScore: botScore ?? this.botScore,
      isRevealing: isRevealing ?? this.isRevealing,
      resultMessage: resultMessage ?? this.resultMessage,
    );
  }

  /// Reset moves but keep scores
  ChifoumiState resetRound() {
    return ChifoumiState(
      playerScore: playerScore,
      botScore: botScore,
      isRevealing: false,
    );
  }

  @override
  List<Object?> get props => [
    playerMove,
    botMove,
    playerScore,
    botScore,
    isRevealing,
    resultMessage,
  ];
}
