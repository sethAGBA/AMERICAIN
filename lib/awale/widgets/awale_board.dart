import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/awale_game_state.dart';
import '../models/awale_player.dart';
import '../providers/awale_provider.dart';
import '../awale_logic.dart';
import '../awale_rules.dart';
import 'awale_pit.dart';

/// Main Awale board widget
class AwaleBoard extends ConsumerWidget {
  const AwaleBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(awaleGameStateProvider);
    final currentPlayerId = ref.watch(awaleCurrentPlayerIdProvider);

    if (gameState == null) {
      return const Center(child: Text('No game state'));
    }

    final currentPlayer = gameState.currentPlayer;
    final isCurrentPlayerTurn =
        currentPlayerId != null && currentPlayer.id == currentPlayerId;

    // Get available moves for highlighting
    final availableMoves = isCurrentPlayerTurn
        ? AwaleLogic.getAvailableMoves(gameState)
        : <int>[];

    // Identify players by side to keep them static
    // Top player (Side.top) is usually on the Left in this column layout (pits 0-5)
    // Bottom player (Side.bottom) is usually on the Right (pits 6-11)
    final topPlayer = gameState.players.firstWhere(
      (p) => p.side == PlayerSide.top,
      orElse: () => gameState.players[1],
    );
    final bottomPlayer = gameState.players.firstWhere(
      (p) => p.side == PlayerSide.bottom,
      orElse: () => gameState.players[0],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Wood grain effect with layered gradients
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6D4C41), // Rich brown
            const Color(0xFF5D4037), // Dark brown
            const Color(0xFF4E342E), // Very dark brown
            const Color(0xFF3E2723), // Almost black brown
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF8D6E63), width: 3),
        boxShadow: [
          // Main shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 5,
          ),
          // Secondary glow
          BoxShadow(
            color: const Color(0xFF3E2723).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRect(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Player (Left side) area
            _buildScoreArea(
              topPlayer,
              gameState.captures[topPlayer.id] ?? 0,
              isOpponent: true,
              isHorizontal: true,
              isCurrentTurn: currentPlayer.id == topPlayer.id,
              isPlayerTurn: currentPlayerId == topPlayer.id,
            ),
            const SizedBox(width: 8),

            // Left column (Top Player's pits: 5, 4, 3, 2, 1, 0)
            _buildPitColumn(
              gameState,
              [5, 4, 3, 2, 1, 0],
              availableMoves,
              ref,
              isLeftColumn: true,
            ),

            const SizedBox(width: 12),

            // Divider
            Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Right column (Bottom Player's pits: 6, 7, 8, 9, 10, 11)
            _buildPitColumn(
              gameState,
              [6, 7, 8, 9, 10, 11],
              availableMoves,
              ref,
              isLeftColumn: false,
            ),

            const SizedBox(width: 8),

            // Bottom Player (Right side) area
            _buildScoreArea(
              bottomPlayer,
              gameState.captures[bottomPlayer.id] ?? 0,
              isOpponent: false,
              isHorizontal: true,
              isCurrentTurn: currentPlayer.id == bottomPlayer.id,
              isPlayerTurn: currentPlayerId == bottomPlayer.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitColumn(
    AwaleGameState gameState,
    List<int> pitIndices,
    List<int> availableMoves,
    WidgetRef ref, {
    required bool isLeftColumn,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: pitIndices.map((pitIndex) {
        final isSelectable = availableMoves.contains(pitIndex);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SizedBox(
            width: 72,
            height: 58,
            child: AwalePit(
              pitIndex: pitIndex,
              seedCount: gameState.pits[pitIndex],
              isSelectable: isSelectable,
              isHighlighted: false,
              isTopRow: isLeftColumn,
              onTap: isSelectable
                  ? () {
                      ref
                          .read(awaleGameStateProvider.notifier)
                          .makeMove(pitIndex);
                    }
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreArea(
    AwalePlayer player,
    int score, {
    required bool isOpponent,
    bool isHorizontal = false,
    bool isCurrentTurn = false,
    bool isPlayerTurn = false,
  }) {
    if (isHorizontal) {
      // Vertical layout for horizontal board
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              player.isBot ? Icons.smart_toy : Icons.person,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: score >= AwaleRules.seedsToWin
                    ? const Color(0xFF4CAF50) // Green for winning
                    : const Color(0xFF8D6E63), // Brown
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Turn indicator
            if (isCurrentTurn)
              RotatedBox(
                quarterTurns: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPlayerTurn
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPlayerTurn ? 'Votre tour' : 'Son tour',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Original horizontal layout for vertical board
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                player.isBot ? Icons.smart_toy : Icons.person,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: score >= AwaleRules.seedsToWin
                  ? const Color(0xFF4CAF50) // Green for winning
                  : const Color(0xFF8D6E63), // Brown
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
