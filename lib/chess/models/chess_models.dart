import 'package:equatable/equatable.dart';

enum ChessColor {
  white,
  black;

  String toJson() => name;
  static ChessColor fromJson(String json) =>
      ChessColor.values.firstWhere((e) => e.name == json);
}

enum ChessPieceType {
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king;

  String toJson() => name;
  static ChessPieceType fromJson(String json) =>
      ChessPieceType.values.firstWhere((e) => e.name == json);
}

class ChessPiece extends Equatable {
  final ChessPieceType type;
  final ChessColor color;
  final bool hasMoved;

  const ChessPiece({
    required this.type,
    required this.color,
    this.hasMoved = false,
  });

  ChessPiece copyWith({bool? hasMoved}) {
    return ChessPiece(
      type: type,
      color: color,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'color': color.toJson(),
    'hasMoved': hasMoved,
  };

  factory ChessPiece.fromJson(Map<String, dynamic> json) => ChessPiece(
    type: ChessPieceType.fromJson(json['type']),
    color: ChessColor.fromJson(json['color']),
    hasMoved: json['hasMoved'] ?? false,
  );

  @override
  List<Object?> get props => [type, color, hasMoved];
}

class ChessSquare extends Equatable {
  final int rank; // 0-7 (rows)
  final int file; // 0-7 (columns)

  const ChessSquare(this.rank, this.file);

  bool get isValid => rank >= 0 && rank < 8 && file >= 0 && file < 8;

  @override
  List<Object?> get props => [rank, file];

  @override
  String toString() =>
      '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';

  String toJson() => '$rank,$file';

  factory ChessSquare.fromJson(String json) {
    final parts = json.split(',');
    return ChessSquare(int.parse(parts[0]), int.parse(parts[1]));
  }
}

enum ChessStatus {
  playing,
  check,
  checkmate,
  stalemate,
  draw;

  String toJson() => name;
  static ChessStatus fromJson(String json) =>
      ChessStatus.values.firstWhere((e) => e.name == json);
}

class ChessGameState extends Equatable {
  final Map<ChessSquare, ChessPiece?> board;
  final ChessColor currentPlayer;
  final ChessSquare? enPassantSquare;
  final ChessStatus status;
  final ChessSquare? selectedSquare;
  final List<ChessSquare> validMoves;
  final List<String> moveHistory;
  final ChessPieceType? promotionPiece; // When a pawn reaches the last rank

  final bool isSolo;

  const ChessGameState({
    required this.board,
    required this.currentPlayer,
    this.enPassantSquare,
    this.status = ChessStatus.playing,
    this.selectedSquare,
    this.validMoves = const [],
    this.moveHistory = const [],
    this.promotionPiece,
    this.isSolo = false,
  });

  factory ChessGameState.initial({bool isSolo = false}) {
    return ChessGameState(
      board: _createInitialBoard(),
      currentPlayer: ChessColor.white,
      isSolo: isSolo,
    );
  }

  static Map<ChessSquare, ChessPiece?> _createInitialBoard() {
    final Map<ChessSquare, ChessPiece?> board = {};

    // Helper to place pieces
    void place(int rank, int file, ChessPieceType type, ChessColor color) {
      board[ChessSquare(rank, file)] = ChessPiece(type: type, color: color);
    }

    // Pawns
    for (int i = 0; i < 8; i++) {
      place(1, i, ChessPieceType.pawn, ChessColor.white);
      place(6, i, ChessPieceType.pawn, ChessColor.black);
    }

    // Rooks
    place(0, 0, ChessPieceType.rook, ChessColor.white);
    place(0, 7, ChessPieceType.rook, ChessColor.white);
    place(7, 0, ChessPieceType.rook, ChessColor.black);
    place(7, 7, ChessPieceType.rook, ChessColor.black);

    // Knights
    place(0, 1, ChessPieceType.knight, ChessColor.white);
    place(0, 6, ChessPieceType.knight, ChessColor.white);
    place(7, 1, ChessPieceType.knight, ChessColor.black);
    place(7, 6, ChessPieceType.knight, ChessColor.black);

    // Bishops
    place(0, 2, ChessPieceType.bishop, ChessColor.white);
    place(0, 5, ChessPieceType.bishop, ChessColor.white);
    place(7, 2, ChessPieceType.bishop, ChessColor.black);
    place(7, 5, ChessPieceType.bishop, ChessColor.black);

    // Queens
    place(0, 3, ChessPieceType.queen, ChessColor.white);
    place(7, 3, ChessPieceType.queen, ChessColor.black);

    // Kings
    place(0, 4, ChessPieceType.king, ChessColor.white);
    place(7, 4, ChessPieceType.king, ChessColor.black);

    return board;
  }

  ChessGameState copyWith({
    Map<ChessSquare, ChessPiece?>? board,
    ChessColor? currentPlayer,
    ChessSquare? enPassantSquare,
    ChessStatus? status,
    ChessSquare? selectedSquare,
    List<ChessSquare>? validMoves,
    List<String>? moveHistory,
    ChessPieceType? promotionPiece,
    bool clearSelectedSquare = false,
    bool clearEnPassant = false,
    bool clearPromotion = false,
    bool? isSolo,
  }) {
    return ChessGameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      enPassantSquare: clearEnPassant
          ? null
          : (enPassantSquare ?? this.enPassantSquare),
      status: status ?? this.status,
      selectedSquare: clearSelectedSquare
          ? null
          : (selectedSquare ?? this.selectedSquare),
      validMoves: validMoves ?? this.validMoves,
      moveHistory: moveHistory ?? this.moveHistory,
      promotionPiece: clearPromotion
          ? null
          : (promotionPiece ?? this.promotionPiece),
      isSolo: isSolo ?? this.isSolo,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> boardJson = {};
    board.forEach((key, value) {
      if (value != null) {
        boardJson[key.toJson()] = value.toJson();
      }
    });

    return {
      'board': boardJson,
      'currentPlayer': currentPlayer.toJson(),
      'enPassantSquare': enPassantSquare?.toJson(),
      'status': status.toJson(),
      'moveHistory': moveHistory,
      'isSolo': isSolo,
    };
  }

  factory ChessGameState.fromJson(Map<String, dynamic> json) {
    final Map<ChessSquare, ChessPiece?> board = {};
    if (json['board'] != null) {
      (json['board'] as Map<String, dynamic>).forEach((key, value) {
        board[ChessSquare.fromJson(key)] = ChessPiece.fromJson(
          value as Map<String, dynamic>,
        );
      });
    }

    // Fill missing squares with null to ensure full board
    for (int r = 0; r < 8; r++) {
      for (int f = 0; f < 8; f++) {
        final sq = ChessSquare(r, f);
        if (!board.containsKey(sq)) {
          board[sq] = null;
        }
      }
    }

    return ChessGameState(
      board: board,
      currentPlayer: ChessColor.fromJson(json['currentPlayer']),
      enPassantSquare: json['enPassantSquare'] != null
          ? ChessSquare.fromJson(json['enPassantSquare'])
          : null,
      status: ChessStatus.fromJson(json['status']),
      moveHistory: List<String>.from(json['moveHistory'] ?? []),
      isSolo: json['isSolo'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentPlayer,
    enPassantSquare,
    status,
    selectedSquare,
    validMoves,
    moveHistory,
    promotionPiece,
    isSolo,
  ];
}
