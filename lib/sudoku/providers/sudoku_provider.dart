import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sudoku_models.dart';

final sudokuProvider = StateNotifierProvider<SudokuNotifier, SudokuGameState>((
  ref,
) {
  return SudokuNotifier();
});

class SudokuNotifier extends StateNotifier<SudokuGameState> {
  SudokuNotifier()
    : super(
        SudokuGameState(
          board: _createEmptyBoard(),
          difficulty: SudokuDifficulty.medium,
          status: SudokuStatus.paused,
        ),
      );

  static List<List<SudokuCell>> _createEmptyBoard() {
    return List.generate(9, (_) => List.generate(9, (_) => const SudokuCell()));
  }

  void startNewGame(SudokuDifficulty difficulty) {
    final fullBoard = _generateFullBoard();
    final puzzleBoard = _removeNumbers(fullBoard, difficulty);

    state = SudokuGameState(
      board: puzzleBoard,
      difficulty: difficulty,
      status: SudokuStatus.playing,
      timer: Duration.zero,
    );
  }

  void selectCell(int row, int col) {
    state = state.copyWith(selectedRow: row, selectedCol: col);
  }

  void setNumber(int number) {
    if (state.selectedRow == null || state.selectedCol == null) return;
    if (state.status != SudokuStatus.playing) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    final cell = state.board[row][col];

    if (cell.isPreFilled) return;

    if (state.isNotesMode) {
      _toggleNote(row, col, number);
    } else {
      _setCellValue(row, col, number);
    }
  }

  void eraseCell() {
    if (state.selectedRow == null || state.selectedCol == null) return;
    final row = state.selectedRow!;
    final col = state.selectedCol!;
    final cell = state.board[row][col];

    if (cell.isPreFilled) return;

    final newBoard = _copyBoard(state.board);
    newBoard[row][col] = const SudokuCell();
    state = state.copyWith(board: newBoard);
  }

  void toggleNotesMode() {
    state = state.copyWith(isNotesMode: !state.isNotesMode);
  }

  void _setCellValue(int row, int col, int value) {
    final newBoard = _copyBoard(state.board);
    final currentCell = newBoard[row][col];

    // Toggle value if same
    if (currentCell.value == value) {
      newBoard[row][col] = const SudokuCell();
    } else {
      newBoard[row][col] = SudokuCell(value: value);
    }

    state = state.copyWith(board: newBoard);
    _checkWinCondition();
  }

  void _toggleNote(int row, int col, int value) {
    final newBoard = _copyBoard(state.board);
    final cell = newBoard[row][col];
    final newNotes = Set<int>.from(cell.notes);

    if (newNotes.contains(value)) {
      newNotes.remove(value);
    } else {
      newNotes.add(value);
    }

    newBoard[row][col] = cell.copyWith(notes: newNotes, clearValue: true);
    state = state.copyWith(board: newBoard);
  }

  // --- Generation Logic ---

  List<List<int>> _generateFullBoard() {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _solve(board);
    return board;
  }

  bool _solve(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (var n in numbers) {
            if (_isValid(board, row, col, n)) {
              board[row][col] = n;
              if (_solve(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValid(List<List<int>> board, int row, int col, int n) {
    // Check row and column
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == n || board[i][col] == n) return false;
    }
    // Check 3x3 box
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[startRow + i][startCol + j] == n) return false;
      }
    }
    return true;
  }

  List<List<SudokuCell>> _removeNumbers(
    List<List<int>> fullBoard,
    SudokuDifficulty difficulty,
  ) {
    final board = List.generate(
      9,
      (r) => List.generate(
        9,
        (c) => SudokuCell(value: fullBoard[r][c], isPreFilled: true),
      ),
    );

    int toRemove;
    switch (difficulty) {
      case SudokuDifficulty.easy:
        toRemove = 30;
        break;
      case SudokuDifficulty.medium:
        toRemove = 45;
        break;
      case SudokuDifficulty.hard:
        toRemove = 55;
        break;
    }

    final random = math.Random();
    int removed = 0;
    while (removed < toRemove) {
      int r = random.nextInt(9);
      int c = random.nextInt(9);
      if (board[r][c].isPreFilled) {
        board[r][c] = const SudokuCell(isPreFilled: false);
        removed++;
      }
    }

    return board;
  }

  // --- Helpers ---

  List<List<SudokuCell>> _copyBoard(List<List<SudokuCell>> original) {
    return List.generate(9, (r) => List.from(original[r]));
  }

  void _checkWinCondition() {
    // 1. Check if all cells are filled
    for (var row in state.board) {
      for (var cell in row) {
        if (cell.value == null) return;
      }
    }

    // 2. Simple check: is every row/col/box valid?
    if (_isBoardCompleteAndValid()) {
      state = state.copyWith(status: SudokuStatus.won);
    }
  }

  bool _isBoardCompleteAndValid() {
    // Check Rows
    for (int r = 0; r < 9; r++) {
      if (!_isValidSet(state.board[r].map((e) => e.value!).toList())) {
        return false;
      }
    }
    // Check Cols
    for (int c = 0; c < 9; c++) {
      final col = <int>[];
      for (int r = 0; r < 9; r++) {
        col.add(state.board[r][c].value!);
      }
      if (!_isValidSet(col)) {
        return false;
      }
    }
    // Check Boxes
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        final box = <int>[];
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            box.add(state.board[boxRow * 3 + r][boxCol * 3 + c].value!);
          }
        }
        if (!_isValidSet(box)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidSet(List<int> values) {
    final set = Set<int>.from(values);
    return set.length == 9 && !set.contains(0);
  }
}
