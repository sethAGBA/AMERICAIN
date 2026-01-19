import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/awale_game_state.dart';
import '../models/awale_player.dart';
import '../awale_logic.dart';
import '../../services/sound_service.dart';

/// Provider for current player ID
final awaleCurrentPlayerIdProvider = StateProvider<String?>((ref) => null);

/// Provider for Awale game state
final awaleGameStateProvider =
    StateNotifierProvider<AwaleGameNotifier, AwaleGameState?>(
      (ref) => AwaleGameNotifier(ref),
    );

/// Notifier for Awale game state management
class AwaleGameNotifier extends StateNotifier<AwaleGameState?> {
  final Ref ref;
  Timer? _botMoveTimer;

  AwaleGameNotifier(this.ref) : super(null);

  /// Create a new game
  void createGame({
    required String gameId,
    required String playerName,
    required String playerId,
    bool vsBot = false,
    GameMode mode = GameMode.local,
  }) {
    final player1 = AwalePlayer(
      id: playerId,
      name: playerName,
      side: PlayerSide.bottom,
    );

    final player2 = AwalePlayer(
      id: vsBot ? 'bot' : 'player2',
      name: vsBot ? 'Bot' : 'Joueur 2',
      isBot: vsBot,
      side: PlayerSide.top,
    );

    state = AwaleGameState.initial(
      gameId: gameId,
      players: [player1, player2],
      hostId: playerId,
      mode: mode,
    );

    ref.read(awaleCurrentPlayerIdProvider.notifier).state = playerId;
  }

  /// Join an existing game
  void joinGame({
    required String gameId,
    required String playerName,
    required String playerId,
  }) {
    // This would be implemented with backend integration
    // For now, just create a local game
    createGame(
      gameId: gameId,
      playerName: playerName,
      playerId: playerId,
      mode: GameMode.online,
    );
  }

  /// Start the game
  void startGame() {
    if (state == null) return;

    state = state!.copyWith(status: GameStatus.playing);

    // If first player is bot, trigger bot move
    if (state!.currentPlayer.isBot) {
      _scheduleBotMove();
    }
  }

  /// Make a move
  Future<void> makeMove(int pitIndex) async {
    if (state == null) return;

    // Validate move
    if (!AwaleLogic.isValidMove(state!, pitIndex)) {
      // Play invalid move sound (using Ludo bridge sound)
      SoundService.playLudoBridge();
      return;
    }

    // Get number of seeds to distribute
    int seedsToDistribute = state!.pits[pitIndex];

    // Play seed drop sound repeatedly to simulate sowing
    _playSowingSounds(seedsToDistribute);

    // Execute move
    final newState = AwaleLogic.executeMove(state!, pitIndex);

    // Play capture sound if seeds were captured
    final lastMove = newState.moveHistory.last;
    if (lastMove.seedsCaptured > 0) {
      // Small delay to let sowing finish
      await Future.delayed(const Duration(milliseconds: 300));

      if (lastMove.seedsCaptured >= 6) {
        // Big capture!
        SoundService.playLudoDoubleSix();
      } else {
        SoundService.playAwaleCapture();
      }
    }

    state = newState;

    // In local mode, update the current player ID provider to match the new current player
    // This allows both players to click on the pits when it's their turn
    if (state!.mode == GameMode.local) {
      ref.read(awaleCurrentPlayerIdProvider.notifier).state =
          state!.currentPlayer.id;
    }

    // Check if game is over
    if (state!.status == GameStatus.finished) {
      await Future.delayed(const Duration(milliseconds: 500));
      _handleGameEnd();
      return;
    }

    // Check for stalemate
    if (AwaleLogic.isStalemate(state!)) {
      state = AwaleLogic.handleStalemate(state!);
      // Update ID again after stalemate resolution
      if (state!.mode == GameMode.local) {
        ref.read(awaleCurrentPlayerIdProvider.notifier).state = state!.winnerId;
      }
      _handleGameEnd();
      return;
    }

    // If turn changed and next is bot, schedule move
    if (state!.currentPlayer.isBot) {
      _scheduleBotMove();
    }
  }

  /// Play sowing sounds with a small delay between each
  void _playSowingSounds(int count) async {
    for (int i = 0; i < count; i++) {
      SoundService.playAwaleSeedDrop();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Schedule a bot move with delay for realism
  void _scheduleBotMove() {
    _botMoveTimer?.cancel();
    _botMoveTimer = Timer(const Duration(milliseconds: 1500), () {
      _executeBotMove();
    });
  }

  /// Execute bot move using AI
  void _executeBotMove() {
    if (state == null || !state!.currentPlayer.isBot) return;

    final botMove = _getBotMove(state!, difficulty: BotDifficulty.medium);
    if (botMove != null) {
      makeMove(botMove);
    }
  }

  /// Get bot move using minimax algorithm
  int? _getBotMove(AwaleGameState state, {required BotDifficulty difficulty}) {
    final availableMoves = AwaleLogic.getAvailableMoves(state);
    if (availableMoves.isEmpty) return null;

    switch (difficulty) {
      case BotDifficulty.easy:
        // Random move
        return availableMoves[Random().nextInt(availableMoves.length)];

      case BotDifficulty.medium:
        // Greedy: choose move with most immediate captures
        return _getGreedyMove(state, availableMoves);

      case BotDifficulty.hard:
        // Minimax with limited depth
        return _getMinimaxMove(state, availableMoves, depth: 3);
    }
  }

  /// Get greedy move (most immediate captures)
  int _getGreedyMove(AwaleGameState state, List<int> availableMoves) {
    int bestMove = availableMoves.first;
    int maxCaptures = 0;

    for (final move in availableMoves) {
      final simulatedState = AwaleLogic.executeMove(state, move);
      final captures = simulatedState.moveHistory.last.seedsCaptured;

      if (captures > maxCaptures) {
        maxCaptures = captures;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// Get move using minimax algorithm
  int _getMinimaxMove(
    AwaleGameState state,
    List<int> availableMoves, {
    required int depth,
  }) {
    int bestMove = availableMoves.first;
    int bestScore = -999999;

    for (final move in availableMoves) {
      final simulatedState = AwaleLogic.executeMove(state, move);
      final score = _minimax(simulatedState, depth - 1, false, -999999, 999999);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// Minimax algorithm with alpha-beta pruning
  int _minimax(
    AwaleGameState state,
    int depth,
    bool isMaximizing,
    int alpha,
    int beta,
  ) {
    // Terminal conditions
    if (depth == 0 || state.status == GameStatus.finished) {
      return _evaluatePosition(state);
    }

    final availableMoves = AwaleLogic.getAvailableMoves(state);
    if (availableMoves.isEmpty) {
      return _evaluatePosition(state);
    }

    if (isMaximizing) {
      int maxEval = -999999;
      for (final move in availableMoves) {
        final newState = AwaleLogic.executeMove(state, move);
        final eval = _minimax(newState, depth - 1, false, alpha, beta);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in availableMoves) {
        final newState = AwaleLogic.executeMove(state, move);
        final eval = _minimax(newState, depth - 1, true, alpha, beta);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Evaluate board position for bot
  int _evaluatePosition(AwaleGameState state) {
    final botId = state.players.firstWhere((p) => p.isBot).id;
    final humanId = state.players.firstWhere((p) => !p.isBot).id;

    // Score based on captured seeds
    final botCaptures = state.captures[botId] ?? 0;
    final humanCaptures = state.captures[humanId] ?? 0;
    int score = (botCaptures - humanCaptures) * 100;

    // Bonus for seeds on bot's side (mobility)
    final botPits = state.getPitIndicesForPlayer(
      state.players.firstWhere((p) => p.isBot),
    );
    final botSeeds = botPits
        .map((pit) => state.pits[pit])
        .fold(0, (a, b) => a + b);
    score += botSeeds * 2;

    // Penalty for seeds on human's side
    final humanPits = state.getPitIndicesForPlayer(
      state.players.firstWhere((p) => !p.isBot),
    );
    final humanSeeds = humanPits
        .map((pit) => state.pits[pit])
        .fold(0, (a, b) => a + b);
    score -= humanSeeds * 2;

    return score;
  }

  /// Handle game end
  void _handleGameEnd() {
    if (state == null || state!.winnerId == null) return;

    final currentPlayerId = ref.read(awaleCurrentPlayerIdProvider);
    final isWinner = state!.winnerId == currentPlayerId;

    // Play win/lose sound
    if (isWinner) {
      SoundService.playAwaleWin();
    } else {
      SoundService.playAwaleLose();
    }
  }

  /// Reset game
  void resetGame() {
    _botMoveTimer?.cancel();
    state = null;
    ref.read(awaleCurrentPlayerIdProvider.notifier).state = null;
  }

  @override
  void dispose() {
    _botMoveTimer?.cancel();
    super.dispose();
  }
}

/// Bot difficulty levels
enum BotDifficulty { easy, medium, hard }
