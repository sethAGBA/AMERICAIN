import 'package:equatable/equatable.dart';

enum OthelloPiece {
  black,
  white;

  String toJson() => name;
  static OthelloPiece fromJson(String json) =>
      OthelloPiece.values.firstWhere((e) => e.name == json);

  OthelloPiece get opponent =>
      this == OthelloPiece.black ? OthelloPiece.white : OthelloPiece.black;
}

class OthelloSquare extends Equatable {
  final int row;
  final int col;

  const OthelloSquare(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  @override
  List<Object?> get props => [row, col];

  String toJson() => '$row,$col';
  factory OthelloSquare.fromJson(String json) {
    final parts = json.split(',');
    return OthelloSquare(int.parse(parts[0]), int.parse(parts[1]));
  }
}

enum OthelloStatus { playing, finished }

class OthelloGameState extends Equatable {
  final Map<OthelloSquare, OthelloPiece?> board;
  final OthelloPiece currentTurn;
  final OthelloStatus status;
  final bool isSolo;
  final List<String> moveHistory;
  final int whiteCount;
  final int blackCount;

  const OthelloGameState({
    required this.board,
    required this.currentTurn,
    this.status = OthelloStatus.playing,
    this.isSolo = false,
    this.moveHistory = const [],
    this.whiteCount = 2,
    this.blackCount = 2,
  });

  factory OthelloGameState.initial({bool isSolo = false}) {
    final Map<OthelloSquare, OthelloPiece?> board = {};
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        board[OthelloSquare(r, c)] = null;
      }
    }

    // Starting position
    board[const OthelloSquare(3, 3)] = OthelloPiece.white;
    board[const OthelloSquare(3, 4)] = OthelloPiece.black;
    board[const OthelloSquare(4, 3)] = OthelloPiece.black;
    board[const OthelloSquare(4, 4)] = OthelloPiece.white;

    return OthelloGameState(
      board: board,
      currentTurn: OthelloPiece.black, // Black always starts
      isSolo: isSolo,
    );
  }

  OthelloGameState copyWith({
    Map<OthelloSquare, OthelloPiece?>? board,
    OthelloPiece? currentTurn,
    OthelloStatus? status,
    bool? isSolo,
    List<String>? moveHistory,
    int? whiteCount,
    int? blackCount,
  }) {
    return OthelloGameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      status: status ?? this.status,
      isSolo: isSolo ?? this.isSolo,
      moveHistory: moveHistory ?? this.moveHistory,
      whiteCount: whiteCount ?? this.whiteCount,
      blackCount: blackCount ?? this.blackCount,
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
      'currentTurn': currentTurn.toJson(),
      'status': status.name,
      'isSolo': isSolo,
      'moveHistory': moveHistory,
      'whiteCount': whiteCount,
      'blackCount': blackCount,
    };
  }

  factory OthelloGameState.fromJson(Map<String, dynamic> json) {
    final Map<OthelloSquare, OthelloPiece?> board = {};
    // Initialize empty board
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        board[OthelloSquare(r, c)] = null;
      }
    }

    if (json['board'] != null) {
      (json['board'] as Map<String, dynamic>).forEach((key, value) {
        board[OthelloSquare.fromJson(key)] = OthelloPiece.fromJson(value);
      });
    }

    return OthelloGameState(
      board: board,
      currentTurn: OthelloPiece.fromJson(json['currentTurn']),
      status: OthelloStatus.values.firstWhere((e) => e.name == json['status']),
      isSolo: json['isSolo'] ?? false,
      moveHistory: List<String>.from(json['moveHistory'] ?? []),
      whiteCount: json['whiteCount'] ?? 2,
      blackCount: json['blackCount'] ?? 2,
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentTurn,
    status,
    isSolo,
    moveHistory,
    whiteCount,
    blackCount,
  ];
}
