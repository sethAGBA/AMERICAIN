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
      title: 'CLASSIC GAMES',
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
      subtitle: 'CLASSIC',
      description: 'Stratégie intemporelle.',
      icon: Icons.grid_4x4,
      category: GameCategory.classics,
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
      id: 'solitaire',
      title: 'Solitaire',
      subtitle: 'CLASSIC',
      description: 'Zen et réflexion.',
      icon: Icons.style,
      category: GameCategory.classics,
    ),

    // Strategy
    GameData(
      id: 'echecs',
      title: 'Échecs',
      subtitle: 'STRATEGY',
      description: 'Maîtrisez l\'art de la guerre.',
      icon: Icons.extension,
      category: GameCategory.strategy,
    ),
    GameData(
      id: 'othello',
      title: 'Othello',
      subtitle: 'STRATEGY',
      description: 'Inversez la situation.',
      icon: Icons.radio_button_checked,
      category: GameCategory.strategy,
    ),
    GameData(
      id: 'sudoku',
      title: 'Sudoku',
      subtitle: 'STRATEGY',
      description: 'Le roi du puzzle numérique.',
      icon: Icons.numbers,
      category: GameCategory.strategy,
    ),

    // Cultural
    GameData(
      id: 'dara',
      title: 'Dara',
      subtitle: 'CULTURAL',
      description: 'La perle d\'Afrique de l\'Ouest.',
      icon: Icons.stars,
      category: GameCategory.cultural,
    ),
    GameData(
      id: 'fanorona',
      title: 'Fanorona',
      subtitle: 'CULTURAL',
      description: 'Le génie malgache.',
      icon: Icons.diamond,
      category: GameCategory.cultural,
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
