import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/suit_pattern.dart';

/// Home screen with main menu
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFF43A047), // Vibrant Emerald Green 600
              const Color(0xFF1B5E20), // Darker Forest Green 800
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Suit Pattern
            const Positioned.fill(child: SuitPattern()),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Game title
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          height: 80,
                          width: 80,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'AMERICAIN',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'PREMIUM CARD GAME',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFFD700), // Gold
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Menu buttons
                      _MenuButton(
                        icon: Icons.add_circle_outline,
                        label: 'Créer une partie',
                        onPressed: () => context.push('/lobby?mode=create'),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        icon: Icons.login,
                        label: 'Rejoindre une partie',
                        onPressed: () => context.push('/lobby?mode=join'),
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        icon: Icons.help_outline,
                        label: 'Comment jouer',
                        onPressed: () => _showHowToPlay(context),
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        onPressed: () => _showSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF5E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'RÈGLES COMPLÈTES',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RuleSection(
                title: 'Objectif',
                content:
                    'Se débarrasser de ses cartes. Le gagnant devient le nouveau donneur.',
              ),
              _RuleSection(
                title: 'Attaques (Pénalités)',
                content:
                    '• AS : Le suivant pioche 1 carte.\n'
                    '• 2 Normaux (♥♦♣) : Suivant +2, puis le 2eme suivant +1.\n'
                    '• 2 de Pique (♠2) : Suivant +4, puis +2, puis +1.\n'
                    '• Joker : Le suivant pioche 4 cartes.\n'
                    '⚠️ Les pénalités ne se cumulent pas si elles sont bloquées.',
              ),
              _RuleSection(
                title: 'Défenses & Blocages',
                content:
                    '• Bloquer un AS : Un autre AS ou un 8.\n'
                    '• Bloquer un 2 : Un autre 2 ou un 8.\n'
                    '• Bloquer le ♠2 : SEULEMENT un autre ♠2.\n'
                    '• Joker : SEULEMENT un autre Joker (Transfert).\n'
                    '🛡️ Après un blocage, vous devez rejouer une carte de même couleur ou valeur.',
              ),
              _RuleSection(
                title: 'Accompagnement (7 & Valet)',
                content:
                    '• 7 : Doit être accompagné d\'une carte de MÊME COULEUR.\n'
                    '• Valet : Doit être accompagné de N\'IMPORTE QUELLE carte.\n'
                    '🔒 Séquence protégée : Personne ne peut jouer pendant que vous accompagnez.\n'
                    '🚫 Jeu anticipé : Celui qui joue avant pioche X cartes (X = nb de joueurs).',
              ),
              _RuleSection(
                title: 'Règles Spéciales',
                content:
                    '• 8 (Bloqueur) : Change la couleur. Interdit d\'aider un joueur qui vient de piocher une pénalité s\'il y a d\'autres cartes jouables (Anti-Aide).\n'
                    '• 10 : Inverse le sens immédiatement.\n'
                    '• Valet de Pique (♠J) : Saute 2 joueurs. En 1v1, vous saute vous-même.',
              ),
              _RuleSection(
                title: 'Début de Partie',
                content:
                    'Si la 1ere carte retournée est :\n'
                    '• 8 : Le donneur annonce la couleur.\n'
                    '• 10 : Le sens est inversé d\'entrée.\n'
                    '• Valet : Le 1er joueur est sauté.\n'
                    '• As/2/Joker : Le 1er joueur subit la pénalité.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'J\'AI TOUT COMPRIS !',
              style: TextStyle(
                color: Color(0xFF1B4D3E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF5E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Paramètres'),
        content: const Text('Réglages du son et des bots à venir !'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(color: Color(0xFF1B4D3E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final String content;

  const _RuleSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Use container decoration
          foregroundColor: const Color(0xFF1B4D3E),
          padding: EdgeInsets.zero, // Padding handled by container
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.black12)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? const Color(0xFFFFD700) : Colors.grey.shade300,
              width: isPrimary ? 3 : 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF1B5E20), // Dark Green text
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
