import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/fanorona_provider.dart';
import '../../services/sound_service.dart';
import '../../providers/settings_provider.dart';

class FanoronaLobbyScreen extends ConsumerStatefulWidget {
  const FanoronaLobbyScreen({super.key});

  @override
  ConsumerState<FanoronaLobbyScreen> createState() =>
      _FanoronaLobbyScreenState();
}

class _FanoronaLobbyScreenState extends ConsumerState<FanoronaLobbyScreen> {
  bool _showHints = true;
  bool _isSolo = true;
  bool _isSequenceMandatory = false;

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8D6E63), // Brown
              Color(0xFF4E342E), // Dark Brown
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    const Text(
                      'FANORONA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
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
                const SizedBox(height: 24),
                _buildModeButton(
                  title: 'SOLO',
                  subtitle: 'Contre l\'ordinateur',
                  icon: Icons.computer,
                  isActive: _isSolo,
                  onTap: () => setState(() => _isSolo = true),
                ),
                const SizedBox(height: 16),
                _buildModeButton(
                  title: 'MULTIJOUEUR',
                  subtitle: '2 joueurs en local',
                  icon: Icons.people,
                  isActive: !_isSolo,
                  onTap: () => setState(() => _isSolo = false),
                ),
                const Spacer(),
                _buildSettingsSection(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(fanoronaProvider.notifier)
                          .startGame(
                            showHints: _showHints,
                            isSolo: _isSolo,
                            isSequenceMandatory: _isSequenceMandatory,
                          );
                      context.push('/fanorona/game');
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
                      'JOUER',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _showRules(),
                  icon: const Icon(Icons.help_outline, color: Colors.white70),
                  label: const Text(
                    'RÈGLES',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
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
        title: const Text(
          'RÈGLES DU FANORONA',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(
                text: 'But : Capturer toutes les pièces de l\'adversaire.',
              ),
              _RuleItem(
                text:
                    'Capture par Approche : Déplacez-vous vers une pièce adverse adjacente.',
              ),
              _RuleItem(
                text:
                    'Capture par Retrait : Éloignez-vous d\'une pièce adverse adjacente.',
              ),
              _RuleItem(
                text:
                    'Séries : Une pièce qui capture peut continuer son mouvement tant qu\'elle peut capturer d\'autres pièces.',
              ),
              _RuleItem(
                text:
                    'Restriction : Une pièce ne peut pas revenir sur un point déjà visité lors d\'une série, ni reprendre la même direction.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'COMPRIS',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildToggle(
            title: 'Afficher les aides',
            subtitle: 'Montrer les déplacements possibles',
            value: _showHints,
            onChanged: (val) => setState(() => _showHints = val),
          ),
          const Divider(color: Colors.white10),
          _buildToggle(
            title: 'Séquence obligatoire',
            subtitle:
                'Impossible de terminer le tour avant la fin des captures',
            value: _isSequenceMandatory,
            onChanged: (val) => setState(() => _isSequenceMandatory = val),
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
          activeThumbColor: const Color(0xFFFFD700),
          activeTrackColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
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
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
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
