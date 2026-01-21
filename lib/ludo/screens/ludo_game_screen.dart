import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../providers/stats_provider.dart';
import '../providers/ludo_provider.dart';
import '../models/ludo_piece.dart';
import '../models/ludo_player.dart';
import '../models/ludo_game_state.dart';
import '../widgets/ludo_board.dart';
import 'package:go_router/go_router.dart';
import '../widgets/ludo_dice.dart';
import '../../services/sound_service.dart';
import '../../widgets/generic_pattern.dart';
import '../../providers/settings_provider.dart';

class LudoGameScreen extends ConsumerStatefulWidget {
  const LudoGameScreen({super.key});

  @override
  ConsumerState<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends ConsumerState<LudoGameScreen> {
  bool _isRolling = false;
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
      SoundService.playBGM(settings.gameMusicPath, volume: 0.3);
    }
  }

  @override
  void dispose() {
    SoundService.stopBGM();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleRoll() async {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    SoundService.playLudoRollStart();

    // Animate for a bit
    await Future.delayed(const Duration(milliseconds: 600));

    // Perform actual roll
    ref.read(ludoProvider.notifier).rollDice();

    if (mounted) {
      setState(() {
        _isRolling = false;
      });
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          'Quitter la partie ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter ? Votre progression sera sauvegardée.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ANNULER',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(ludoProvider.notifier).leaveGame();
              context.go('/ludo'); // Go back to start
            },
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(ludoProvider);

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
        SoundService.playBGM(next, volume: 0.3);
      }
    });
    // For now, assume single device multiplayer or always enable touches if it's "current player"

    // Listen for game finished
    ref.listen(ludoProvider.select((s) => s.turnState), (previous, next) {
      if (next == LudoTurnState.finished &&
          previous != LudoTurnState.finished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWinnerDialog(context, gameState);
        });
      }
    });

    final canRoll =
        gameState.turnState == LudoTurnState.waitingForRoll && !_isRolling;

    final piecesInPlay = gameState.currentPlayer.pieces
        .where(
          (p) =>
              p.state == PieceState.track || p.state == PieceState.goalStretch,
        )
        .length;
    final hasSix = gameState.diceValues.contains(6);
    final isForcedCombined =
        piecesInPlay == 1 && !hasSix && gameState.diceValues.length >= 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E88E5), // Blue 600
              Color(0xFF0D47A1), // Blue 900
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.board,
                opacity: 0.05,
                crossAxisCount: 8,
              ),
            ),
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
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LUDO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.exit_to_app,
                            color: Colors.white,
                          ),
                          onPressed: _showExitConfirmation,
                          tooltip: 'Quitter la partie',
                        ),
                      ],
                    ),
                  ),
                ),

                // Turn indicator (🎯 À votre tour ! style)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getTurnIcon(gameState),
                      const SizedBox(width: 8),
                      Text(
                        _getTurnIndicatorText(gameState),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _getColor(gameState.currentPlayer.color),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LudoBoard(gameState: gameState),
                    ),
                  ),
                ),

                // Dice Control Area
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 110, // Dice height 80 + padding/shadows
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Undo Button
                                  if (gameState.currentPlayer.type ==
                                          PlayerType.human &&
                                      gameState.diceValues.isNotEmpty) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.replay,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(ludoProvider.notifier)
                                            .undoTurn();
                                      },
                                      tooltip: 'Annuler et Relancer',
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  ...List.generate(
                                    gameState.diceValues.length,
                                    (index) {
                                      final val = gameState.diceValues[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: LudoDice(
                                          value: val,
                                          isSelected: gameState
                                              .selectedDiceIndices
                                              .contains(index),
                                          onTap: () {
                                            if (canRoll) {
                                              _handleRoll();
                                            } else if (gameState.turnState ==
                                                LudoTurnState.waitingForMove) {
                                              ref
                                                  .read(ludoProvider.notifier)
                                                  .selectDie(index);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  if (_isRolling)
                                    ...List.generate(2, (i) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: LudoDice(isRolling: true),
                                      );
                                    }),
                                  if (gameState.turnState ==
                                          LudoTurnState.waitingForRoll &&
                                      !_isRolling)
                                    ...List.generate(2, (i) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: LudoDice(
                                          value: 1,
                                          isSelected: false,
                                          onTap: canRoll ? _handleRoll : null,
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (gameState.selectedDiceIndices.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Somme : ${gameState.selectedDiceIndices.fold(0, (sum, i) => sum + gameState.diceValues[i])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          _getTurnText(gameState),
                          style: TextStyle(
                            color: isForcedCombined ? Colors.red : Colors.grey,
                            fontWeight: isForcedCombined
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTurnText(LudoGameState gameState) {
    if (gameState.turnState == LudoTurnState.waitingForRoll) {
      if (_isRolling) return '...';
      return 'Appuyez pour lancer';
    }
    if (gameState.diceValues.isEmpty) return '...';

    final piecesInPlay = gameState.currentPlayer.pieces
        .where(
          (p) =>
              p.state == PieceState.track || p.state == PieceState.goalStretch,
        )
        .length;
    final hasSix = gameState.diceValues.contains(6);
    final isForcedCombined =
        piecesInPlay == 1 && !hasSix && gameState.diceValues.length >= 2;

    if (isForcedCombined) return 'Mouvement combiné ! Jouez le pion.';

    if (gameState.selectedDiceIndices.isEmpty) return 'Sélectionnez un dé';
    return 'Jouez une pièce';
  }

  Widget _getTurnIcon(LudoGameState gameState) {
    if (gameState.currentPlayer.type == PlayerType.bot) {
      return const Icon(Icons.smart_toy, size: 20, color: Colors.grey);
    }
    return const Text('🎯', style: TextStyle(fontSize: 18));
  }

  String _getTurnIndicatorText(LudoGameState gameState) {
    final color = gameState.currentPlayer.color.frenchName;
    final type = gameState.currentPlayer.type == PlayerType.bot
        ? ' (ROBOT)'
        : '';
    return 'JOUEUR $color$type';
  }

  Color _getColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return Colors.red.shade700;
      case LudoColor.green:
        return Colors.green.shade700;
      case LudoColor.yellow:
        return Colors.orange.shade700;
      case LudoColor.blue:
        return Colors.blue.shade700;
    }
  }

  void _showWinnerDialog(BuildContext context, LudoGameState state) {
    if (state.winners.isEmpty) return;

    _confettiController.play();
    final winnerColor = state.winners.first;

    // Check if "User" (Red/Player 0) won
    // Assuming user is always Red in this simple version or explicit mapping needed
    // If Red is human and Red won -> Win
    final userWon = winnerColor == LudoColor.red; // Simplified assumption

    if (userWon) {
      ref.read(statsControllerProvider.notifier).recordWin('ludo');
    } else {
      ref.read(statsControllerProvider.notifier).recordLoss('ludo');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Partie terminée !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Les ${winnerColor.frenchName} ont gagné !',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (userWon)
              const Text(
                'Bravo, vous avez gagné !',
                style: TextStyle(color: Colors.green),
              )
            else
              const Text(
                'Dommage, une prochaine fois !',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _confettiController.stop();
              ref.read(ludoProvider.notifier).leaveGame();
              context.go('/ludo');
            },
            child: const Text('Retour au menu'),
          ),
        ],
      ),
    );
  }
}
