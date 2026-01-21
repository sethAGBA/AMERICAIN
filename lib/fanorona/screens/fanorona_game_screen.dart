import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/fanorona_provider.dart';
import '../models/fanorona_game_state.dart';
import '../widgets/fanorona_widgets.dart';
import '../../widgets/game_exit_dialog.dart';
import '../../widgets/generic_pattern.dart';

class FanoronaGameScreen extends ConsumerStatefulWidget {
  const FanoronaGameScreen({super.key});

  @override
  ConsumerState<FanoronaGameScreen> createState() => _FanoronaGameScreenState();
}

class _FanoronaGameScreenState extends ConsumerState<FanoronaGameScreen> {
  BoardPoint? _selectedPoint;
  List<BoardPoint> _validMoves = [];

  void _onPointTap(BoardPoint point) {
    final state = ref.read(fanoronaProvider);

    if (_selectedPoint == null) {
      // Selecting a piece
      if (state.board[point] == state.currentPlayer) {
        if (state.capturingPiece != null && point != state.capturingPiece) {
          // If in sequence, must move the same piece
          return;
        }
        setState(() {
          _selectedPoint = point;
          _validMoves = ref
              .read(fanoronaProvider.notifier)
              .getValidMoves(point);
        });
      }
    } else {
      // Selecting destination or another piece
      if (_validMoves.contains(point)) {
        ref.read(fanoronaProvider.notifier).movePiece(_selectedPoint!, point);
        setState(() {
          _selectedPoint = null;
          _validMoves = [];
        });
      } else if (state.board[point] == state.currentPlayer) {
        // Change selection
        if (state.capturingPiece != null) {
          return; // Cannot change during sequence
        }
        setState(() {
          _selectedPoint = point;
          _validMoves = ref
              .read(fanoronaProvider.notifier)
              .getValidMoves(point);
        });
      } else {
        // Deselect
        setState(() {
          _selectedPoint = null;
          _validMoves = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fanoronaProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const GenericPattern(type: PatternType.board, opacity: 0.1),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                const Spacer(),
                _buildBoard(context, state),
                const Spacer(),
                _buildFooter(context, state),
              ],
            ),
          ),

          if (state.status == FanoronaStatus.won)
            _buildWinOverlay(context, state),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FanoronaGameState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(fanoronaProvider.notifier).startGame(),
          ),
          Column(
            children: [
              const Text(
                'FANORONA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                state.currentPlayer == FanoronaPiece.white
                    ? 'Tour : BLANC'
                    : 'Tour : NOIR',
                style: TextStyle(
                  color: state.currentPlayer == FanoronaPiece.white
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  Widget _buildBoard(BuildContext context, FanoronaGameState state) {
    return AspectRatio(
      aspectRatio: 9 / 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const margin = 25.0;
            final boardWidth = constraints.maxWidth - (margin * 2);
            final boardHeight = constraints.maxHeight - (margin * 2);
            final cellWidth = boardWidth / 8;
            final cellHeight = boardHeight / 4;

            return Stack(
              children: [
                // Board Painter
                Positioned(
                  left: margin,
                  top: margin,
                  width: boardWidth,
                  height: boardHeight,
                  child: CustomPaint(
                    painter: FanoronaBoardPainter(
                      board: state.board,
                      validMoves: _validMoves,
                      selectedPoint: _selectedPoint,
                      showHints: state.showHints,
                    ),
                  ),
                ),
                // Interactive Area
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (details) {
                      final x =
                          ((details.localPosition.dx - margin) / cellWidth)
                              .round();
                      final y =
                          ((details.localPosition.dy - margin) / cellHeight)
                              .round();
                      if (x >= 0 && x < 9 && y >= 0 && y < 5) {
                        _onPointTap(BoardPoint(x, y));
                      }
                    },
                  ),
                ),
                // Pieces
                ...state.board.entries.where((e) => e.value != null).map((e) {
                  final p = e.key;
                  final type = e.value!;
                  return Positioned(
                    left: margin + (p.x * cellWidth) - 15,
                    top: margin + (p.y * cellHeight) - 15,
                    width: 30,
                    height: 30,
                    child: IgnorePointer(
                      child: FanoronaPieceWidget(
                        type: type,
                        isCapturing: state.capturingPiece == p,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, FanoronaGameState state) {
    // Only show the skip button if turn is in sequence AND it's not mandatory to finish
    final showSkipButton =
        state.capturingPiece != null && !state.isSequenceMandatory;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: showSkipButton
          ? ElevatedButton(
              onPressed: () =>
                  ref.read(fanoronaProvider.notifier).skipSequence(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('TERMINER LE TOUR'),
            )
          : const SizedBox(height: 48),
    );
  }

  Widget _buildWinOverlay(BuildContext context, FanoronaGameState state) {
    final winnerText = state.winner == FanoronaPiece.white
        ? 'BLANC GAGNE !'
        : 'NOIR GAGNE !';
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const SizedBox(height: 24),
            Text(
              winnerText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('QUITTER'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(fanoronaProvider.notifier).startGame(),
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
          context.pop();
        },
      ),
    );
  }
}
