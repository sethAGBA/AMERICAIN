import 'dart:ui'; // For ImageFilter
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../models/puissance4_player.dart';
import '../models/puissance4_state.dart';
import '../providers/puissance4_provider.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_exit_dialog.dart';

class Puissance4GameScreen extends ConsumerStatefulWidget {
  const Puissance4GameScreen({super.key});

  @override
  ConsumerState<Puissance4GameScreen> createState() =>
      _Puissance4GameScreenState();
}

class _Puissance4GameScreenState extends ConsumerState<Puissance4GameScreen> {
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
    final gameState = ref.watch(puissance4Provider);

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

    // Listen to music path changes
    ref.listen(settingsProvider.select((s) => s.gameMusicPath), (
      previous,
      next,
    ) {
      if (next != previous) {
        SoundService.playBGM(next);
      }
    });

    // Listen for game end/moves to trigger sounds
    ref.listen(puissance4Provider, (previous, next) {
      // 1. Check for Move (Piece Drop)
      // If board is different and not empty (to avoid sound on init)
      if (previous != null && next.board.isNotEmpty && !previous.isGameOver) {
        // Calculate total pieces
        int prevCount = previous.board.fold(
          0,
          (sum, row) => sum + row.where((c) => c != null).length,
        );
        int nextCount = next.board.fold(
          0,
          (sum, row) => sum + row.where((c) => c != null).length,
        );

        if (nextCount > prevCount) {
          SoundService.playP4Drop();
        }
      }

      // 2. Check for Game Over
      if (next.isGameOver && (previous == null || !previous.isGameOver)) {
        final winner = next.winner;
        if (winner != null) {
          if (winner.type == PlayerType.human) {
            SoundService.playWin();
          } else {
            SoundService.playLose();
          }
        } else if (next.isDraw) {
          // Optional: Play draw sound or generic game over
          SoundService.playLose(); // Or a draw sound if available
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD32F2F), // Red 700
              Color(0xFFB71C1C), // Red 900
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left button: Refresh/Restart (Standardizing positions)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            ref.read(puissance4Provider.notifier).restartGame();
                          },
                        ),

                        // Turn Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gameState.currentPlayer?.type ==
                                        PlayerType.human
                                    ? Icons.person
                                    : Icons.computer,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                gameState.players.any(
                                      (p) => p.type == PlayerType.bot,
                                    )
                                    ? (gameState.currentPlayer?.type ==
                                              PlayerType.human
                                          ? "À VOTRE TOUR"
                                          : "L'IA RÉFLÉCHIT...")
                                    : "TOUR DE ${gameState.currentPlayer?.name.toUpperCase()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right button: Exit (X)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            _confirmExit(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Game Board
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 7 / 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return _buildBoard(
                                context,
                                ref,
                                gameState,
                                constraints,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
              if (gameState.isGameOver) _buildWinOverlay(gameState),

              // Confetti Overlay
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
                    Colors.purple,
                    Colors.yellow,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(
    BuildContext context,
    WidgetRef ref,
    Puissance4State state,
    BoxConstraints constraints,
  ) {
    if (state.board.isEmpty) return const SizedBox.shrink();

    // Calculate cell size based on the smaller dimension to fit safely
    final cellWidth = constraints.maxWidth / 7;
    final cellHeight = constraints.maxHeight / 6;
    final cellSize = min(cellWidth, cellHeight);

    // We center the board effectively by using this constrained size

    return Stack(
      children: [
        // Blue Grid Background
        Center(
          child: Container(
            width: cellSize * 7,
            height: cellSize * 6,
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: List.generate(6, (rowIndex) {
                return Row(
                  children: List.generate(7, (colIndex) {
                    final color = state.board[rowIndex][colIndex];
                    final isWinning = state.winningCells.any(
                      (p) => p.x == rowIndex && p.y == colIndex,
                    );

                    return GestureDetector(
                      onTap: () {
                        final currentPlayer = state.currentPlayer;
                        if (currentPlayer != null &&
                            currentPlayer.type == PlayerType.human &&
                            !state.isGameOver) {
                          ref
                              .read(puissance4Provider.notifier)
                              .playMove(colIndex);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: Center(
                          child: Container(
                            width: cellSize * 0.85,
                            height: cellSize * 0.85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color == null
                                  ? Colors.white.withOpacity(0.1) // Empty hole
                                  : (color == Puissance4Color.red
                                        ? Colors.red
                                        : Colors.yellow),
                              border: isWinning
                                  ? Border.all(color: Colors.white, width: 4)
                                  : null,
                              boxShadow: color != null
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinOverlay(Puissance4State state) {
    final isHumanWin =
        state.winner != null && state.winner!.type == PlayerType.human;
    final isDraw = state.isDraw;

    String title;
    Color color;
    IconData icon;

    if (isDraw) {
      title = "MATCH NUL";
      color = Colors.white;
      icon = Icons.balance;
    } else if (isHumanWin) {
      title = "VICTOIRE !";
      color = const Color(0xFFFFD700);
      icon = Icons.emoji_events;
      _confettiController.play(); // Play confetti on win
    } else {
      title = "DÉFAITE";
      color = Colors.red;
      icon = Icons.sentiment_very_dissatisfied;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Icon(icon, color: color, size: 120),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            if (state.winner != null && !isHumanWin)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "${state.winner!.name} a gagné",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('QUITTER'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.read(puissance4Provider.notifier).restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: const Text(
                    'REJOUER',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
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
        content: 'Voulez-vous vraiment quitter la partie ?',
        backgroundColor: const Color(0xFFB71C1C),
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}
