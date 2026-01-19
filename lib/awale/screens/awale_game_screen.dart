import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/awale_game_state.dart';
import '../providers/awale_provider.dart';
import '../widgets/awale_board.dart';
import '../../providers/settings_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/generic_pattern.dart';

/// Main Awale game screen
class AwaleGameScreen extends ConsumerStatefulWidget {
  const AwaleGameScreen({super.key});

  @override
  ConsumerState<AwaleGameScreen> createState() => _AwaleGameScreenState();
}

class _AwaleGameScreenState extends ConsumerState<AwaleGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    SoundService.playBGM(settings.gameMusicPath, volume: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(awaleGameStateProvider);
    final currentPlayerId = ref.watch(awaleCurrentPlayerIdProvider);

    // Listen to music path changes
    ref.listen(settingsProvider.select((s) => s.gameMusicPath), (
      previous,
      next,
    ) {
      if (next != previous) {
        SoundService.playBGM(next, volume: 0.3);
      }
    });

    // Listen to music enabled status
    ref.listen(settingsProvider.select((s) => s.musicEnabled), (
      previous,
      next,
    ) {
      if (next == true && (previous == false || previous == null)) {
        _playMusic();
      } else if (next == false) {
        SoundService.stopBGM();
      }
    });

    // Listen for game end
    ref.listen(awaleGameStateProvider, (previous, next) {
      if (next != null &&
          next.status == GameStatus.finished &&
          previous?.status != GameStatus.finished) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showGameEndDialog(next);
          }
        });
      }
    });

    if (gameState == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Awale'),
          backgroundColor: const Color(0xFF5D4037),
        ),
        body: const Center(child: Text('Aucune partie en cours')),
      );
    }

    final currentPlayer = gameState.currentPlayer;
    final isCurrentPlayerTurn =
        currentPlayerId != null && currentPlayer.id == currentPlayerId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8D6E63), // Light brown
              Color(0xFF5D4037), // Medium brown
              Color(0xFF3E2723), // Dark brown
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.circles,
                opacity: 0.1,
                crossAxisCount: 8,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(gameState, currentPlayer, isCurrentPlayerTurn),

                  // Game board
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [const AwaleBoard()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AwaleGameState gameState,
    dynamic currentPlayer,
    bool isCurrentPlayerTurn,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Awale',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showRulesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              _showExitDialog();
            },
            tooltip: 'Quitter la partie',
          ),
        ],
      ),
    );
  }

  void _showGameEndDialog(AwaleGameState gameState) {
    final currentPlayerId = ref.read(awaleCurrentPlayerIdProvider);
    final winnerId = gameState.winnerId;
    final isWinner = winnerId == currentPlayerId;

    final winner = gameState.players.firstWhere((p) => p.id == winnerId);
    final winnerScore = gameState.captures[winnerId] ?? 0;
    final loserScore = gameState.captures.values.firstWhere(
      (score) => score != winnerScore,
      orElse: () => 0,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF5D4037),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isWinner ? '🎉 Victoire !' : '😔 Défaite',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${winner.name} gagne !',
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Score Final',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$winnerScore - $loserScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(awaleGameStateProvider.notifier).resetGame();
              context.go('/');
            },
            child: const Text(
              'Menu Principal',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Restart game with same settings
              final oldState = gameState;
              ref.read(awaleGameStateProvider.notifier).resetGame();

              // Create new game
              ref
                  .read(awaleGameStateProvider.notifier)
                  .createGame(
                    gameId: DateTime.now().millisecondsSinceEpoch.toString(),
                    playerName: oldState.players
                        .firstWhere((p) => p.id == currentPlayerId)
                        .name,
                    playerId: currentPlayerId!,
                    vsBot: oldState.players.any((p) => p.isBot),
                    mode: oldState.mode,
                  );
              ref.read(awaleGameStateProvider.notifier).startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejouer'),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF5D4037),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Règles d\'Awale',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleItem(
                '🎯 Objectif',
                'Capturer plus de 25 graines (sur 48 au total)',
              ),
              _buildRuleItem(
                '🎮 Comment jouer',
                'Choisissez un trou de votre côté et distribuez les graines dans le sens antihoraire',
              ),
              _buildRuleItem(
                '✨ Capture',
                'Si la dernière graine atterrit dans un trou adverse avec 2 ou 3 graines au total, capturez-les',
              ),
              _buildRuleItem(
                '🚫 Règle anti-famine',
                'Vous ne pouvez pas laisser l\'adversaire sans graines',
              ),
              _buildRuleItem(
                '🏆 Victoire',
                'Premier joueur à capturer 25+ graines',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFB74D),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF5D4037),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quitter la partie ?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Voulez-vous vraiment quitter cette partie ?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(awaleGameStateProvider.notifier).resetGame();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
