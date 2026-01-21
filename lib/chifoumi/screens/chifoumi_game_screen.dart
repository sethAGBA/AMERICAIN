import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../providers/chifoumi_provider.dart';
import '../models/chifoumi_move.dart';
import '../models/chifoumi_state.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class ChifoumiGameScreen extends ConsumerStatefulWidget {
  const ChifoumiGameScreen({super.key});

  @override
  ConsumerState<ChifoumiGameScreen> createState() => _ChifoumiGameScreenState();
}

class _ChifoumiGameScreenState extends ConsumerState<ChifoumiGameScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    if (settings.musicEnabled) {
      SoundService.playBGM(settings.gameMusicPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Confetti Trigger
    ref.listen(chifoumiProvider, (previous, next) {
      if (next.resultMessage == 'GAGNÉ !' &&
          previous?.resultMessage != 'GAGNÉ !') {
        _confettiController.play();
        SoundService.playWin();
      } else if (next.resultMessage == 'PERDU !' &&
          previous?.resultMessage != 'PERDU !') {
        SoundService.playLose();
      }
    });

    final state = ref.watch(chifoumiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF311B92),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Battle Arena
                      Spacer(),
                      // Bot Move
                      _buildMoveAvatar(
                        move: state.botMove,
                        isMe: false,
                        isHidden: !state.isRevealing,
                        label: 'Bot',
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Player Move
                      _buildMoveAvatar(
                        move: state.playerMove,
                        isMe: true,
                        isHidden: state.playerMove == null,
                        label: 'Vous',
                      ),
                      Spacer(),
                    ],
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ChifoumiMove.values.map((move) {
                      return _buildMoveButton(
                        move,
                        () =>
                            ref.read(chifoumiProvider.notifier).playMove(move),
                        state.isRevealing, // disable details if revealing
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

            // Result Overlay
            if (state.isRevealing) _buildResultOverlay(context, state),

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
                  Colors.purple,
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
    double degToRad(double deg) => deg * (math.pi / 180.0);

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

  Widget _buildHeader(BuildContext context, ChifoumiState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () => _showRulesDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _confirmExit(context),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  '${state.playerScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '-',
                    style: TextStyle(color: Colors.white54, fontSize: 20),
                  ),
                ),
                Text(
                  '${state.botScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.computer, color: Colors.redAccent),
              ],
            ),
          ),
          // Balancer
          const SizedBox(width: 96),
        ],
      ),
    );
  }

  Widget _buildMoveAvatar({
    required ChifoumiMove? move,
    required bool isMe,
    required bool isHidden,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isHidden ? Colors.white10 : move!.color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHidden ? Colors.white24 : move!.color,
              width: 4,
            ),
            boxShadow: isHidden
                ? []
                : [
                    BoxShadow(
                      color: move!.color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Center(
            child: isHidden
                ? const Icon(
                    Icons.question_mark,
                    size: 48,
                    color: Colors.white24,
                  )
                : Icon(move!.icon, size: 64, color: move.color),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isHidden ? (isMe ? 'Choisissez...' : 'Attente...') : move!.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMoveButton(
    ChifoumiMove move,
    VoidCallback onTap,
    bool disabled,
  ) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(move.icon, color: move.color, size: 32),
              const SizedBox(height: 4),
              Text(
                move.label,
                style: TextStyle(
                  color: move.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay(BuildContext context, ChifoumiState state) {
    final isWin = state.resultMessage == 'GAGNÉ !';
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWin) ...[
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    state.resultMessage ?? '',
                    style: TextStyle(
                      color: _getResultColor(state.resultMessage),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _confettiController.stop(); // Stop confetti on next round
                      ref.read(chifoumiProvider.notifier).nextRound();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF311B92),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('MANCHE SUIVANTE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getResultColor(String? msg) {
    if (msg == 'GAGNÉ !') return Colors.green;
    if (msg == 'PERDU !') return Colors.red;
    return Colors.orange;
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quitter la partie ?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Voulez-vous vraiment quitter ce duel intense ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/chifoumi/lobby');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'RÈGLES DU CHIFOUMI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleItem(text: '👊 La Pierre écrase les Ciseaux'),
            _RuleItem(text: '🖐 La Feuille enveloppe la Pierre'),
            _RuleItem(text: '✌️ Les Ciseaux coupent la Feuille'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'COMBATTRE !',
              style: TextStyle(color: Color(0xFFFFD700)),
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
