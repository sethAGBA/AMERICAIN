import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/game_data.dart';
import '../providers/favorites_provider.dart';
import '../widgets/generic_pattern.dart';

class OtherGamesScreen extends StatelessWidget {
  const OtherGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF455A64), // Blue Grey 700
              Color(0xFF263238), // Blue Grey 900
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.dice,
                opacity: 0.1,
                crossAxisCount: 6,
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROCHAINEMENT',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nouveaux Défis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildCategory('CLASSIQUES', GameCategory.classics),
                  _buildCategory('STRATÉGIE', GameCategory.strategy),
                  _buildCategory('CULTUREL', GameCategory.cultural),
                  _buildCategory('CARTES', GameCategory.cards),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(String title, GameCategory category) {
    final games = GameData.getByCategory(category).where((g) {
      // Exclude games that have their own main tabs
      return g.id != 'americain' && g.id != 'ludo' && g.id != 'awale';
    }).toList();

    if (games.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: games.length,
              itemBuilder: (context, index) {
                return _UpcomingGameCard(game: games[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingGameCard extends ConsumerWidget {
  final GameData game;

  const _UpcomingGameCard({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(game.id);

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (game.isImplemented && game.route != null) {
                context.push(game.route!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${game.title} arrive bientôt !'),
                    backgroundColor: const Color(0xFF263238),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          game.icon,
                          color: const Color(0xFFFFD700),
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        game.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(game.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                      if (!game.isImplemented) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOON',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
