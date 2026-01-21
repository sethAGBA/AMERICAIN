import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dara_provider.dart';
import '../models/dara_models.dart';
import '../widgets/dara_widgets.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';

class DaraGameScreen extends ConsumerStatefulWidget {
  const DaraGameScreen({super.key});

  @override
  ConsumerState<DaraGameScreen> createState() => _DaraGameScreenState();
}

class _DaraGameScreenState extends ConsumerState<DaraGameScreen> {
  DaraSquare? _selectedSquare;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(daraProvider);
    final notifier = ref.read(daraProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
              ),
            ),
            child: const GenericPattern(type: PatternType.board, opacity: 0.1),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state, notifier),
                _buildScoreBoard(state),
                _buildPhaseIndicator(state),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DaraBoardWidget(
                    board: state.board,
                    phase: state.phase,
                    selectedSquare: _selectedSquare,
                    onSquareTap: (sq) {
                      if (state.phase == DaraPhase.move) {
                        if (state.board[sq] == state.currentTurn) {
                          setState(() => _selectedSquare = sq);
                        } else if (_selectedSquare != null) {
                          notifier.onMove(_selectedSquare!, sq);
                          setState(() => _selectedSquare = null);
                        }
                      } else {
                        notifier.onSquareTap(sq);
                      }
                    },
                    onMove: (from, to) {
                      notifier.onMove(from, to);
                      setState(() => _selectedSquare = null);
                    },
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          if (state.status == DaraStatus.finished)
            _buildGameOverOverlay(context, state, notifier),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DaraGameState state,
    DaraNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _confirmExit(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Column(
            children: [
              const Text(
                'DARA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              Text(
                state.currentTurn == DaraPiece.player1
                    ? 'TOUR DES BLANCS'
                    : 'TOUR DES NOIRS',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _confirmReset(context, notifier),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(DaraGameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerScore(
            "BLANC",
            state.p1Score,
            state.p1PiecesToDrop,
            DaraPiece.player1,
          ),
          const Text(
            "VS",
            style: TextStyle(
              color: Colors.white24,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildPlayerScore(
            "NOIR",
            state.p2Score,
            state.p2PiecesToDrop,
            DaraPiece.player2,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(
    String label,
    int score,
    int toDrop,
    DaraPiece piece,
  ) {
    return Column(
      children: [
        DaraPieceWidget(piece: piece, size: 24),
        const SizedBox(height: 8),
        Text(
          score.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (toDrop > 0)
          Text(
            "RESTANTS : $toDrop",
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicator(DaraGameState state) {
    String text = "";
    Color color = Colors.amber;
    if (state.phase == DaraPhase.drop) {
      text = "PHASE DE POSE";
    } else if (state.phase == DaraPhase.move) {
      text = "PHASE DE MOUVEMENT";
      color = Colors.greenAccent;
    } else {
      text = "CAPTUREZ UN PION !";
      color = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(
    BuildContext context,
    DaraGameState state,
    DaraNotifier notifier,
  ) {
    final winner = state.p1Score >= 3 ? "BLANC" : "NOIR";
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const SizedBox(height: 24),
            const Text(
              "VICTOIRE !",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "LES $winner ONT GAGNÉ",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text("QUITTER"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => notifier.resetGame(),
                  child: const Text("REJOUER"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, DaraNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4E342E),
        title: const Text(
          "Réinitialiser ?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Voulez-vous recommencer la partie ?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("NON", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              notifier.resetGame();
              context.pop();
            },
            child: const Text("OUI", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GameExitDialog(
        title: 'Quitter ?',
        content: 'Voulez-vous vraiment quitter la partie de Dara ?',
        onConfirm: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }
}
