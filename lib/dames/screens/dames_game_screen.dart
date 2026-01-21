import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../providers/dames_provider.dart';
import '../models/dames_models.dart';
import '../../widgets/generic_pattern.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stats_provider.dart';
import 'dart:ui';

class DamesGameScreen extends ConsumerStatefulWidget {
  const DamesGameScreen({super.key});

  @override
  ConsumerState<DamesGameScreen> createState() => _DamesGameScreenState();
}

class _DamesGameScreenState extends ConsumerState<DamesGameScreen> {
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
      SoundService.playBGM(SoundService.bgmDames, volume: 0.4);
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
    final state = ref.watch(damesProvider);

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

    ref.listen(damesProvider.select((s) => s.status), (prev, next) {
      if (next == DamesStatus.finished && prev != DamesStatus.finished) {
        if (state.winner != null) {
          // If human wins (User is usually White in single player, or check colors)
          // Assuming User plays White vs Bot Black? Setup says White Bottom.
          // In standard View, user is bottom.

          // Actually let's use the explicit check
          if (state.winner == DamesColor.white) {
            // White Won. If Single Player, User is White.
            ref.read(statsControllerProvider.notifier).recordWin('dames');
          } else {
            // Black Won. If Single Player, User Lost.
            ref.read(statsControllerProvider.notifier).recordLoss('dames');
          }

          if (state.isMultiplayer || state.winner == DamesColor.white) {
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
            colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
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
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state),
                  _buildTurnIndicator(state),
                  const Spacer(),
                  _buildBoard(state),
                  const Spacer(),
                  _buildLegend(state),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (state.status == DamesStatus.finished) _buildWinOverlay(state),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.white,
                  Colors.brown,
                  Color(0xFFFFD700),
                  Colors.black,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DamesState state) {
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
            'DAMES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(damesProvider.notifier).resetGame(),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(DamesState state) {
    if (state.status == DamesStatus.finished) return const SizedBox.shrink();

    bool isWhiteTurn = state.currentTurn == DamesColor.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isWhiteTurn ? Colors.white : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isWhiteTurn ? "TOUR DES BLANCS" : "TOUR DES NOIRS",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(DamesState state) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF42210B),
          border: Border.all(color: const Color(0xFF2E1505), width: 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final y = index ~/ 8;
            final x = index % 8;
            final pos = Position(x, y);
            final isDarkSquare = (x + y) % 2 != 0;
            final piece = state.board[pos];
            final isSelected = state.selectedPosition == pos;
            final isValidMove = state.validMoves.contains(pos);

            return GestureDetector(
              onTap: () {
                if (isValidMove) {
                  ref.read(damesProvider.notifier).movePiece(pos);
                } else {
                  ref.read(damesProvider.notifier).selectPiece(pos);
                }
              },
              child: Container(
                color: isDarkSquare
                    ? const Color(0xFF5D3A1A)
                    : const Color(0xFFD7B899),
                child: Stack(
                  children: [
                    if (isSelected)
                      Container(color: Colors.yellow.withOpacity(0.3)),
                    if (isValidMove && state.showHints)
                      Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (piece != null)
                      Center(
                        child: _PieceWidget(
                          piece: piece,
                          isSelected: isSelected,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(DamesState state) {
    int whiteCount = state.board.values.where((p) => p.isWhite).length;
    int blackCount = state.board.values.where((p) => p.isBlack).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildScore('BLANCS', whiteCount, Colors.white),
          _buildScore('NOIRS', blackCount, Colors.black),
        ],
      ),
    );
  }

  Widget _buildScore(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinOverlay(DamesState state) {
    final isWhiteWin = state.winner == DamesColor.white;
    final title = isWhiteWin ? "VICTOIRE BLANCS" : "VICTOIRE NOIRS";
    final color = isWhiteWin ? Colors.white : Colors.black;

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
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 120,
              ),
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
            const SizedBox(height: 16),
            const Text(
              "LA PARTIE EST TERMINÉE",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () {
                ref.read(damesProvider.notifier).resetGame();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
              ),
              child: const Text(
                'RETOUR AU SALON',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
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
        backgroundColor: const Color(0xFF3E2723),
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}

class _PieceWidget extends StatelessWidget {
  final DamesPiece piece;
  final bool isSelected;

  const _PieceWidget({required this.piece, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: piece.isWhite ? Colors.white : Colors.black,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: piece.isWhite ? Colors.black26 : Colors.white24,
          width: 2,
        ),
      ),
      child: piece.isKing
          ? const Center(
              child: Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
            )
          : null,
    );
  }
}
