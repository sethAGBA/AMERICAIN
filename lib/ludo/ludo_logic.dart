import 'models/ludo_piece.dart';
import 'models/ludo_player.dart';

class LudoLogic {
  // Total spaces on the main track usually 52
  static const int mainTrackLength = 52;
  static const int goalLength = 5;

  // Starting positions for each color (indices on the main track)
  static final Map<LudoColor, int> startPositions = {
    LudoColor.red: 0,
    LudoColor.green: 13,
    LudoColor.yellow: 26,
    LudoColor.blue: 39,
  };

  // Safe spots (Globe/Star) indices relative to board (0-51)
  // Indices 0, 13, 26, 39 are start positions.
  // Per rule: "Un pion sortant peut être mangé même sur sa case de départ",
  // they are NOT safe spots.
  static final List<int> safeSpots = [8, 21, 34, 47];

  /// Checks if a move is valid for the given piece and dice roll
  static bool isValidMove(
    LudoPiece piece,
    int roll, {
    List<LudoPiece>? allPieces,
  }) {
    // Basic checks
    if (roll < 1 || roll > 12) return false;
    if (piece.state == PieceState.goal) return false;

    // Check path blocking first if context provided
    if (allPieces != null &&
        piece.state == PieceState.track &&
        _isPathBlocked(piece, roll, allPieces)) {
      return false;
    }

    if (piece.state == PieceState.home) {
      if (roll != 6) return false;
      if (allPieces != null) {
        final startPos = startPositions[piece.color];
        if (startPos == null) return false;
        final opponentBridgeCount = allPieces
            .where(
              (p) =>
                  p.state == PieceState.track &&
                  p.position == startPos &&
                  p.color != piece.color,
            )
            .length;
        if (opponentBridgeCount >= 2) {
          return false; // Blocked by bridge at exit
        }
      }
      return true;
    }

    if (piece.state == PieceState.inJail) {
      return roll == 6; // Buy back with 6
    }

    if (piece.state == PieceState.goal) {
      return false;
    }

    if (piece.state == PieceState.track) {
      // 1. Check path blocking
      if (allPieces != null && _isPathBlocked(piece, roll, allPieces)) {
        return false;
      }

      // 2. Check for goal overshoot
      final startPos = startPositions[piece.color] ?? 0;
      int relativePos =
          (piece.position - startPos + mainTrackLength) % mainTrackLength;
      int newRelativePos = relativePos + roll;
      if (newRelativePos > 56) return false; // Overshot goal

      return true;
    }

    if (piece.state == PieceState.goalStretch) {
      // Must not overshoot 6 (Assuming goal is at index 5)
      // Current position 0-4. Goal is at virtual 5.
      // E.g. at pos 4, need 1 to win. Roll 2 is invalid.
      return (piece.position + roll) <= 5;
    }

    return false;
  }

  /// Calculates the new state and position for a piece
  /// Returns a COPY of the piece with updated fields
  static LudoPiece movePiece(LudoPiece piece, int roll) {
    if (piece.state == PieceState.home) {
      // Exit home
      return piece.copyWith(
        state: PieceState.track,
        position: startPositions[piece.color] ?? 0,
      );
    }

    if (piece.state == PieceState.inJail) {
      // Return to home (bought back)
      return piece.copyWith(
        state: PieceState.home,
        position: 0,
        capturedBy: null, // Clear capturer
      );
    }

    if (piece.state == PieceState.goalStretch) {
      final newPos = piece.position + roll;
      if (newPos == 5) {
        return piece.copyWith(state: PieceState.goal, position: 5); // Finished
      } else {
        return piece.copyWith(position: newPos);
      }
    }

    // Main Track Movement
    // This requires calculating position relative to player's start to detect goal entry
    final startPos = startPositions[piece.color] ?? 0;
    // Calculate distance traveled so far relative to start
    // If piece.pos >= start, dist = pos - start
    // If piece.pos < start (wrapped), dist = (52 - start) + pos
    int relativePos =
        (piece.position - startPos + mainTrackLength) % mainTrackLength;

    int newRelativePos = relativePos + roll;

    // Check if entering goal stretch
    // Each player travels 51 squares then enters goal?
    // Usually 50 squares + 1 to enter goal.
    // Let's say track length is 52. One lap is 52.
    // Entry to goal is just before start position.

    if (newRelativePos >= 51) {
      // ENTER GOAL STRETCH
      int surplus = newRelativePos - 51; // 0 means first square of goal

      if (surplus > 5) {
        // Overshot goal entirely from track (rare but possible if logic permits)
        // Usually you bounce back or move is invalid.
        // For now, treat as invalid (should check isValidMove first)
        return piece;
      }

      if (surplus == 5) {
        return piece.copyWith(state: PieceState.goal, position: 5);
      }

      return piece.copyWith(state: PieceState.goalStretch, position: surplus);
    }

    // Still on track
    int newBoardPos = (startPos + newRelativePos) % mainTrackLength;
    return piece.copyWith(position: newBoardPos);
  }

  /// Checks if `piece` lands on `target` and can capture it
  static bool canCapture(LudoPiece piece, LudoPiece target) {
    if (piece.color == target.color) return false; // Cannot capture own
    if (piece.state != PieceState.track || target.state != PieceState.track) {
      return false;
    }
    if (piece.position != target.position) return false;
    if (safeSpots.contains(target.position)) return false; // Safe spot
    return true;
  }

  static bool _isPathBlocked(
    LudoPiece piece,
    int roll,
    List<LudoPiece> allPieces,
  ) {
    // Only applies to pieces on the main track
    if (piece.state != PieceState.track) return false;

    // Check each step 1..roll
    for (int i = 1; i <= roll; i++) {
      int checkPos = (piece.position + i) % mainTrackLength;

      // Count opponent pieces at this position
      int obstacleCount = allPieces
          .where(
            (p) =>
                p.state == PieceState.track &&
                p.position == checkPos &&
                p.color != piece.color,
          )
          .length;

      if (obstacleCount >= 2) {
        return true; // Blocked by bridge
      }
    }
    return false;
  }

  /// Returns a list of track positions where the current player HAS a bridge
  /// that MUST be broken according to the "Mandatory Unblocking" rule.
  static List<int> getMandatoryUnblockPositions(
    List<LudoPlayer> players,
    int currentPlayerIndex,
  ) {
    final currentPlayer = players[currentPlayerIndex];
    final unblockPositions = <int>[];

    // Find all bridges for current player
    final bridgePositions = <int, int>{};
    for (var p in currentPlayer.pieces) {
      if (p.state == PieceState.track) {
        bridgePositions[p.position] = (bridgePositions[p.position] ?? 0) + 1;
      }
    }

    final activeBridges = bridgePositions.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();

    if (activeBridges.isEmpty) return [];

    // Check each opponent to see if they are blocked by one of these bridges
    for (int i = 0; i < players.length; i++) {
      if (i == currentPlayerIndex) continue;
      final opponent = players[i];

      // Condition 1: Opponent has 3 pieces in goal
      final piecesInGoal = opponent.pieces
          .where((p) => p.state == PieceState.goal)
          .length;
      if (piecesInGoal < 3) continue;

      // Condition 2: Opponent's 4th piece is directly behind a current player's bridge
      final remainingPieces = opponent.pieces
          .where((p) => p.state != PieceState.goal)
          .toList();
      if (remainingPieces.length != 1) continue;
      final fourthPiece = remainingPieces.first;

      if (fourthPiece.state != PieceState.track) continue;

      final nextPos = (fourthPiece.position + 1) % mainTrackLength;

      if (activeBridges.contains(nextPos)) {
        // Condition 4: Blocker is NOT himself blocked by another player (Bridge Chain)
        final afterBridgePos = (nextPos + 1) % mainTrackLength;
        bool blockerIsBlocked = false;

        for (int j = 0; j < players.length; j++) {
          if (j == currentPlayerIndex) continue; // Another player
          final otherPlayer = players[j];
          int piecesAtAfter = otherPlayer.pieces
              .where(
                (p) =>
                    p.state == PieceState.track && p.position == afterBridgePos,
              )
              .length;
          if (piecesAtAfter >= 2) {
            blockerIsBlocked = true;
            break;
          }
        }

        if (!blockerIsBlocked) {
          unblockPositions.add(nextPos);
        }
      }
    }

    return unblockPositions;
  }
}
