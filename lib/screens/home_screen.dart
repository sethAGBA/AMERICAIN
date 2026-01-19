import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/recent_games_provider.dart';
import '../widgets/generic_pattern.dart';
import '../ludo/ludo_rules.dart';

/// Home screen with main menu
class HomeScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final bool isCardGame;
  final String? createGameRoute;
  final String? iconPath; // Path to game-specific icon
  final String gameId;
  final PatternType? patternType;

  const HomeScreen({
    super.key,
    required this.gameId,
    this.title = 'AMERICAIN',
    this.subtitle = 'PREMIUM CARD GAME',
    this.gradientColors = const [
      Color(0xFF43A047), // Vibrant Emerald Green 600
      Color(0xFF1B5E20), // Darker Forest Green 800
    ],
    this.isCardGame = true,
    this.createGameRoute,
    this.iconPath,
    this.patternType,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    SoundService.playBGM(settings.homeMusicPath);
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to music path changes
    ref.listen(settingsProvider.select((s) => s.homeMusicPath), (
      previous,
      next,
    ) {
      if (next != previous) {
        SoundService.playBGM(next);
      }
    });

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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: widget.gradientColors,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GenericPattern(
                type:
                    widget.patternType ??
                    (widget.gameId == 'ludo'
                        ? PatternType.board
                        : widget.gameId == 'awale'
                        ? PatternType.circles
                        : widget.gameId == 'americain'
                        ? PatternType.suits
                        : widget.gameId == 'autre'
                        ? PatternType.dice
                        : PatternType.circles),
                opacity: 0.1,
                crossAxisCount: 6,
              ),
            ),

            // Favorite Button
            Positioned(
              top: 16,
              right: 16,
              child: Consumer(
                builder: (context, ref, child) {
                  final isFav = ref
                      .watch(favoritesProvider)
                      .contains(widget.gameId);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white70,
                      size: 32,
                    ),
                    onPressed: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(widget.gameId);
                    },
                  );
                },
              ),
            ),

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
                          widget.iconPath ?? 'assets/icon/americain.png',
                          height: 80,
                          width: 80,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        widget.title,
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
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFFD700), // Gold
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Menu buttons
                      if (widget.isCardGame) ...[
                        _MenuButton(
                          icon: Icons.add_circle_outline,
                          label: 'Créer une partie',
                          onPressed: () {
                            ref
                                .read(recentGamesProvider.notifier)
                                .addGame(widget.gameId);
                            context.push('/lobby?mode=create');
                          },
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
                      ] else ...[
                        // Non-card games
                        if (widget.createGameRoute != null)
                          Column(
                            children: [
                              _MenuButton(
                                icon: Icons.play_circle_fill,
                                label: 'JOUER',
                                onPressed: () {
                                  ref
                                      .read(recentGamesProvider.notifier)
                                      .addGame(widget.gameId);
                                  context.push(widget.createGameRoute!);
                                },
                                isPrimary: true,
                              ),
                              if (widget.title == 'LUDO') ...[
                                const SizedBox(height: 16),
                                _MenuButton(
                                  icon: Icons.help_outline,
                                  label: 'Comment jouer',
                                  onPressed: () => _showHowToPlay(context),
                                ),
                              ],
                            ],
                          )
                        else
                          _MenuButton(
                            icon: Icons.hourglass_empty,
                            label: 'Bientôt disponible',
                            onPressed: () {},
                            isPrimary: true,
                          ),
                      ],
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
              if (!widget.isCardGame && widget.title == 'LUDO') ...[
                ...LudoRules.rules.map(
                  (rule) => _RuleSection(
                    title: rule['title']!,
                    content: rule['content']!,
                  ),
                ),
              ] else ...[
                const _RuleSection(
                  title: 'Objectif',
                  content:
                      'Se débarrasser de ses cartes. Le gagnant devient le nouveau donneur.',
                ),
                const _RuleSection(
                  title: 'Attaques (Pénalités)',
                  content:
                      '• AS : Le suivant pioche 1 carte.\n'
                      '• 2 Normaux (♥♦♣) : Suivant +2, puis le 2eme suivant +1.\n'
                      '• 2 de Pique (♠2) : Suivant +4, puis +2, puis +1.\n'
                      '• Joker : Le suivant pioche 4 cartes. Il se glisse **sous** la pile pour transférer la pénalité sans changer la couleur de base.\n'
                      '⚠️ Les pénalités ne se cumulent pas si elles sont bloquées.',
                ),
                const _RuleSection(
                  title: 'Défenses & Blocages',
                  content:
                      '• Bloquer un AS : Un autre AS ou un 8.\n'
                      '• Bloquer un 2 : Un autre 2 ou un 8.\n'
                      '• Bloquer le ♠2 : SEULEMENT un autre ♠2 ou un Joker (transfert).\n'
                      '• Joker : SEULEMENT un autre Joker (Transfert).\n'
                      '🛡️ Après un blocage par un 2, vous devez rejouer une carte de même couleur ou un autre 2.',
                ),
                const _RuleSection(
                  title: 'Accompagnement (7 & Valet)',
                  content:
                      '• 7 : Doit être accompagné d\'une carte de MÊME COULEUR.\n'
                      '• Valet : Doit être accompagné de N\'IMPORTE QUELLE carte.\n'
                      '🔒 Séquence protégée : Personne ne peut jouer pendant que vous accompagnez.\n'
                      '🚫 Jeu anticipé : Celui qui joue avant pioche X cartes (X = nb de joueurs).',
                ),
                const _RuleSection(
                  title: 'Règles Spéciales',
                  content:
                      '• 8 (Bloqueur) : Change la couleur. Bloque AS et 2.\n'
                      '• Anti-Aide : Interdit de changer la couleur avec un 8 juste pour libérer un joueur qui vient de piocher une pénalité.\n'
                      '• 10 : Inverse le sens immédiatement.\n'
                      '• Valet de Pique (♠J) : Saute 2 joueurs. En 1v1, il vous saute vous-même.',
                ),
                const _RuleSection(
                  title: 'Fin de Manche & Score',
                  content:
                      '• Fin : Dès qu\'un joueur n\'a plus de cartes.\n'
                      '• Score : On additionne les points restants en main des perdants.\n'
                      '• Donneur : Le gagnant distribue la manche suivante.',
                ),
                const _RuleSection(
                  title: 'Valeur des Points',
                  content:
                      '• Joker : 50 pts | 8 : 64 pts\n'
                      '• Valet : 11 pts (22 pts pour ♠J)\n'
                      '• 10 : 10 pts | 7 : 7 pts\n'
                      '• As / Roi / Dame : 1 pt\n'
                      '• Autres : Valeur nominale (ex: 5 = 5 pts)',
                ),
                const _RuleSection(
                  title: 'Début de Partie',
                  content:
                      'Si la 1ere carte retournée est :\n'
                      '• 8 : Le donneur annonce la couleur.\n'
                      '• 10 : Le sens est inversé d\'entrée.\n'
                      '• Valet : Le 1er joueur est sauté.\n'
                      '• As / 2 : Le 1er joueur subit la pénalité.\n'
                      '• Joker : Pas de sanction, le 1er joueur joue n\'importe quelle carte.',
                ),
              ],
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
