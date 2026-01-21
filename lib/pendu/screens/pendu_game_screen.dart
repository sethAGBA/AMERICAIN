import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../providers/pendu_provider.dart';
import '../models/pendu_game_state.dart';
import '../widgets/hangman_painter.dart';
import '../widgets/pendu_keyboard.dart';
import '../../services/sound_service.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';
import '../../providers/settings_provider.dart';

class PenduGameScreen extends ConsumerStatefulWidget {
  const PenduGameScreen({super.key});

  @override
  ConsumerState<PenduGameScreen> createState() => _PenduGameScreenState();
}

class _PenduGameScreenState extends ConsumerState<PenduGameScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start game on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(penduProvider.notifier).startGame();
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    if (settings.musicEnabled) {
      // Use generic BGM or specific if added
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
    final state = ref.watch(penduProvider);

    // Listen for Game Over
    ref.listen(penduProvider, (previous, next) {
      if (next?.status == PenduStatus.won &&
          previous?.status != PenduStatus.won) {
        _confettiController.play();
        SoundService.playWin();
      } else if (next?.status == PenduStatus.lost &&
          previous?.status != PenduStatus.lost) {
        SoundService.playLose();
      }
    });

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF263238), Color(0xFF37474F)], // Blackboard colors
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(type: PatternType.letters, opacity: 0.05),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, state),

                  // Hangman Drawing Area
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(200, 250),
                        painter: HangmanPainter(
                          mistakes: state.maxAttempts - state.remainingAttempts,
                        ),
                      ),
                    ),
                  ),

                  // Word Display
                  Expanded(
                    flex: 2,
                    child: Center(child: _buildWordDisplay(state)),
                  ),

                  // Keyboard
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PenduKeyboard(
                      guessedLetters: state.guessedLetters,
                      onLetterPressed: (letter) {
                        ref.read(penduProvider.notifier).guessLetter(letter);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Win/Lose Overlays
            if (state.status != PenduStatus.playing)
              _buildGameOverOverlay(context, state),

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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PenduGameState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(penduProvider.notifier).resetGame();
            },
          ),
          Text(
            'PENDU',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _confirmExit(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay(PenduGameState state) {
    return Wrap(
      spacing: 8,
      children: state.targetWord.split('').map((char) {
        final isFound = state.guessedLetters.contains(char);
        final showChar = isFound || state.status != PenduStatus.playing;

        return Container(
          width: 40,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
          ),
          child: Text(
            showChar ? char : '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isFound
                  ? Colors.white
                  : Colors.redAccent, // Red if revealed at end
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, PenduGameState state) {
    final isWin = state.status == PenduStatus.won;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWin ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
              color: isWin ? Colors.amber : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isWin ? 'GAGNÉ !' : 'PERDU...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isWin) ...[
              const Text(
                'Le mot était :',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                state.targetWord,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.definition,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
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
                    // Reset confetti if playing
                    _confettiController.stop();
                    ref.read(penduProvider.notifier).resetGame();
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
