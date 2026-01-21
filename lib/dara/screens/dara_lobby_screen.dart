import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dara_provider.dart';
import '../models/dara_models.dart';
import '../../widgets/generic_pattern.dart';

class DaraLobbyScreen extends ConsumerStatefulWidget {
  const DaraLobbyScreen({super.key});

  @override
  ConsumerState<DaraLobbyScreen> createState() => _DaraLobbyScreenState();
}

class _DaraLobbyScreenState extends ConsumerState<DaraLobbyScreen> {
  bool _isSolo = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(daraProvider);
    final hasOngoingGame =
        state.status == DaraStatus.playing &&
        (state.p1PiecesToDrop < 12 || state.board.values.any((v) => v != null));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const GenericPattern(type: PatternType.board, opacity: 0.1),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (hasOngoingGame)
                        IconButton(
                          onPressed: () => context.push('/dara/game'),
                          icon: const Icon(
                            Icons.restore,
                            color: Colors.white,
                            size: 32,
                          ),
                          tooltip: 'Reprendre la partie',
                        ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Image.asset(
                      'assets/icon/dara.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DARA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'La perle d\'Afrique de l\'Ouest',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const Spacer(),
                  const Text(
                    'CHOISISSEZ VOTRE MODE',
                    style: TextStyle(
                      color: Colors.amber,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(daraProvider.notifier)
                            .startGame(isSolo: _isSolo);
                        context.push('/dara/game');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'DÉMARRER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildRulesButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
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
            color: isActive ? Colors.amber : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.amber : Colors.white70,
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
            if (isActive) const Icon(Icons.check_circle, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showRules(context),
      icon: const Icon(Icons.info_outline, color: Colors.white70),
      label: const Text(
        'Règles du jeu',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4E342E),
        title: const Text(
          'Règles du Dara',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(text: 'Phase 1 : Placez vos 12 pions à tour de rôle.'),
              _RuleItem(
                text: 'Interdiction de former 3 pions consécutifs à la pose.',
              ),
              _RuleItem(
                text: 'Phase 2 : Déplacez un pion d\'une case orthogonalement.',
              ),
              _RuleItem(
                text:
                    'L\'alignement d\'exactement 3 pions permet de capturer un pion adverse.',
              ),
              _RuleItem(text: 'Gagnez quand l\'adversaire a moins de 3 pions.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('COMPRIS', style: TextStyle(color: Colors.amber)),
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
          const Text('• ', style: TextStyle(color: Colors.amber, fontSize: 18)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
