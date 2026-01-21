import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sudoku_provider.dart';
import '../models/sudoku_models.dart';
import '../widgets/sudoku_widgets.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';

class SudokuGameScreen extends ConsumerStatefulWidget {
  const SudokuGameScreen({super.key});

  @override
  ConsumerState<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends ConsumerState<SudokuGameScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sudokuProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const GenericPattern(
              type: PatternType.circles,
              opacity: 0.1,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SudokuBoard(
                    board: state.board,
                    selectedRow: state.selectedRow,
                    selectedCol: state.selectedCol,
                    onCellTap: (r, c) =>
                        ref.read(sudokuProvider.notifier).selectCell(r, c),
                  ),
                ),
                const Spacer(),
                _buildControls(state),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (state.status == SudokuStatus.won) _buildWinOverlay(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SudokuGameState state) {
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
                'SUDOKU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              Text(
                state.difficulty.name.toUpperCase(),
                style: TextStyle(
                  color: _getDifficultyColor(state.difficulty),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => ref
                .read(sudokuProvider.notifier)
                .startNewGame(state.difficulty),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(SudokuGameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SudokuNumberPad(
        isNotesMode: state.isNotesMode,
        onNumberTap: (n) => ref.read(sudokuProvider.notifier).setNumber(n),
        onErase: () => ref.read(sudokuProvider.notifier).eraseCell(),
        onToggleNotes: () =>
            ref.read(sudokuProvider.notifier).toggleNotesMode(),
      ),
    );
  }

  Widget _buildWinOverlay(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const SizedBox(height: 24),
            const Text(
              'VICTOIRE !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
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
                  onPressed: () {
                    final diff = ref.read(sudokuProvider).difficulty;
                    ref.read(sudokuProvider.notifier).startNewGame(diff);
                  },
                  child: const Text('REJOUER'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(SudokuDifficulty diff) {
    switch (diff) {
      case SudokuDifficulty.easy:
        return Colors.greenAccent;
      case SudokuDifficulty.medium:
        return Colors.orangeAccent;
      case SudokuDifficulty.hard:
        return Colors.redAccent;
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GameExitDialog(
        title: 'Quitter ?',
        content: 'Voulez-vous vraiment quitter la partie ?',
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}
