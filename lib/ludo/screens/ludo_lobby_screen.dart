import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ludo_provider.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_piece.dart';
import '../../widgets/generic_pattern.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class LudoLobbyScreen extends ConsumerStatefulWidget {
  const LudoLobbyScreen({super.key});

  @override
  ConsumerState<LudoLobbyScreen> createState() => _LudoLobbyScreenState();
}

class _LudoLobbyScreenState extends ConsumerState<LudoLobbyScreen> {
  final List<PlayerType> _slots = [
    PlayerType.human, // Red
    PlayerType.human, // Green
    PlayerType.human, // Yellow
    PlayerType.human, // Blue
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    if (settings.musicEnabled) {
      SoundService.playBGM(settings.lobbyMusicPath);
    }
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
    ref.listen(settingsProvider.select((s) => s.lobbyMusicPath), (
      previous,
      next,
    ) {
      if (next != previous) {
        SoundService.playBGM(next);
      }
    });

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
            SafeArea(
              child: Column(
                children: [
                  // Custom Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Text(
                          'SALON LUDO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Configuration des Joueurs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choisissez qui joue pour chaque couleur.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            Expanded(
                              child: ListView.separated(
                                itemCount: 4,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final color = LudoColor.values[index];
                                  return _buildSlotRow(index, color);
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (_hasInProgressGame(gameState))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ElevatedButton(
                                  onPressed: () => context.go('/ludo/game'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'REPRENDRE LA PARTIE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                            ElevatedButton(
                              onPressed: _canStart() ? _handleStart : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'DÉMARRER LA PARTIE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotRow(int index, LudoColor color) {
    final colorValue = _getDisplayColor(color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorValue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorValue.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorValue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorValue.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getColorName(color),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorValue.withValues(alpha: 0.8),
                  ),
                ),
                _buildTypeSelector(index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(int index) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTypeChip(index, PlayerType.human, 'Humain', Icons.face),
        _buildTypeChip(index, PlayerType.bot, 'Robot', Icons.smart_toy),
        _buildTypeChip(index, PlayerType.none, 'Désactivé', Icons.block),
      ],
    );
  }

  Widget _buildTypeChip(
    int index,
    PlayerType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _slots[index] == type;
    final color = _getDisplayColor(LudoColor.values[index]);

    return InkWell(
      onTap: () {
        setState(() {
          _slots[index] = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDisplayColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return Colors.red.shade600;
      case LudoColor.green:
        return Colors.green.shade600;
      case LudoColor.yellow:
        return Colors.orange.shade500;
      case LudoColor.blue:
        return Colors.blue.shade600;
    }
  }

  String _getColorName(LudoColor color) {
    return 'JOUEUR ${color.frenchName}';
  }

  bool _canStart() {
    final activeCount = _slots.where((s) => s != PlayerType.none).length;
    return activeCount >= 2;
  }

  bool _hasInProgressGame(LudoGameState gameState) {
    // A game is in progress if it's not the default initial state
    // We can check if any piece is NOT in jail or if winners is not empty
    bool anyPieceOut = gameState.players.any(
      (p) => p.pieces.any((pc) => pc.state != PieceState.inJail),
    );
    return anyPieceOut || gameState.winners.isNotEmpty;
  }

  void _handleStart() {
    ref.read(ludoProvider.notifier).startNewGame(_slots);
    context.go('/ludo/game');
  }
}
