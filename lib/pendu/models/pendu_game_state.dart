import 'package:equatable/equatable.dart';

enum PenduStatus { playing, won, lost }

class PenduGameState extends Equatable {
  final String targetWord;
  final String definition;
  final Set<String> guessedLetters;
  final int remainingAttempts;
  final int maxAttempts;
  final PenduStatus status;

  const PenduGameState({
    required this.targetWord,
    required this.definition,
    required this.guessedLetters,
    required this.remainingAttempts,
    required this.maxAttempts,
    required this.status,
  });

  factory PenduGameState.initial({
    required String word,
    required String definition,
    int maxAttempts = 7,
  }) {
    return PenduGameState(
      targetWord: word.toUpperCase(),
      definition: definition,
      guessedLetters: const {},
      remainingAttempts: maxAttempts,
      maxAttempts: maxAttempts,
      status: PenduStatus.playing,
    );
  }

  PenduGameState copyWith({
    String? targetWord,
    String? definition,
    Set<String>? guessedLetters,
    int? remainingAttempts,
    int? maxAttempts,
    PenduStatus? status,
  }) {
    return PenduGameState(
      targetWord: targetWord ?? this.targetWord,
      definition: definition ?? this.definition,
      guessedLetters: guessedLetters ?? this.guessedLetters,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    targetWord,
    definition,
    guessedLetters,
    remainingAttempts,
    maxAttempts,
    status,
  ];
}
