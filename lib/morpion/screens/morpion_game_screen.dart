import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../providers/morpion_provider.dart';
import '../models/morpion_state.dart';
import '../../widgets/generic_pattern.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class MorpionGameScreen extends ConsumerStatefulWidget {
  const MorpionGameScreen({super.key});

  @override
  ConsumerState<MorpionGameScreen> createState() => _MorpionGameScreenState();
}

class _MorpionGameScreenState extends ConsumerState<MorpionGameScreen> {
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
      SoundService.playBGM(SoundService.bgmDomino, volume: 0.4);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    SoundService.stopBGM();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(morpionProvider);

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

    ref.listen(morpionProvider.select((s) => s.status), (prev, next) {
      if (next == MorpionStatus.finished && prev != MorpionStatus.finished) {
        final currentState = ref.read(morpionProvider);
        if (currentState.winnerId != null) {
          final winner = currentState.players.firstWhere(
            (p) => p.id == currentState.winnerId,
          );
          if (!winner.isBot) {
            _confettiController.play();
            SoundService.playWin();
          } else {
            SoundService.playLose();
          }
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.board,
                opacity: 0.05,
                crossAxisCount: 6,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state),
                  const Spacer(),
                  _buildGameStatus(state),
                  const SizedBox(height: 32),
                  _buildGrid(state),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            if (state.status == MorpionStatus.finished) _buildWinOverlay(state),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.yellow,
                  Colors.white,
                  Colors.purpleAccent,
                  Colors.blueAccent,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MorpionState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _confirmExit(context),
          ),
          const Text(
            'MORPION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showRules(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatus(MorpionState state) {
    if (state.status == MorpionStatus.finished) return const SizedBox.shrink();

    final currentPlayer = state.players[state.currentTurn];
    return Column(
      children: [
        Text(
          currentPlayer.isBot ? 'L\'IA RÉFLÉCHIT...' : 'À VOTRE TOUR',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentPlayer.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(MorpionState state) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(32),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final cell = state.board[index];
            final isWinningCell = state.winningLine?.contains(index) ?? false;

            return GestureDetector(
              onTap: () => ref.read(morpionProvider.notifier).makeMove(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWinningCell
                        ? const Color(0xFFFFD700)
                        : Colors.white24,
                    width: isWinningCell ? 4 : 1,
                  ),
                ),
                child: Center(
                  child: _SymbolWidget(symbol: cell, isWinning: isWinningCell),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWinOverlay(MorpionState state) {
    String title = "";
    String message = "";
    Color accentColor = const Color(0xFFFFD700);

    if (state.isDraw) {
      title = "MATCH NUL";
      message = "Personne ne gagne !";
      accentColor = Colors.white70;
    } else {
      final winner = state.players.firstWhere((p) => p.id == state.winnerId);
      title = winner.isBot ? "DOMMAGE !" : "VICTOIRE !";
      message = "${winner.name} a gagné la partie.";
    }

    return Container(
      color: Colors.black.withOpacity(0.85),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.isDraw ? Icons.handshake : Icons.emoji_events,
            color: accentColor,
            size: 100,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () {
              ref.read(morpionProvider.notifier).resetGame();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'RETOUR AU SALON',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A148C),
        title: const Text('Quitter ?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment quitter la partie ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('NON', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: const Text(
              'OUI',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A148C),
        title: const Text(
          'Comment jouer ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Alignez 3 symboles identiques (horizontal, vertical ou diagonal) pour gagner !',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}

class _SymbolWidget extends StatelessWidget {
  final MorpionSymbol symbol;
  final bool isWinning;

  const _SymbolWidget({required this.symbol, this.isWinning = false});

  @override
  Widget build(BuildContext context) {
    if (symbol == MorpionSymbol.none) return const SizedBox.shrink();

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: 1,
      curve: Curves.elasticOut,
      child: symbol == MorpionSymbol.x
          ? CustomPaint(
              size: const Size(40, 40),
              painter: _XPainter(
                color: isWinning ? const Color(0xFFFFD700) : Colors.white,
              ),
            )
          : CustomPaint(
              size: const Size(40, 40),
              painter: _OPainter(
                color: isWinning ? const Color(0xFFFFD700) : Colors.white,
              ),
            ),
    );
  }
}

class _XPainter extends CustomPainter {
  final Color color;
  _XPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const padding = 10.0;
    canvas.drawLine(
      const Offset(padding, padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(padding, size.height - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _OPainter extends CustomPainter {
  final Color color;
  _OPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    const padding = 10.0;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width / 2) - padding,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
