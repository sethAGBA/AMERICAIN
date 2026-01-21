import 'package:flutter/material.dart';

enum GameCategory { classics, strategy, cultural, cards }

class GameData {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String? iconPath;
  final GameCategory category;
  final String? route;
  final List<Color>? gradientColors;
  final bool isImplemented;

  const GameData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.iconPath,
    required this.category,
    this.route,
    this.gradientColors,
    this.isImplemented = false,
  });

  static const List<GameData> allGames = [
    // Implemented Games
    GameData(
      id: 'americain',
      title: 'AMERICAIN',
      subtitle: '8 AMÉRICAIN',
      description: 'Le célèbre jeu de cartes stratégique.',
      icon: Icons.style,
      iconPath: 'assets/icon/americain.png',
      category: GameCategory.cards,
      route: '/americain',
      isImplemented: true,
    ),
    GameData(
      id: 'ludo',
      title: 'LUDO',
      subtitle: 'BOARD GAME',
      description: 'Le jeu de petits chevaux revisité.',
      icon: Icons.casino,
      iconPath: 'assets/icon/ludo.png',
      category: GameCategory.classics,
      route: '/ludo',
      isImplemented: true,
    ),
    GameData(
      id: 'awale',
      title: 'AWALÉ',
      subtitle: 'STRATEGY GAME',
      description: 'Jeu traditionnel de semailles d\'Afrique.',
      icon: Icons.blur_on,
      iconPath: 'assets/icon/awale.png',
      category: GameCategory.cultural,
      route: '/awale',
      isImplemented: true,
    ),

    // Upcoming Games - Classiques
    GameData(
      id: 'domino',
      title: 'Dominos',
      subtitle: 'LE GRAND CLASSIQUE',
      description: 'Le grand classique africain',
      icon: Icons.filter_2,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/dominos/lobby',
      gradientColors: [Color(0xFF1E88E5), Color(0xFF0D47A1)], // Blues
    ),
    GameData(
      id: 'dames',
      title: 'Dames',
      subtitle: 'STRATÉGIE',
      description: 'Capturez toutes les pièces adverses.',
      icon: Icons.grid_4x4,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/dames/lobby',
      gradientColors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
    ),
    GameData(
      id: 'morpion',
      title: 'Morpion',
      subtitle: 'SIMPLE & RAPIDE',
      description: 'Alignez 3 symboles pour gagner.',
      icon: Icons.close,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/morpion/lobby',
      gradientColors: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
    ),
    GameData(
      id: 'puissance4',
      title: 'Puissance 4',
      subtitle: 'ALIGNEMENT',
      description: 'Alignez 4 jetons pour gagner.',
      icon: Icons.grid_view,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/puissance4/lobby',
      gradientColors: [Color(0xFFD32F2F), Color(0xFFB71C1C)], // Red Theme
    ),
    GameData(
      id: 'pendu',
      title: 'Le Pendu',
      subtitle: 'MOTS',
      description: 'Devinez le mot avant qu\'il ne soit trop tard.',
      icon: Icons.abc,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/pendu',
      gradientColors: [
        Color(0xFF263238),
        Color(0xFF37474F),
      ], // Blackboard Theme
    ),
    GameData(
      id: 'memory',
      title: 'Memory',
      subtitle: 'MÉMOIRE',
      description: 'Retrouvez toutes les paires.',
      icon: Icons.psychology,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/memory/lobby',
      gradientColors: [Color(0xFF4A148C), Color(0xFF311B92)],
    ),
    GameData(
      id: 'chifoumi',
      title: 'Chifoumi',
      subtitle: 'PIERRE PAPIER CISEAUX',
      description: 'Le duel ancestral en un geste.',
      icon: Icons.front_hand,
      category: GameCategory.classics,
      isImplemented: true,
      route: '/chifoumi/lobby',
      gradientColors: [const Color(0xFF4A148C), const Color(0xFF311B92)],
    ),

    // Strategy
    GameData(
      id: 'echecs',
      title: 'Échecs',
      subtitle: 'STRATEGY',
      description: 'Le roi des jeux de stratégie.',
      icon: Icons.extension,
      category: GameCategory.strategy,
      isImplemented: true,
      route: '/chess/lobby',
      gradientColors: [Color(0xFF3E2723), Color(0xFF1B1B1B)],
    ),
    GameData(
      id: 'othello',
      title: 'Othello',
      subtitle: 'STRATEGY',
      description: 'Inversez la situation.',
      icon: Icons.radio_button_checked,
      category: GameCategory.strategy,
      isImplemented: true,
      route: '/othello/lobby',
      gradientColors: [Color(0xFF1B5E20), Color(0xFF000000)],
    ),
    GameData(
      id: 'sudoku',
      title: 'Sudoku',
      subtitle: 'STRATEGY',
      description: 'Le roi du puzzle numérique.',
      icon: Icons.numbers,
      category: GameCategory.strategy,
      isImplemented: true,
      route: '/sudoku/lobby',
      gradientColors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
    ),

    // Cultural
    GameData(
      id: 'dara',
      title: 'Dara',
      subtitle: 'CULTURAL',
      description: 'La perle d\'Afrique de l\'Ouest.',
      icon: Icons.stars,
      category: GameCategory.cultural,
      isImplemented: true,
      route: '/dara/lobby',
      iconPath: 'assets/icon/dara.png',
      gradientColors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
    ),
    GameData(
      id: 'fanorona',
      title: 'Fanorona',
      subtitle: 'CULTURAL',
      description: 'Le génie malgache.',
      icon: Icons.diamond,
      category: GameCategory.cultural,
      isImplemented: true,
      route: '/fanorona/lobby',
      gradientColors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
    ),

    // Cards
    GameData(
      id: 'whot',
      title: 'Whot',
      subtitle: 'CARDS',
      description: 'Le favori nigérian.',
      icon: Icons.amp_stories,
      category: GameCategory.cards,
    ),
    GameData(
      id: 'belote',
      title: 'Belote',
      subtitle: 'CARDS',
      description: 'L\'incontournable.',
      icon: Icons.layers,
      category: GameCategory.cards,
    ),
    GameData(
      id: 'president',
      title: 'Président',
      subtitle: 'CARDS',
      description: 'Le jeu du Trouduc.',
      icon: Icons.military_tech,
      category: GameCategory.cards,
    ),
    GameData(
      id: 'solitaire',
      title: 'Solitaire',
      subtitle: 'KLONDIKE',
      description: 'Le classique du jeu de patience.',
      icon: Icons.style,
      category: GameCategory.cards,
      route: '/solitaire/lobby',
      isImplemented: true,
      gradientColors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
    ),
  ];

  static GameData? getById(String id) {
    try {
      return allGames.firstWhere((game) => game.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<GameData> getByCategory(GameCategory category) {
    return allGames.where((game) => game.category == category).toList();
  }
}
