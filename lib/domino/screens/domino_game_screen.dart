import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../providers/domino_provider.dart';
import '../models/domino_piece.dart';
import '../../widgets/generic_pattern.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class DominoGameScreen extends ConsumerStatefulWidget {
  const DominoGameScreen({super.key});

  @override
  ConsumerState<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends ConsumerState<DominoGameScreen> {
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
    final state = ref.watch(dominoProvider);

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

    // Listen for game end to trigger confetti and sounds
    ref.listen(dominoProvider.select((s) => s.status), (previous, next) {
      if (next == DominoStatus.finished && previous != DominoStatus.finished) {
        final winnerId = ref.read(dominoProvider).winnerId;
        final winner = ref
            .read(dominoProvider)
            .players
            .firstWhere((p) => p.id == winnerId);

        if (!winner.isBot) {
          _confettiController.play();
          SoundService.playWin();
        } else {
          SoundService.playLose();
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.board,
                opacity: 0.05,
                crossAxisCount: 10,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, state),

                  // Opponents
                  _buildOpponents(state),

                  // Board
                  Expanded(child: _buildBoard(state)),

                  // Status message
                  if (state.lastMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        state.lastMessage!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Current Human player hand
                  if (!state.isHandoverInProgress) _buildPlayerHand(state, ref),
                ],
              ),
            ),
            if (state.isHandoverInProgress) _buildHandoverOverlay(state, ref),
            if (state.status == DominoStatus.finished)
              _buildWinOverlay(context, state),

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

  Widget _buildHandoverOverlay(DominoState state, WidgetRef ref) {
    final currentPlayer = state.players[state.currentTurn];
    return Container(
      color: Colors.black.withOpacity(0.9),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phonelink_setup, color: Color(0xFFFFD700), size: 80),
          const SizedBox(height: 24),
          Text(
            'AU TOUR DE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentPlayer.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Passez le téléphone !',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(dominoProvider.notifier).setHandoverComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'JE SUIS PRÊT',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DominoState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showRulesDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              _showExitDialog(context);
            },
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'DOMINOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'PIOCHE: ${state.deck.length}',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balancing back button
        ],
      ),
    );
  }

  Widget _buildOpponents(DominoState state) {
    final currentPlayerIndex = state.currentTurn;
    final opponents = <DominoPlayer>[];

    // Get all players except the current human if it's their turn
    // Or just all other players from the perspective of the current player
    for (int i = 1; i < state.players.length; i++) {
      int idx = (currentPlayerIndex + i) % state.players.length;
      opponents.add(state.players[idx]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((opp) {
          bool isTurn = state.players[state.currentTurn].id == opp.id;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTurn
                        ? const Color(0xFFFFD700)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Text(
                    opp.name[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opp.name,
                style: TextStyle(
                  color: isTurn ? const Color(0xFFFFD700) : Colors.white70,
                  fontSize: 12,
                  fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '${opp.hand.length} pcs',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoard(DominoState state) {
    if (state.board.isEmpty) {
      return const Center(
        child: Text(
          'Veuillez poser la première pièce',
          style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 50),
        itemCount: state.board.length,
        itemBuilder: (context, index) {
          final piece = state.board[index];
          // Determine orientation logic simplified for MVP
          // In a real app we'd rotate pieces to match values
          return Center(child: _DominoWidget(piece: piece));
        },
      ),
    );
  }

  Widget _buildPlayerHand(DominoState state, WidgetRef ref) {
    final currentPlayer = state.players[state.currentTurn];
    if (currentPlayer.isBot) {
      return const SizedBox(height: 150);
    }

    bool isMyTurn = true; // Since we are showing the current player's hand

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentPlayer.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (isMyTurn && !ref.watch(dominoProvider.notifier).canPlayAny())
                ElevatedButton(
                  onPressed: () =>
                      ref.read(dominoProvider.notifier).drawPiece(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(state.deck.isEmpty ? 'PASSER' : 'PIOCHER'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentPlayer.hand.length,
              itemBuilder: (context, index) {
                final piece = currentPlayer.hand[index];
                final canPlay =
                    isMyTurn &&
                    ref.read(dominoProvider.notifier).canPlay(piece);

                return GestureDetector(
                  onTap: canPlay
                      ? () => _showPlayOptions(context, ref, piece)
                      : null,
                  child: Opacity(
                    opacity: canPlay || !isMyTurn ? 1.0 : 0.5,
                    child: _DominoWidget(piece: piece, isVertical: true),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // This method is new and was not in the original code.
  // It's needed for the _buildPlayerHand's GestureDetector onTap.
  void _showPlayOptions(
    BuildContext context,
    WidgetRef ref,
    DominoPiece piece,
  ) {
    final notifier = ref.read(dominoProvider.notifier);
    final state = ref.read(dominoProvider);

    final canLeft = state.board.isEmpty || piece.contains(state.leftValue!);
    final canRight = state.board.isEmpty || piece.contains(state.rightValue!);

    if (canLeft &&
        canRight &&
        state.board.isNotEmpty &&
        state.leftValue != state.rightValue) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0D47A1),
          title: const Text(
            'Où jouer ?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Ce domino peut être joué des deux côtés du plateau.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.playPiece(piece, atLeft: true);
              },
              child: const Text(
                'GAUCHE',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.playPiece(piece, atLeft: false);
              },
              child: const Text(
                'DROITE',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      // Direct play if only one choice or empty board
      notifier.playPiece(piece, atLeft: canLeft);
    }
  }

  Widget _buildWinOverlay(BuildContext context, DominoState state) {
    final winner = state.players.firstWhere((p) => p.id == state.winnerId);
    final isBotWinner = winner.isBot;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 100),
            const SizedBox(height: 24),
            Text(
              isBotWinner ? 'FIN DE PARTIE' : 'FÉLICITATIONS !',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBotWinner
                  ? '${winner.name} a gagné'
                  : '${winner.name} gagne la partie !',
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 24),
            ),
            const SizedBox(height: 16),
            Text(
              state.lastMessage ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                _confettiController.stop();
                if (GoRouter.of(context).canPop()) {
                  context.pop(); // Returns to Lobby
                } else {
                  context.go('/autre');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text('RETOUR AU SALON'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quitter la partie ?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Voulez-vous vraiment quitter cette partie en cours ?',
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
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/autre');
              }
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

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Règles des Dominos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleItem(
                '🎯 Objectif',
                'Être le premier à poser tous ses dominos ou avoir le moins de points en cas de blocage.',
              ),
              _buildRuleItem(
                '🎮 Distribution',
                'Chaque joueur reçoit 7 dominos au départ.',
              ),
              _buildRuleItem(
                '✨ Le Plateau',
                'Les dominos sont posés bout à bout. Les chiffres des extrémités doivent correspondre.',
              ),
              _buildRuleItem(
                '🎴 La Pioche',
                'Si vous ne pouvez pas jouer, vous piochez jusqu\'à trouver un coup valide ou que la pioche soit vide.',
              ),
              _buildRuleItem(
                '🏆 Fin de partie',
                'La partie s\'arrête quand un joueur vide sa main ou quand plus aucun coup n\'est possible.',
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
              color: Color(0xFFFFD700),
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
}

class _DominoWidget extends StatelessWidget {
  final DominoPiece piece;
  final bool isVertical;

  const _DominoWidget({required this.piece, this.isVertical = false});

  @override
  Widget build(BuildContext context) {
    // Fix: Use 2:1 ratio.
    // User requested larger size (matching hand).
    // Using 35x70 provides a good size (bigger than 28x56, close to original 40x80 equivalent area)
    const double shortSide = 35;
    const double longSide = 70; // 2 * shortSide // 2:1 ratio

    return Container(
      width: isVertical ? shortSide : longSide,
      height: isVertical ? longSide : shortSide,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Flex(
        direction: isVertical ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            child: Center(child: _Dots(value: piece.sideA)),
          ),
          Container(
            width: isVertical ? double.infinity : 2,
            height: isVertical ? 2 : double.infinity,
            color: Colors.black26,
          ),
          Expanded(
            child: Center(child: _Dots(value: piece.sideB)),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int value;
  const _Dots({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.shrink();

    // Simple dot layout
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: List.generate(value, (index) {
        return Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
