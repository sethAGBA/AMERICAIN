import 'package:equatable/equatable.dart';

enum SudokuDifficulty { easy, medium, hard }

enum SudokuStatus { playing, won, paused }

class SudokuCell extends Equatable {
  final int? value;
  final bool isPreFilled;
  final Set<int> notes;
  final bool? isIncorrect; // Optional: for immediate feedback

  const SudokuCell({
    this.value,
    this.isPreFilled = false,
    this.notes = const {},
    this.isIncorrect,
  });

  SudokuCell copyWith({
    int? value,
    bool? isPreFilled,
    Set<int>? notes,
    bool? isIncorrect,
    bool clearValue = false,
  }) {
    return SudokuCell(
      value: clearValue ? null : (value ?? this.value),
      isPreFilled: isPreFilled ?? this.isPreFilled,
      notes: notes ?? this.notes,
      isIncorrect: isIncorrect ?? this.isIncorrect,
    );
  }

  @override
  List<Object?> get props => [value, isPreFilled, notes, isIncorrect];
}

class SudokuGameState extends Equatable {
  final List<List<SudokuCell>> board;
  final SudokuDifficulty difficulty;
  final SudokuStatus status;
  final Duration timer;
  final bool isNotesMode;
  final int? selectedRow;
  final int? selectedCol;

  const SudokuGameState({
    required this.board,
    required this.difficulty,
    this.status = SudokuStatus.playing,
    this.timer = Duration.zero,
    this.isNotesMode = false,
    this.selectedRow,
    this.selectedCol,
  });

  SudokuGameState copyWith({
    List<List<SudokuCell>>? board,
    SudokuDifficulty? difficulty,
    SudokuStatus? status,
    Duration? timer,
    bool? isNotesMode,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
  }) {
    return SudokuGameState(
      board: board ?? this.board,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      timer: timer ?? this.timer,
      isNotesMode: isNotesMode ?? this.isNotesMode,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
    );
  }

  @override
  List<Object?> get props => [
    board,
    difficulty,
    status,
    timer,
    isNotesMode,
    selectedRow,
    selectedCol,
  ];
}
