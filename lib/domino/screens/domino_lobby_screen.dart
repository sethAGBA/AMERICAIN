import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/domino_provider.dart';
import '../../widgets/generic_pattern.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class DominoLobbyScreen extends ConsumerStatefulWidget {
  const DominoLobbyScreen({super.key});

  @override
  ConsumerState<DominoLobbyScreen> createState() => _DominoLobbyScreenState();
}

class _DominoLobbyScreenState extends ConsumerState<DominoLobbyScreen> {
  int _humanCount = 1;
  int _botCount = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dominoProvider.notifier).setupGame(_humanCount, _botCount);
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.board,
                opacity: 0.1,
                crossAxisCount: 8,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (GoRouter.of(context).canPop()) {
                              context.pop();
                            } else {
                              context.go('/autre');
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                          ),
                          onPressed: _showRulesDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DOMINOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const Text(
                      'CONFIGURER LA PARTIE',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Joueurs Humains',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCountSelector(
                            current: _humanCount,
                            options: [1, 2, 3, 4],
                            onChanged: (val) {
                              setState(() {
                                _humanCount = val;
                                // Adjust bot count if total > 4
                                if (_humanCount + _botCount > 4) {
                                  _botCount = 4 - _humanCount;
                                }
                              });
                              ref
                                  .read(dominoProvider.notifier)
                                  .setupGame(_humanCount, _botCount);
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Nombre de Bots',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCountSelector(
                            current: _botCount,
                            options: List.generate(5 - _humanCount, (i) => i),
                            onChanged: (val) {
                              setState(() => _botCount = val);
                              ref
                                  .read(dominoProvider.notifier)
                                  .setupGame(_humanCount, _botCount);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(dominoProvider.notifier).startGame();
                          context.push('/dominos/game');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'DÉMARRER',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountSelector({
    required int current,
    required List<int> options,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((count) {
        bool isSelected = current == count;
        return GestureDetector(
          onTap: () => onChanged(count),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD700) : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRulesDialog() {
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
