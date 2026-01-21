import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/othello_provider.dart';
import '../../widgets/generic_pattern.dart';

class OthelloLobbyScreen extends ConsumerStatefulWidget {
  const OthelloLobbyScreen({super.key});

  @override
  ConsumerState<OthelloLobbyScreen> createState() => _OthelloLobbyScreenState();
}

class _OthelloLobbyScreenState extends ConsumerState<OthelloLobbyScreen> {
  bool _isSolo = true;

  @override
  Widget build(BuildContext context) {
    final hasOngoingGame = ref.watch(othelloProvider).moveHistory.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF000000)],
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
                          onPressed: () => context.push('/othello/game'),
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
                  const Icon(Icons.circle, size: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'OTHELLO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'L\'élégance de la stratégie',
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
                            .read(othelloProvider.notifier)
                            .startGame(isSolo: _isSolo);
                        context.push('/othello/game');
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
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Règles de l\'Othello',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(
                text:
                    'Le but est d\'avoir le plus de pions de sa couleur à la fin.',
              ),
              _RuleItem(
                text: 'On encadre des pions adverses pour les retourner.',
              ),
              _RuleItem(
                text:
                    'Les pions peuvent être retournés horizontalement, verticalement ou en diagonale.',
              ),
              _RuleItem(
                text: 'Si un joueur ne peut pas jouer, il passe son tour.',
              ),
              _RuleItem(
                text:
                    'Le jeu s\'arrête quand le plateau est plein ou qu\'aucun joueur ne peut jouer.',
              ),
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
