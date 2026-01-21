import 'package:equatable/equatable.dart';

enum DaraPiece {
  player1, // Usually White
  player2; // Usually Black

  String toJson() => name;
  static DaraPiece fromJson(String json) =>
      DaraPiece.values.firstWhere((e) => e.name == json);

  DaraPiece get opponent =>
      this == DaraPiece.player1 ? DaraPiece.player2 : DaraPiece.player1;
}

enum DaraPhase {
  drop, // Placing pieces (12 each)
  move, // Moving pieces after all dropped
  capture, // State after forming a 3-in-a-row, waiting to remove opponent piece
}

class DaraSquare extends Equatable {
  final int row;
  final int col;

  const DaraSquare(this.row, this.col);

  bool get isValid => row >= 0 && row < 5 && col >= 0 && col < 6;

  @override
  List<Object?> get props => [row, col];

  String toJson() => '$row,$col';
  factory DaraSquare.fromJson(String json) {
    final parts = json.split(',');
    return DaraSquare(int.parse(parts[0]), int.parse(parts[1]));
  }
}

enum DaraStatus { playing, finished }

class DaraGameState extends Equatable {
  final Map<DaraSquare, DaraPiece?> board;
  final DaraPiece currentTurn;
  final DaraPhase phase;
  final DaraStatus status;
  final bool isSolo;
  final int p1PiecesToDrop;
  final int p2PiecesToDrop;
  final int p1Score;
  final int p2Score;
  final DaraSquare? lastDrop; // To help with 3-in-a-row check during drop
  final List<String> moveHistory;

  const DaraGameState({
    required this.board,
    required this.currentTurn,
    this.phase = DaraPhase.drop,
    this.status = DaraStatus.playing,
    this.isSolo = false,
    this.p1PiecesToDrop = 12,
    this.p2PiecesToDrop = 12,
    this.p1Score = 12,
    this.p2Score = 12,
    this.lastDrop,
    this.moveHistory = const [],
  });

  factory DaraGameState.initial({bool isSolo = false}) {
    final Map<DaraSquare, DaraPiece?> board = {};
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 6; c++) {
        board[DaraSquare(r, c)] = null;
      }
    }

    return DaraGameState(
      board: board,
      currentTurn: DaraPiece.player1,
      isSolo: isSolo,
    );
  }

  DaraGameState copyWith({
    Map<DaraSquare, DaraPiece?>? board,
    DaraPiece? currentTurn,
    DaraPhase? phase,
    DaraStatus? status,
    bool? isSolo,
    int? p1PiecesToDrop,
    int? p2PiecesToDrop,
    int? p1Score,
    int? p2Score,
    DaraSquare? lastDrop,
    List<String>? moveHistory,
    bool clearLastDrop = false,
  }) {
    return DaraGameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      isSolo: isSolo ?? this.isSolo,
      p1PiecesToDrop: p1PiecesToDrop ?? this.p1PiecesToDrop,
      p2PiecesToDrop: p2PiecesToDrop ?? this.p2PiecesToDrop,
      p1Score: p1Score ?? this.p1Score,
      p2Score: p2Score ?? this.p2Score,
      lastDrop: clearLastDrop ? null : (lastDrop ?? this.lastDrop),
      moveHistory: moveHistory ?? this.moveHistory,
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
      'phase': phase.name,
      'status': status.name,
      'isSolo': isSolo,
      'p1PiecesToDrop': p1PiecesToDrop,
      'p2PiecesToDrop': p2PiecesToDrop,
      'p1Score': p1Score,
      'p2Score': p2Score,
      'moveHistory': moveHistory,
    };
  }

  factory DaraGameState.fromJson(Map<String, dynamic> json) {
    final Map<DaraSquare, DaraPiece?> board = {};
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 6; c++) {
        board[DaraSquare(r, c)] = null;
      }
    }

    if (json['board'] != null) {
      (json['board'] as Map<String, dynamic>).forEach((key, value) {
        board[DaraSquare.fromJson(key)] = DaraPiece.fromJson(value);
      });
    }

    return DaraGameState(
      board: board,
      currentTurn: DaraPiece.fromJson(json['currentTurn'] ?? 'player1'),
      phase: DaraPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => DaraPhase.drop,
      ),
      status: DaraStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DaraStatus.playing,
      ),
      isSolo: json['isSolo'] ?? false,
      p1PiecesToDrop: json['p1PiecesToDrop'] ?? 12,
      p2PiecesToDrop: json['p2PiecesToDrop'] ?? 12,
      p1Score: json['p1Score'] ?? 12,
      p2Score: json['p2Score'] ?? 12,
      moveHistory: List<String>.from(json['moveHistory'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentTurn,
    phase,
    status,
    isSolo,
    p1PiecesToDrop,
    p2PiecesToDrop,
    p1Score,
    p2Score,
    lastDrop,
    moveHistory,
  ];
}
