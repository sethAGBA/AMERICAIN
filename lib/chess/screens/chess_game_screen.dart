import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chess_provider.dart';
import '../models/chess_models.dart';
import '../widgets/chess_widgets.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';

class ChessGameScreen extends ConsumerWidget {
  const ChessGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3E2723), Color(0xFF1B1B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const GenericPattern(type: PatternType.board, opacity: 0.1),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state, ref),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ChessBoardWidget(
                    board: state.board,
                    selectedSquare: state.selectedSquare,
                    validMoves: state.validMoves,
                    currentPlayer: state.currentPlayer,
                    onSquareTap: (square) =>
                        ref.read(chessProvider.notifier).selectSquare(square),
                  ),
                ),
                const Spacer(),
                _buildStatus(state),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (state.status == ChessStatus.checkmate ||
              state.status == ChessStatus.stalemate)
            _buildGameOverOverlay(context, state, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChessGameState state,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _confirmExit(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Column(
            children: [
              const Text(
                'ÉCHECS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              Text(
                state.currentPlayer == ChessColor.white
                    ? 'TOUR DES BLANCS'
                    : 'TOUR DES NOIRS',
                style: TextStyle(
                  color: state.currentPlayer == ChessColor.white
                      ? Colors.white70
                      : Colors.brown[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => ref.read(chessProvider.notifier).resetGame(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(ChessGameState state) {
    if (state.status == ChessStatus.check) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'ÉCHEC !',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }
    return const SizedBox(height: 48);
  }

  Widget _buildGameOverOverlay(
    BuildContext context,
    ChessGameState state,
    WidgetRef ref,
  ) {
    final isMate = state.status == ChessStatus.checkmate;
    final winner = state.currentPlayer == ChessColor.white ? 'NOIRS' : 'BLANCS';

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMate ? Icons.emoji_events : Icons.balance,
              color: Colors.amber,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isMate ? 'ÉCHEC ET MAT !' : 'PAT',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isMate)
              Text(
                'VICTOIRE DES $winner',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('QUITTER'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => ref.read(chessProvider.notifier).resetGame(),
                  child: const Text('REJOUER'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GameExitDialog(
        title: 'Quitter ?',
        content: 'Voulez-vous vraiment quitter la partie d\'échecs ?',
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}
