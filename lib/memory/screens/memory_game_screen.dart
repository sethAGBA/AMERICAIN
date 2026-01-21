import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../providers/memory_provider.dart';
import '../models/memory_game_state.dart';
import '../widgets/memory_card_widget.dart';
import '../../services/sound_service.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';
import '../../providers/settings_provider.dart';

class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    if (settings.musicEnabled) {
      SoundService.playBGM(settings.gameMusicPath);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryProvider);

    // Listen for Win
    ref.listen(memoryProvider, (previous, next) {
      if (next.status == MemoryGameStatus.won &&
          previous?.status != MemoryGameStatus.won) {
        _confettiController.play();
        SoundService.playWin();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF311B92)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: state.cards.length,
                          itemBuilder: (context, index) {
                            final card = state.cards[index];
                            return MemoryCardWidget(
                              card: card,
                              onTap: () {
                                ref
                                    .read(memoryProvider.notifier)
                                    .flipCard(card.id);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Win Overlay
          if (state.status == MemoryGameStatus.won)
            _buildWinOverlay(context, state),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MemoryGameState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(memoryProvider.notifier).restartGame();
            },
          ),
          Column(
            children: [
              const Text(
                'MEMORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (state.isMultiplayer) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayerScore(
                      'P1',
                      state.playerScores[0],
                      state.currentPlayer == 0,
                    ),
                    const SizedBox(width: 24),
                    _buildPlayerScore(
                      'P2',
                      state.playerScores[1],
                      state.currentPlayer == 1,
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Coups: ${state.attempts}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _confirmExit(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWinOverlay(BuildContext context, MemoryGameState state) {
    String message = 'VICTOIRE !';
    String subMessage = 'Terminé en ${state.attempts} coups';

    if (state.isMultiplayer) {
      if (state.playerScores[0] > state.playerScores[1]) {
        message = 'JOUEUR 1 GAGNE !';
      } else if (state.playerScores[1] > state.playerScores[0]) {
        message = 'JOUEUR 2 GAGNE !';
      } else {
        message = 'ÉGALITÉ !';
      }
      subMessage = '${state.playerScores[0]} - ${state.playerScores[1]}';
    }

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('QUITTER'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _confettiController.stop();
                    ref.read(memoryProvider.notifier).restartGame();
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

  Widget _buildPlayerScore(String label, int score, bool isActive) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.amber : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        Text(
          score.toString(),
          style: TextStyle(
            color: isActive ? Colors.amber : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 20,
            color: Colors.amber,
          ),
      ],
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GameExitDialog(
        title: 'Quitter ?',
        content: 'Voulez-vous vraiment quitter la partie ?',
        onConfirm: () {
          Navigator.of(context).pop();
          if (GoRouter.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    );
  }
}
