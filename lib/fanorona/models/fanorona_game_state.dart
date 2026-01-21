import 'package:equatable/equatable.dart';

enum FanoronaPiece { white, black }

class BoardPoint extends Equatable {
  final int x;
  final int y;

  const BoardPoint(this.x, this.y);

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';

  BoardPoint operator +(BoardPoint other) =>
      BoardPoint(x + other.x, y + other.y);
  BoardPoint operator -(BoardPoint other) =>
      BoardPoint(x - other.x, y - other.y);
  BoardPoint operator *(int scalar) => BoardPoint(x * scalar, y * scalar);
}

enum FanoronaStatus { playing, won }

class FanoronaGameState extends Equatable {
  final Map<BoardPoint, FanoronaPiece?> board;
  final FanoronaPiece currentPlayer;
  final FanoronaPiece? winner;
  final FanoronaStatus status;
  final bool showHints;
  final bool isSolo;
  final bool isSequenceMandatory;

  // For sequences (multiple captures in one turn)
  final BoardPoint? capturingPiece;
  final List<BoardPoint> visitedPoints;
  final BoardPoint? lastDirection;

  const FanoronaGameState({
    required this.board,
    required this.currentPlayer,
    this.winner,
    required this.status,
    this.showHints = true,
    this.isSolo = false,
    this.isSequenceMandatory = false,
    this.capturingPiece,
    this.visitedPoints = const [],
    this.lastDirection,
  });

  factory FanoronaGameState.initial({
    bool showHints = true,
    bool isSolo = false,
    bool isSequenceMandatory = false,
  }) {
    return FanoronaGameState(
      board: _createInitialBoard(),
      currentPlayer: FanoronaPiece.white,
      status: FanoronaStatus.playing,
      showHints: showHints,
      isSolo: isSolo,
      isSequenceMandatory: isSequenceMandatory,
    );
  }

  static Map<BoardPoint, FanoronaPiece?> _createInitialBoard() {
    final Map<BoardPoint, FanoronaPiece?> board = {};
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 9; x++) {
        final point = BoardPoint(x, y);
        if (x == 4 && y == 2) {
          board[point] = null; // Center is empty
        } else if (y < 2 || (y == 2 && x < 4)) {
          board[point] = FanoronaPiece.white;
        } else {
          board[point] = FanoronaPiece.black;
        }
      }
    }
    return board;
  }

  FanoronaGameState copyWith({
    Map<BoardPoint, FanoronaPiece?>? board,
    FanoronaPiece? currentPlayer,
    FanoronaPiece? winner,
    FanoronaStatus? status,
    bool? showHints,
    bool? isSolo,
    bool? isSequenceMandatory,
    BoardPoint? capturingPiece,
    List<BoardPoint>? visitedPoints,
    BoardPoint? lastDirection,
    bool clearCapturingState = false,
  }) {
    return FanoronaGameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      status: status ?? this.status,
      showHints: showHints ?? this.showHints,
      isSolo: isSolo ?? this.isSolo,
      isSequenceMandatory: isSequenceMandatory ?? this.isSequenceMandatory,
      capturingPiece: clearCapturingState
          ? null
          : (capturingPiece ?? this.capturingPiece),
      visitedPoints: clearCapturingState
          ? const []
          : (visitedPoints ?? this.visitedPoints),
      lastDirection: clearCapturingState
          ? null
          : (lastDirection ?? this.lastDirection),
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentPlayer,
    winner,
    status,
    showHints,
    isSolo,
    isSequenceMandatory,
    capturingPiece,
    visitedPoints,
    lastDirection,
  ];
}
