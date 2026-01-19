import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';
import 'services/sound_service.dart';
import 'providers/settings_provider.dart';
import 'screens/other_games_screen.dart';

import 'widgets/main_scaffold.dart';
import 'domino/screens/domino_game_screen.dart';
import 'domino/screens/domino_lobby_screen.dart';
import 'ludo/screens/ludo_game_screen.dart';
import 'ludo/screens/ludo_lobby_screen.dart';
import 'awale/screens/awale_game_screen.dart';
import 'awale/screens/awale_lobby_screen.dart';
import 'morpion/screens/morpion_game_screen.dart';
import 'morpion/screens/morpion_lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync settings with SoundService
    final settings = ref.watch(settingsProvider);
    SoundService.updateSettings(
      soundEnabled: settings.soundEnabled,
      musicEnabled: settings.musicEnabled,
      soundVolume: settings.soundVolume,
      musicVolume: settings.musicVolume,
    );

    return MaterialApp.router(
      title: 'AMERICAIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Favoris (Accueil désormais)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        // Tab 2: Autre
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/autre',
              builder: (context, state) => const OtherGamesScreen(),
            ),
          ],
        ),
        // Tab 3: Classic Games (Ex Américain)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/americain',
              builder: (context, state) => const HomeScreen(
                gameId: 'americain',
                title: 'CLASSIC GAMES',
                subtitle: '8 AMÉRICAIN & MORE',
              ),
            ),
          ],
        ),
        // Tab 4: Ludo
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ludo',
              builder: (context, state) => const HomeScreen(
                gameId: 'ludo',
                title: 'LUDO',
                subtitle: 'CLASSIC BOARD GAME',
                gradientColors: [
                  Color(0xFF1E88E5), // Blue 600
                  Color(0xFF0D47A1), // Blue 900
                ],
                isCardGame: false,
                createGameRoute: '/ludo/lobby',
                iconPath: 'assets/icon/ludo.png',
              ),
            ),
          ],
        ),
        // Tab 5: Awalé
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/awale',
              builder: (context, state) => const HomeScreen(
                gameId: 'awale',
                title: 'AWALÉ',
                subtitle: 'TRADITIONAL STRATEGY',
                gradientColors: [
                  Color(0xFF8D6E63), // Brown 400
                  Color(0xFF3E2723), // Brown 900
                ],
                isCardGame: false,
                createGameRoute: '/awale/lobby',
                iconPath: 'assets/icon/awale.png',
              ),
            ),
          ],
        ),
        // Tab 6: Paramètres
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full screen routes
    GoRoute(
      path: '/lobby',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'create';
        return LobbyScreen(mode: mode);
      },
    ),
    GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
    GoRoute(
      path: '/ludo/lobby',
      builder: (context, state) => const LudoLobbyScreen(),
    ),
    GoRoute(
      path: '/ludo/game',
      builder: (context, state) => const LudoGameScreen(),
    ),
    GoRoute(
      path: '/awale/lobby',
      builder: (context, state) => const AwaleLobbyScreen(),
    ),
    GoRoute(
      path: '/awale-game',
      builder: (context, state) => const AwaleGameScreen(),
    ),
    GoRoute(
      path: '/morpion/lobby',
      builder: (context, state) => const MorpionLobbyScreen(),
    ),
    GoRoute(
      path: '/morpion/game',
      builder: (context, state) => const MorpionGameScreen(),
    ),
    GoRoute(
      path: '/dominos/lobby',
      builder: (context, state) => const DominoLobbyScreen(),
    ),
    GoRoute(
      path: '/dominos/game',
      builder: (context, state) => const DominoGameScreen(),
    ),
  ],
);
