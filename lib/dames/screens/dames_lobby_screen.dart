import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dames_provider.dart';
import '../../widgets/generic_pattern.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class DamesLobbyScreen extends ConsumerStatefulWidget {
  const DamesLobbyScreen({super.key});

  @override
  ConsumerState<DamesLobbyScreen> createState() => _DamesLobbyScreenState();
}

class _DamesLobbyScreenState extends ConsumerState<DamesLobbyScreen> {
  bool _isMultiplayer = false;
  bool _isCaptureMandatory = true;
  bool _showHints = true;

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
            colors: [Color(0xFF8D6E63), Color(0xFF4E342E)], // Wooden theme
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        const Text(
                          'DAMES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                          ),
                          onPressed: () => _showRules(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'CHOISISSEZ VOTRE MODE',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildModeButton(
                      title: 'SOLO',
                      subtitle: 'Contre l\'ordinateur',
                      icon: Icons.computer,
                      isActive: !_isMultiplayer,
                      onTap: () => setState(() => _isMultiplayer = false),
                    ),
                    const SizedBox(height: 16),
                    _buildModeButton(
                      title: 'MULTIJOUEUR',
                      subtitle: '2 joueurs en local',
                      icon: Icons.people,
                      isActive: _isMultiplayer,
                      onTap: () => setState(() => _isMultiplayer = true),
                    ),
                    const SizedBox(height: 32),
                    _buildSettingsSection(),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(damesProvider.notifier)
                              .setupGame(
                                isMultiplayer: _isMultiplayer,
                                isCaptureMandatory: _isCaptureMandatory,
                                showHints: _showHints,
                              );
                          context.push('/dames/game');
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildToggle(
            title: 'Prise obligatoire',
            subtitle: 'Règle officielle des dames',
            value: _isCaptureMandatory,
            onChanged: (val) => setState(() => _isCaptureMandatory = val),
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildToggle(
            title: 'Afficher les aides',
            subtitle: 'Montrer les déplacements possibles',
            value: _showHints,
            onChanged: (val) => setState(() => _showHints = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFFFFD700),
          activeTrackColor: const Color(0xFFFFD700).withOpacity(0.3),
          inactiveThumbColor: Colors.white60,
          inactiveTrackColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFD700) : Colors.white70,
              size: 32,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
          ],
        ),
      ),
    );
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4E342E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFFFFD700)),
            SizedBox(width: 12),
            Text(
              'RÈGLES DES DAMES',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(
                text:
                    'Les pions se déplacent d\'une case en diagonale vers l\'avant.',
              ),
              _RuleItem(
                text: 'La capture est obligatoire si elle est possible.',
              ),
              _RuleItem(
                text:
                    'On peut capturer plusieurs pièces à la suite avec le même pion.',
              ),
              _RuleItem(
                text: 'Un pion atteignant la dernière ligne devient une Dame.',
              ),
              _RuleItem(
                text:
                    'La Dame se déplace de plusieurs cases dans toutes les directions.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'COMPRIS',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 18),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
