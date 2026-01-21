import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dames_models.dart';
import '../../services/sound_service.dart';

final damesProvider = StateNotifierProvider<DamesNotifier, DamesState>((ref) {
  return DamesNotifier();
});

class DamesNotifier extends StateNotifier<DamesState> {
  DamesNotifier()
    : super(
        const DamesState(
          board: {},
          currentTurn: DamesColor.white,
          status: DamesStatus.lobby,
        ),
      );

  void setupGame({
    required bool isMultiplayer,
    bool isCaptureMandatory = true,
    bool showHints = true,
  }) {
    Map<Position, DamesPiece> board = {};

    // Initial board setup (8x8)
    // White pieces at bottom (rows 5, 6, 7)
    // Black pieces at top (rows 0, 1, 2)
    // Pieces only on dark squares (where x+y is odd)
    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < 8; x++) {
        if ((x + y) % 2 != 0) {
          board[Position(x, y)] = const DamesPiece(
            color: DamesColor.black,
            type: DamesType.pawn,
          );
        }
      }
    }

    for (int y = 5; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        if ((x + y) % 2 != 0) {
          board[Position(x, y)] = const DamesPiece(
            color: DamesColor.white,
            type: DamesType.pawn,
          );
        }
      }
    }

    state = DamesState(
      board: board,
      currentTurn: DamesColor.white,
      status: DamesStatus.playing,
      isMultiplayer: isMultiplayer,
      isCaptureMandatory: isCaptureMandatory,
      showHints: showHints,
    );
  }

  void selectPiece(Position pos) {
    if (state.status != DamesStatus.playing) return;

    // If we're in middle of a jump sequence, can only select the jumping piece
    if (state.lastJumpPosition != null && state.lastJumpPosition != pos) return;

    final piece = state.board[pos];
    if (piece == null || piece.color != state.currentTurn) {
      state = state.copyWith(clearSelection: true);
      return;
    }

    List<Position> moves = _getValidMoves(pos);
    state = state.copyWith(selectedPosition: pos, validMoves: moves);
  }

  void movePiece(Position to) {
    if (state.selectedPosition == null || !state.validMoves.contains(to))
      return;

    final from = state.selectedPosition;
    if (from == null) return;

    final piece = state.board[from];
    if (piece == null) return;
    final Map<Position, DamesPiece> newBoard = Map.from(state.board);

    // Is it a jump?
    bool isJump = (to.x - from.x).abs() > 1;
    bool hasCaptured = false;

    if (isJump) {
      // Capture the piece in between
      // For kings, we need to find the jumped piece on the diagonal
      int dx = (to.x - from.x).sign;
      int dy = (to.y - from.y).sign;
      Position current = Position(from.x + dx, from.y + dy);
      while (current != to) {
        if (newBoard.containsKey(current)) {
          newBoard.remove(current);
          hasCaptured = true;
          break;
        }
        current = Position(current.x + dx, current.y + dy);
      }
    }

    // Move the piece
    newBoard.remove(from);

    // Check for promotion
    DamesPiece movedPiece = piece;
    bool promoted = false;
    if (piece.type == DamesType.pawn) {
      if ((piece.isWhite && to.y == 0) || (piece.isBlack && to.y == 7)) {
        movedPiece = piece.copyWith(type: DamesType.king);
        promoted = true;
      }
    }
    newBoard[to] = movedPiece;

    SoundService.playDominoPlay(); // Clac!

    // Check for multiple jumps
    if (hasCaptured && !promoted) {
      List<Position> multiJumps = _getJumpsOnly(to, board: newBoard);
      if (multiJumps.isNotEmpty) {
        state = state.copyWith(
          board: newBoard,
          selectedPosition: to,
          validMoves: multiJumps,
          lastJumpPosition: to,
        );

        // If bot, automatically trigger next move
        if (!state.isMultiplayer && state.currentTurn == DamesColor.black) {
          Future.delayed(const Duration(milliseconds: 600), () {
            _makeBotMove();
          });
        }
        return;
      }
    }

    // End turn
    state = state.copyWith(board: newBoard, clearSelection: true);

    _nextTurn();
    _checkGameOver();
  }

  void _nextTurn() {
    state = state.copyWith(
      currentTurn: state.currentTurn == DamesColor.white
          ? DamesColor.black
          : DamesColor.white,
    );

    if (!state.isMultiplayer && state.currentTurn == DamesColor.black) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _makeBotMove();
      });
    }
  }

  List<Position> _getValidMoves(
    Position pos, {
    Map<Position, DamesPiece>? board,
  }) {
    final effectiveBoard = board ?? state.board;

    // If we're in middle of a jump sequence, only the jumping piece is valid
    if (state.lastJumpPosition != null && state.lastJumpPosition != pos) {
      return [];
    }

    // If a jump is possible for ANY piece, it's mandatory
    // This is the standard rule for checkers
    List<Position> jumps = _getJumpsOnly(pos, board: effectiveBoard);

    // Check if ANY of our pieces can jump
    bool anyJumpPossible = false;
    for (var entry in effectiveBoard.entries) {
      if (entry.value.color == state.currentTurn) {
        if (_getJumpsOnly(entry.key, board: effectiveBoard).isNotEmpty) {
          anyJumpPossible = true;
          break;
        }
      }
    }

    if (state.isCaptureMandatory && anyJumpPossible) {
      return jumps;
    }

    // Regular moves (only if no jumps are possible)
    return jumps + _getRegularMovesOnly(pos, board: effectiveBoard);
  }

  List<Position> _getRegularMovesOnly(
    Position pos, {
    Map<Position, DamesPiece>? board,
  }) {
    final effectiveBoard = board ?? state.board;
    final piece = effectiveBoard[pos];
    if (piece == null) return [];

    List<Position> moves = [];

    List<Position> directions = [];
    if (piece.isKing) {
      directions = [
        const Position(1, 1),
        const Position(1, -1),
        const Position(-1, 1),
        const Position(-1, -1),
      ];
    } else {
      int dy = piece.isWhite ? -1 : 1;
      directions = [Position(1, dy), Position(-1, dy)];
    }

    for (var dir in directions) {
      if (piece.isKing) {
        // Slide as far as possible
        Position current = Position(pos.x + dir.x, pos.y + dir.y);
        while (current.isValid && !effectiveBoard.containsKey(current)) {
          moves.add(current);
          current = Position(current.x + dir.x, current.y + dir.y);
        }
      } else {
        Position target = Position(pos.x + dir.x, pos.y + dir.y);
        if (target.isValid && !effectiveBoard.containsKey(target)) {
          moves.add(target);
        }
      }
    }
    return moves;
  }

  List<Position> _getJumpsOnly(
    Position pos, {
    Map<Position, DamesPiece>? board,
  }) {
    final effectiveBoard = board ?? state.board;
    final piece = effectiveBoard[pos];
    if (piece == null) return [];

    List<Position> jumps = [];

    List<Position> directions = [
      const Position(1, 1),
      const Position(1, -1),
      const Position(-1, 1),
      const Position(-1, -1),
    ];

    for (var dir in directions) {
      if (piece.isKing) {
        // Slide until we hit something
        Position current = Position(pos.x + dir.x, pos.y + dir.y);
        while (current.isValid && !effectiveBoard.containsKey(current)) {
          current = Position(current.x + dir.x, current.y + dir.y);
        }

        // If we hit an enemy piece, check if space behind is free
        if (current.isValid && effectiveBoard[current]?.color != piece.color) {
          Position landing = Position(current.x + dir.x, current.y + dir.y);
          while (landing.isValid && !effectiveBoard.containsKey(landing)) {
            jumps.add(landing);
            landing = Position(landing.x + dir.x, landing.y + dir.y);
          }
        }
      } else {
        // Must jump over opponent
        Position enemy = Position(pos.x + dir.x, pos.y + dir.y);
        Position landing = Position(pos.x + dir.x * 2, pos.y + dir.y * 2);

        if (landing.isValid &&
            effectiveBoard.containsKey(enemy) &&
            effectiveBoard[enemy]?.color != piece.color &&
            !effectiveBoard.containsKey(landing)) {
          jumps.add(landing);
        }
      }
    }
    return jumps;
  }

  void _checkGameOver() {
    // Check if current player has any moves
    bool hasMoves = false;
    for (var entry in state.board.entries) {
      if (entry.value.color == state.currentTurn) {
        if (_getValidMoves(entry.key).isNotEmpty) {
          hasMoves = true;
          break;
        }
      }
    }

    if (!hasMoves) {
      state = state.copyWith(
        status: DamesStatus.finished,
        winner: state.currentTurn == DamesColor.white
            ? DamesColor.black
            : DamesColor.white,
      );
    }
  }

  void _makeBotMove() {
    if (state.status != DamesStatus.playing) return;

    // Very simple bot logic:
    // 1. Mandatory jumps first
    // 2. Evaluate all moves and pick best (greedy)
    List<Map<String, dynamic>> allPossibleMoves = [];

    for (var entry in state.board.entries) {
      if (entry.value.color == DamesColor.black) {
        List<Position> moves = _getValidMoves(entry.key);
        for (var m in moves) {
          allPossibleMoves.add({'from': entry.key, 'to': m});
        }
      }
    }

    if (allPossibleMoves.isEmpty) return;

    // Priority to jumps
    var jumps = allPossibleMoves
        .where((m) => (m['to'].x - m['from'].x).abs() > 1)
        .toList();
    var finalMove =
        (jumps.isNotEmpty ? jumps : allPossibleMoves)[math.Random().nextInt(
          jumps.isNotEmpty ? jumps.length : allPossibleMoves.length,
        )];

    selectPiece(finalMove['from']);
    Future.delayed(const Duration(milliseconds: 300), () {
      movePiece(finalMove['to']);
    });
  }

  void resetGame() {
    setupGame(
      isMultiplayer: state.isMultiplayer,
      isCaptureMandatory: state.isCaptureMandatory,
      showHints: state.showHints,
    );
  }
}
