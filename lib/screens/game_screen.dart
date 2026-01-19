import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import '../widgets/game_table.dart';
import '../widgets/hand_widget.dart';
import '../widgets/suit_pattern.dart';

/// Main game screen
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
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
    // Reduce volume to 30% during gameplay so sound effects are more audible
    SoundService.playBGM(settings.gameMusicPath, volume: 0.3);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final currentPlayerId = ref.watch(currentPlayerIdProvider);

    // Listen to music path changes
    ref.listen(settingsProvider.select((s) => s.gameMusicPath), (
      previous,
      next,
    ) {
      if (next != previous) {
        SoundService.playBGM(next);
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

    if (gameState == null || currentPlayerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partie')),
        body: const Center(child: Text('Aucune partie active')),
      );
    }

    final currentPlayer = gameState.players.firstWhere(
      (p) => p.id == currentPlayerId,
      orElse: () => gameState.players.first,
    );
    final isCurrentTurn = gameState.currentPlayer?.id == currentPlayerId;

    // Check for winner
    if (gameState.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWinnerDialog(context, gameState);
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF43A047), // Vibrant Emerald Green 600
              const Color(0xFF1B5E20), // Darker Forest Green 800
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: SuitPattern(opacity: 0.05)),
            SafeArea(
              child: Column(
                children: [
                  // Custom Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AMERICAIN',
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
                          onPressed: () => _confirmLeaveGame(context),
                        ),
                      ],
                    ),
                  ),

                  // Turn indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: isCurrentTurn
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.7),
                    child: Text(
                      isCurrentTurn
                          ? '🎯 À votre tour !'
                          : '⏳ Tour de ${gameState.currentPlayer?.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrentTurn
                            ? const Color(0xFF1B5E20)
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Game table
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GameTable(
                          gameState: gameState,
                          currentPlayerId: currentPlayerId,
                          onDrawCard: isCurrentTurn ? _handleDrawCard : null,
                        ),
                      ),
                    ),
                  ),

                  // Current player's hand
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Votre main (${currentPlayer.cardCount} cartes)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        HandWidget(
                          player: currentPlayer,
                          topCard: gameState.topCard,
                          currentSuit: gameState.currentSuit,
                          penalty: gameState.getPenaltyFor(currentPlayer.id),
                          activeAttackCard: gameState.activeAttackCard,
                          mustMatchSuit: gameState.mustMatchSuit,
                          onCardTap: isCurrentTurn ? _handleCardPlay : null,
                          isCurrentPlayer: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Confetti Layer
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
                createParticlePath: drawStar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A custom Path to paint stars
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * math.cos(step),
        halfWidth + externalRadius * math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  void _handleCardPlay(PlayingCard card) {
    if (card.rank == Rank.eight) {
      _showSuitSelector(card);
    } else {
      ref.read(gameNotifierProvider.notifier).playCard(card);
    }
  }

  void _showSuitSelector(PlayingCard card) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez une couleur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...Suit.values.map((suit) {
              final isRed = suit == Suit.hearts || suit == Suit.diamonds;
              return ListTile(
                leading: Text(
                  suit.symbol,
                  style: TextStyle(
                    fontSize: 32,
                    color: isRed ? Colors.red : Colors.black,
                  ),
                ),
                title: Text(suit.label.toUpperCase()),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(gameNotifierProvider.notifier)
                      .playCard(card, chosenSuit: suit);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handleDrawCard() {
    ref.read(gameNotifierProvider.notifier).drawCard();
  }

  void _confirmLeaveGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text('Êtes-vous sûr de vouloir quitter cette partie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameNotifierProvider.notifier).leaveGame();
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _showWinnerDialog(BuildContext context, GameState state) {
    // Play confetti
    _confettiController.play();

    final winner = state.winner;
    final currentPlayerId = ref.read(currentPlayerIdProvider);

    // Play win/lose sound immediately
    if (winner?.id == currentPlayerId) {
      SoundService.playWin();
    } else {
      SoundService.playLose();
    }

    final playersWithScores = List.from(state.players);
    playersWithScores.sort((a, b) => a.handPoints.compareTo(b.handPoints));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Partie terminée !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${winner?.name ?? 'Inconnu'} a gagné !',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Points restants :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...playersWithScores.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: p.id == winner?.id ? Colors.green : Colors.black,
                        fontWeight: p.id == winner?.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${p.handPoints} pts',
                      style: TextStyle(
                        fontWeight: p.id == winner?.id
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
        actions: [
          TextButton(
            onPressed: () {
              _confettiController.stop();
              ref.read(gameNotifierProvider.notifier).leaveGame();
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Retour au menu'),
          ),
        ],
      ),
    );
  }
}
