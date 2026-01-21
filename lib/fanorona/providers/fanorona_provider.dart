import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fanorona_game_state.dart';

class FanoronaNotifier extends StateNotifier<FanoronaGameState> {
  FanoronaNotifier() : super(FanoronaGameState.initial());

  void startGame({
    bool showHints = true,
    bool isSolo = false,
    bool isSequenceMandatory = false,
  }) {
    state = FanoronaGameState.initial(
      showHints: showHints,
      isSolo: isSolo,
      isSequenceMandatory: isSequenceMandatory,
    );
  }

  bool get _isBotTurn =>
      state.isSolo && state.currentPlayer == FanoronaPiece.black;

  // Get all valid moves for a given point
  List<BoardPoint> getValidMoves(BoardPoint from) {
    if (state.status != FanoronaStatus.playing) return [];

    final piece = state.board[from];
    if (piece == null || piece != state.currentPlayer) return [];

    // If in a capture sequence, only the capturing piece can move
    if (state.capturingPiece != null && from != state.capturingPiece) {
      return [];
    }

    final List<BoardPoint> validMoves = [];
    final neighbors = _getNeighbors(from);

    for (var to in neighbors) {
      if (state.board[to] == null) {
        // If in a sequence, only capturing moves are allowed
        if (state.capturingPiece != null) {
          if (_getCaptures(from, to).isNotEmpty) {
            // Also check sequence restrictions: no point revisit, no same direction
            if (!state.visitedPoints.contains(to)) {
              final direction = to - from;
              if (direction != state.lastDirection) {
                validMoves.add(to);
              }
            }
          }
        } else {
          validMoves.add(to);
        }
      }
    }

    // MANDATORY CAPTURE RULE:
    // If ANY capture is possible on the board, the player MUST capture.
    // However, for Fanorona Tsiky (the first move), captures are not ALWAYS mandatory
    // depending on the rules variation. But in standard play, if captures are available,
    // only capture moves are valid.

    final allCaptureMoves = _getAllCaptureMoves();
    if (allCaptureMoves.isNotEmpty) {
      // Filter current point's moves to only those that capture
      final currentPointCaptures = validMoves
          .where((to) => _getCaptures(from, to).isNotEmpty)
          .toList();
      return currentPointCaptures;
    }

    return validMoves;
  }

  // Perform a move
  void movePiece(BoardPoint from, BoardPoint to) {
    final validMoves = getValidMoves(from);
    if (!validMoves.contains(to)) return;

    final captures = _getCaptures(from, to);
    final newBoard = Map<BoardPoint, FanoronaPiece?>.from(state.board);

    newBoard[to] = state.board[from];
    newBoard[from] = null;

    if (captures.isNotEmpty) {
      // Remove captured pieces
      for (var p in captures) {
        newBoard[p] = null;
      }

      // Check if another capture is possible from the new position
      final nextCaptures = _getPossibleCapturesFrom(
        to,
        lastDir: to - from,
        visited: [...state.visitedPoints, from],
      );

      if (nextCaptures.isNotEmpty) {
        // Continue sequence
        state = state.copyWith(
          board: newBoard,
          capturingPiece: to,
          visitedPoints: [...state.visitedPoints, from],
          lastDirection: to - from,
        );

        if (_isBotTurn) {
          Future.delayed(const Duration(milliseconds: 600), () {
            _makeBotMove();
          });
        }
      } else {
        _endTurn(newBoard);
      }
    } else {
      _endTurn(newBoard);
    }

    _checkWinCondition();
  }

  void skipSequence() {
    if (state.capturingPiece != null) {
      _endTurn(state.board);
    }
  }

  void _endTurn(Map<BoardPoint, FanoronaPiece?> newBoard) {
    state = state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == FanoronaPiece.white
          ? FanoronaPiece.black
          : FanoronaPiece.white,
      clearCapturingState: true,
    );

    if (_isBotTurn && state.status == FanoronaStatus.playing) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _makeBotMove();
      });
    }
  }

  void _makeBotMove() {
    if (state.status != FanoronaStatus.playing) return;
    if (!_isBotTurn) return;

    // 1. Get all pieces for current player
    final botPieces = state.board.entries
        .where((e) => e.value == state.currentPlayer)
        .map((e) => e.key)
        .toList();

    // 2. Identify all valid moves
    List<Map<String, dynamic>> allMoves = [];
    for (var from in botPieces) {
      final moves = getValidMoves(from);
      for (var to in moves) {
        final caps = _getCaptures(from, to);
        allMoves.add({'from': from, 'to': to, 'captureCount': caps.length});
      }
    }

    if (allMoves.isEmpty) {
      if (state.capturingPiece != null) {
        skipSequence();
      } else {
        // Bot is blocked? Should not really happen in Fanorona unless game over
        _checkWinCondition();
      }
      return;
    }

    // 3. Simple Greedy: pick move with most captures
    allMoves.sort((a, b) => b['captureCount'].compareTo(a['captureCount']));
    final bestMove = allMoves.first;

    movePiece(bestMove['from'], bestMove['to']);
  }

  // Helper: Get neighboring points based on connectivity
  List<BoardPoint> _getNeighbors(BoardPoint p) {
    final List<BoardPoint> neighbors = [];
    final directions = [
      const BoardPoint(0, 1),
      const BoardPoint(0, -1),
      const BoardPoint(1, 0),
      const BoardPoint(-1, 0),
    ];

    // Diagonal connections only for points where (x+y) is even
    if ((p.x + p.y) % 2 == 0) {
      directions.addAll([
        const BoardPoint(1, 1),
        const BoardPoint(1, -1),
        const BoardPoint(-1, 1),
        const BoardPoint(-1, -1),
      ]);
    }

    for (var d in directions) {
      final neighbor = p + d;
      if (neighbor.x >= 0 &&
          neighbor.x < 9 &&
          neighbor.y >= 0 &&
          neighbor.y < 5) {
        neighbors.add(neighbor);
      }
    }
    return neighbors;
  }

  // Helper: Get captured pieces for a move
  // Returns a list of points to be removed
  List<BoardPoint> _getCaptures(BoardPoint from, BoardPoint to) {
    final direction = to - from;

    // 1. Capture by Approach
    final List<BoardPoint> approachCaptures = [];
    var checkPoint = to + direction;
    while (checkPoint.x >= 0 &&
        checkPoint.x < 9 &&
        checkPoint.y >= 0 &&
        checkPoint.y < 5) {
      final p = state.board[checkPoint];
      if (p != null && p != state.currentPlayer) {
        approachCaptures.add(checkPoint);
        checkPoint += direction;
      } else {
        break;
      }
    }

    // 2. Capture by Withdrawal
    final List<BoardPoint> withdrawalCaptures = [];
    checkPoint = from - direction;
    while (checkPoint.x >= 0 &&
        checkPoint.x < 9 &&
        checkPoint.y >= 0 &&
        checkPoint.y < 5) {
      final p = state.board[checkPoint];
      if (p != null && p != state.currentPlayer) {
        withdrawalCaptures.add(checkPoint);
        checkPoint -= direction;
      } else {
        break;
      }
    }

    // If both are possible, the player MUST choose (handled in UI or by rule)
    // In many implementations, the player picks. For simplicity, we can return both
    // but the rule usually says you can only pick one line of capture.
    // Actually, Fanorona rule: "If both types are available from a move, only one can be chosen."
    // We'll return BOTH and wait for UI selection or just take Approach as priority for now.
    // IMPROVEMENT: Let's returned defined list and let logic handle it.

    return approachCaptures.isNotEmpty ? approachCaptures : withdrawalCaptures;
  }

  // Check if ANY point has a capture move
  List<BoardPoint> _getAllCaptureMoves() {
    final List<BoardPoint> captureMoves = [];
    state.board.forEach((point, piece) {
      if (piece == state.currentPlayer) {
        final neighbors = _getNeighbors(point);
        for (var to in neighbors) {
          if (state.board[to] == null && _getCaptures(point, to).isNotEmpty) {
            captureMoves.add(point);
          }
        }
      }
    });
    return captureMoves;
  }

  // For sequences: check if captures are possible from current point
  List<BoardPoint> _getPossibleCapturesFrom(
    BoardPoint from, {
    required BoardPoint lastDir,
    required List<BoardPoint> visited,
  }) {
    final neighbors = _getNeighbors(from);
    final List<BoardPoint> validNexts = [];

    for (var to in neighbors) {
      if (state.board[to] == null && !visited.contains(to)) {
        final dir = to - from;
        if (dir != lastDir && _getCaptures(from, to).isNotEmpty) {
          validNexts.add(to);
        }
      }
    }
    return validNexts;
  }

  void _checkWinCondition() {
    // Check both pieces counts
    final whitePieces = state.board.values
        .where((p) => p == FanoronaPiece.white)
        .length;
    final blackPieces = state.board.values
        .where((p) => p == FanoronaPiece.black)
        .length;

    if (whitePieces == 0) {
      state = state.copyWith(
        status: FanoronaStatus.won,
        winner: FanoronaPiece.black,
      );
    } else if (blackPieces == 0) {
      state = state.copyWith(
        status: FanoronaStatus.won,
        winner: FanoronaPiece.white,
      );
    }
  }
}

final fanoronaProvider =
    StateNotifierProvider<FanoronaNotifier, FanoronaGameState>((ref) {
      return FanoronaNotifier();
    });
