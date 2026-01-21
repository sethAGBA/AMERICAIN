enum DamesColor { white, black }

enum DamesType { pawn, king }

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';

  bool get isValid => x >= 0 && x < 8 && y >= 0 && y < 8;
}

class DamesPiece {
  final DamesColor color;
  final DamesType type;

  const DamesPiece({required this.color, required this.type});

  DamesPiece copyWith({DamesType? type}) {
    return DamesPiece(color: color, type: type ?? this.type);
  }

  bool get isWhite => color == DamesColor.white;
  bool get isBlack => color == DamesColor.black;
  bool get isKing => type == DamesType.king;

  @override
  String toString() => '${color.name} ${type.name}';
}

enum DamesStatus { lobby, playing, finished }

class DamesState {
  final Map<Position, DamesPiece> board;
  final DamesColor currentTurn;
  final DamesStatus status;
  final Position? selectedPosition;
  final List<Position> validMoves;
  final DamesColor? winner;
  final bool isMultiplayer;
  final Position? lastJumpPosition;
  final bool isCaptureMandatory;
  final bool showHints;

  const DamesState({
    required this.board,
    required this.currentTurn,
    required this.status,
    this.selectedPosition,
    this.validMoves = const [],
    this.winner,
    this.isMultiplayer = false,
    this.lastJumpPosition,
    this.isCaptureMandatory = true,
    this.showHints = true,
  });

  DamesState copyWith({
    Map<Position, DamesPiece>? board,
    DamesColor? currentTurn,
    DamesStatus? status,
    Position? selectedPosition,
    List<Position>? validMoves,
    DamesColor? winner,
    bool? isMultiplayer,
    Position? lastJumpPosition,
    bool? isCaptureMandatory,
    bool? showHints,
    bool clearSelection = false,
  }) {
    return DamesState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      status: status ?? this.status,
      selectedPosition: clearSelection
          ? null
          : (selectedPosition ?? this.selectedPosition),
      validMoves: clearSelection ? [] : (validMoves ?? this.validMoves),
      winner: winner ?? this.winner,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      lastJumpPosition: clearSelection
          ? null
          : (lastJumpPosition ?? this.lastJumpPosition),
      isCaptureMandatory: isCaptureMandatory ?? this.isCaptureMandatory,
      showHints: showHints ?? this.showHints,
    );
  }
}
