import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/othello_provider.dart';
import '../models/othello_models.dart';
import '../widgets/othello_widgets.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';

class OthelloGameScreen extends ConsumerWidget {
  const OthelloGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(othelloProvider);
    final validMoves = ref
        .read(othelloProvider.notifier)
        .getValidMoves(state.currentTurn);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF000000)],
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
                _buildScoreBoard(state),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OthelloBoardWidget(
                    board: state.board,
                    validMoves: validMoves,
                    onSquareTap: (square) {
                      ref.read(othelloProvider.notifier).makeMove(square);
                    },
                  ),
                ),
                const Spacer(),
                _buildTurnIndicator(state),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (state.status == OthelloStatus.finished)
            _buildGameOverOverlay(context, state, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    OthelloGameState state,
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
          const Text(
            'OTHELLO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          IconButton(
            onPressed: () => ref.read(othelloProvider.notifier).resetGame(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(OthelloGameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem(
            'NOIRS',
            state.blackCount,
            Colors.black,
            Colors.white,
          ),
          _buildScoreItem(
            'BLANCS',
            state.whiteCount,
            Colors.white,
            Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(
    String label,
    int count,
    Color bgColor,
    Color textColor,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTurnIndicator(OthelloGameState state) {
    if (state.status == OthelloStatus.finished) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: state.currentTurn == OthelloPiece.black
                  ? Colors.black
                  : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            state.currentTurn == OthelloPiece.black
                ? 'TOUR DES NOIRS'
                : 'TOUR DES BLANCS',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(
    BuildContext context,
    OthelloGameState state,
    WidgetRef ref,
  ) {
    final blackWin = state.blackCount > state.whiteCount;
    final draw = state.blackCount == state.whiteCount;
    final winner = blackWin ? 'NOIRS' : 'BLANCS';

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              draw ? Icons.balance : Icons.emoji_events,
              color: Colors.amber,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              draw ? 'MATCH NUL !' : 'VICTOIRE !',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!draw)
              Text(
                'LES $winner ONT GAGNÉ',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            const SizedBox(height: 16),
            Text(
              'SCORE : ${state.blackCount} - ${state.whiteCount}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                  onPressed: () =>
                      ref.read(othelloProvider.notifier).resetGame(),
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
        content: 'Voulez-vous vraiment quitter la partie d\'Othello ?',
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}
