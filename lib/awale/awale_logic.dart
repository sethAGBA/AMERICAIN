import 'models/awale_game_state.dart';
import 'models/awale_player.dart';
import 'models/awale_move.dart';
import 'awale_rules.dart';

/// Core game logic for Awale
class AwaleLogic {
  /// Check if a move is valid
  static bool isValidMove(AwaleGameState state, int pitIndex) {
    // Game must be in playing status
    if (state.status != GameStatus.playing) {
      return false;
    }

    // Pit must be in valid range
    if (pitIndex < 0 || pitIndex >= AwaleRules.totalPits) {
      return false;
    }

    // Pit must belong to current player
    final currentPlayer = state.currentPlayer;
    final playerPits = state.getPitIndicesForPlayer(currentPlayer);
    if (!playerPits.contains(pitIndex)) {
      return false;
    }

    // Pit must have seeds
    if (state.pits[pitIndex] == 0) {
      return false;
    }

    // Anti-starvation rule: cannot make a move that leaves opponent with no seeds
    if (!wouldLeaveOpponentWithSeeds(state, pitIndex)) {
      return false;
    }

    return true;
  }

  /// Get all valid moves for the current player
  static List<int> getAvailableMoves(AwaleGameState state) {
    final currentPlayer = state.currentPlayer;
    final playerPits = state.getPitIndicesForPlayer(currentPlayer);

    return playerPits.where((pit) => isValidMove(state, pit)).toList();
  }

  /// Execute a move and return the new game state
  static AwaleGameState executeMove(AwaleGameState state, int pitIndex) {
    if (!isValidMove(state, pitIndex)) {
      return state;
    }

    // Pick up all seeds from the selected pit
    final newPits = List<int>.from(state.pits);
    int seedsInHand = newPits[pitIndex];
    newPits[pitIndex] = 0;

    // Distribute seeds counter-clockwise
    int currentPit = pitIndex;
    while (seedsInHand > 0) {
      currentPit = (currentPit + 1) % AwaleRules.totalPits;

      // Skip the original pit if we come back to it
      if (currentPit == pitIndex) {
        continue;
      }

      newPits[currentPit]++;
      seedsInHand--;
    }

    // Check for captures
    final captureResult = checkCapture(
      newPits,
      currentPit,
      state.currentPlayer,
      state.opponentPlayer,
    );

    final newCaptures = Map<String, int>.from(state.captures);
    newCaptures[state.currentPlayer.id] =
        (newCaptures[state.currentPlayer.id] ?? 0) +
        captureResult.seedsCaptured;

    // Create move record
    final move = AwaleMove(
      playerId: state.currentPlayer.id,
      pitIndex: pitIndex,
      seedsDistributed: state.pits[pitIndex],
      seedsCaptured: captureResult.seedsCaptured,
      capturedFromPits: captureResult.capturedPits,
      timestamp: DateTime.now(),
    );

    // Update game state
    final newMoveHistory = List<AwaleMove>.from(state.moveHistory)..add(move);

    // Check win condition
    final winResult = checkWinCondition(captureResult.pits, newCaptures);

    return state.copyWith(
      pits: captureResult.pits,
      currentPlayerIndex: 1 - state.currentPlayerIndex,
      captures: newCaptures,
      moveHistory: newMoveHistory,
      status: winResult.isGameOver ? GameStatus.finished : GameStatus.playing,
      winnerId: winResult.winnerId,
    );
  }

  /// Check for captures after a move
  static CaptureResult checkCapture(
    List<int> pits,
    int lastPitIndex,
    AwalePlayer currentPlayer,
    AwalePlayer opponentPlayer,
  ) {
    final newPits = List<int>.from(pits);
    int totalCaptured = 0;
    final capturedPits = <int>[];

    // Get opponent's pit indices
    final opponentPits = pits
        .asMap()
        .entries
        .where((entry) {
          final pitIndex = entry.key;
          final opponentPitIndices = opponentPlayer.side == PlayerSide.top
              ? AwaleRules.topRowPits
              : AwaleRules.bottomRowPits;
          return opponentPitIndices.contains(pitIndex);
        })
        .map((e) => e.key)
        .toList();

    // Check if last pit is on opponent's side
    if (!opponentPits.contains(lastPitIndex)) {
      return CaptureResult(pits: newPits, seedsCaptured: 0, capturedPits: []);
    }

    // Capture backwards from last pit while conditions are met
    int currentPit = lastPitIndex;
    while (opponentPits.contains(currentPit)) {
      final seedCount = newPits[currentPit];

      // Can only capture if pit has 2 or 3 seeds
      if (!AwaleRules.canCapture(seedCount)) {
        break;
      }

      // Capture seeds
      totalCaptured += seedCount;
      capturedPits.add(currentPit);
      newPits[currentPit] = 0;

      // Move backwards (counter-clockwise)
      currentPit =
          (currentPit - 1 + AwaleRules.totalPits) % AwaleRules.totalPits;
    }

    // Grand Slam rule: cannot capture ALL opponent's seeds
    // If this capture would leave opponent with 0 seeds, undo it
    final opponentSeedsAfterCapture = opponentPits
        .map((pit) => newPits[pit])
        .fold(0, (sum, seeds) => sum + seeds);

    if (opponentSeedsAfterCapture == 0 && totalCaptured > 0) {
      // Undo all captures
      for (final pit in capturedPits) {
        newPits[pit] = pits[pit];
      }
      return CaptureResult(pits: newPits, seedsCaptured: 0, capturedPits: []);
    }

    return CaptureResult(
      pits: newPits,
      seedsCaptured: totalCaptured,
      capturedPits: capturedPits,
    );
  }

  /// Check if a move would leave the opponent with at least one seed
  static bool wouldLeaveOpponentWithSeeds(AwaleGameState state, int pitIndex) {
    // Simulate the move
    final newPits = List<int>.from(state.pits);
    int seedsInHand = newPits[pitIndex];
    newPits[pitIndex] = 0;

    // Distribute seeds
    int currentPit = pitIndex;
    while (seedsInHand > 0) {
      currentPit = (currentPit + 1) % AwaleRules.totalPits;
      if (currentPit == pitIndex) continue;
      newPits[currentPit]++;
      seedsInHand--;
    }

    // Simulate captures
    final captureResult = checkCapture(
      newPits,
      currentPit,
      state.currentPlayer,
      state.opponentPlayer,
    );

    // Check if opponent has any seeds left
    final opponentPits = state.getPitIndicesForPlayer(state.opponentPlayer);
    final opponentSeeds = opponentPits
        .map((pit) => captureResult.pits[pit])
        .fold(0, (sum, seeds) => sum + seeds);

    return opponentSeeds > 0;
  }

  /// Check win condition
  static WinResult checkWinCondition(
    List<int> pits,
    Map<String, int> captures,
  ) {
    // Check if any player has captured enough seeds to win
    for (final entry in captures.entries) {
      if (entry.value >= AwaleRules.seedsToWin) {
        return WinResult(isGameOver: true, winnerId: entry.key);
      }
    }

    // Check if all seeds are captured (no more on board)
    final totalSeedsOnBoard = pits.fold(0, (sum, seeds) => sum + seeds);
    if (totalSeedsOnBoard == 0) {
      // Game over, player with most captures wins
      final sortedCaptures = captures.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return WinResult(isGameOver: true, winnerId: sortedCaptures.first.key);
    }

    return WinResult(isGameOver: false);
  }

  /// Check if the game is in a stalemate (no valid moves for current player)
  static bool isStalemate(AwaleGameState state) {
    return getAvailableMoves(state).isEmpty;
  }

  /// Handle stalemate by giving remaining seeds to the player who can still move
  static AwaleGameState handleStalemate(AwaleGameState state) {
    final opponentPits = state.getPitIndicesForPlayer(state.opponentPlayer);
    final remainingSeeds = opponentPits
        .map((pit) => state.pits[pit])
        .fold(0, (sum, seeds) => sum + seeds);

    final newCaptures = Map<String, int>.from(state.captures);
    newCaptures[state.opponentPlayer.id] =
        (newCaptures[state.opponentPlayer.id] ?? 0) + remainingSeeds;

    final newPits = List<int>.from(state.pits);
    for (final pit in opponentPits) {
      newPits[pit] = 0;
    }

    final winResult = checkWinCondition(newPits, newCaptures);

    return state.copyWith(
      pits: newPits,
      captures: newCaptures,
      status: GameStatus.finished,
      winnerId: winResult.winnerId,
    );
  }
}

/// Result of a capture operation
class CaptureResult {
  final List<int> pits;
  final int seedsCaptured;
  final List<int> capturedPits;

  CaptureResult({
    required this.pits,
    required this.seedsCaptured,
    required this.capturedPits,
  });
}

/// Result of win condition check
class WinResult {
  final bool isGameOver;
  final String? winnerId;

  WinResult({required this.isGameOver, this.winnerId});
}
