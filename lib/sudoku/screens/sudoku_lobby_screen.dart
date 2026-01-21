import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sudoku_provider.dart';
import '../models/sudoku_models.dart';
import '../../widgets/generic_pattern.dart';

class SudokuLobbyScreen extends ConsumerWidget {
  const SudokuLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.grid_3x3, size: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'SUDOKU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Défiez votre esprit',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const Spacer(),
                  _buildDifficultySection(context, ref),
                  const Spacer(),
                  _buildRulesButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildDifficultyButton(
          context,
          ref,
          'FACILE',
          SudokuDifficulty.easy,
          Colors.greenAccent,
        ),
        const SizedBox(height: 16),
        _buildDifficultyButton(
          context,
          ref,
          'MOYEN',
          SudokuDifficulty.medium,
          Colors.orangeAccent,
        ),
        const SizedBox(height: 16),
        _buildDifficultyButton(
          context,
          ref,
          'DIFFICILE',
          SudokuDifficulty.hard,
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    SudokuDifficulty difficulty,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ref.read(sudokuProvider.notifier).startNewGame(difficulty);
          context.push('/sudoku/game');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRulesButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showRules(context),
      icon: const Icon(Icons.info_outline, color: Colors.white70),
      label: const Text(
        'Règles du jeu',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          'Règles du Sudoku',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(
                text: 'Remplissez la grille 9x9 avec les chiffres de 1 à 9.',
              ),
              _RuleItem(
                text: 'Chaque ligne doit contenir tous les chiffres de 1 à 9.',
              ),
              _RuleItem(
                text:
                    'Chaque colonne doit contenir tous les chiffres de 1 à 9.',
              ),
              _RuleItem(
                text:
                    'Chaque carré 3x3 doit contenir tous les chiffres de 1 à 9.',
              ),
              _RuleItem(
                text: 'Utilisez le mode "Notes" pour marquer les possibilités.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'COMPRIS',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.orangeAccent, fontSize: 18),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
