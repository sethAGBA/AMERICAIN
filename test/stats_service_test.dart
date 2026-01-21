import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeu_8_americain/services/stats_service.dart';

void main() {
  group('StatsService Tests', () {
    late StatsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = StatsService();
    });

    test('Initial load should return empty list', () async {
      final stats = await service.loadStats();
      expect(stats, isEmpty);
    });

    test('Increment win should save correctly', () async {
      await service.incrementWin('game1');
      var stats = await service.loadStats();

      expect(stats, hasLength(1));
      expect(stats.first.gameId, 'game1');
      expect(stats.first.wins, 1);
      expect(stats.first.losses, 0);

      await service.incrementWin('game1');
      stats = await service.loadStats();
      expect(stats.first.wins, 2);
    });

    test('Increment loss should save correctly', () async {
      await service.incrementLoss('game2');
      final stats = await service.loadStats();

      expect(stats, hasLength(1));
      expect(stats.first.gameId, 'game2');
      expect(stats.first.wins, 0);
      expect(stats.first.losses, 1);
    });

    test('Get stats for specific game', () async {
      await service.incrementWin('game3');
      await service.incrementLoss('game3');

      final stat = await service.getStatsForGame('game3');
      expect(stat.gameId, 'game3');
      expect(stat.wins, 1);
      expect(stat.losses, 1);
    });

    test('Get stats for unknown game should return empty stats', () async {
      final stat = await service.getStatsForGame('unknown');
      expect(stat.gameId, 'unknown');
      expect(stat.wins, 0);
      expect(stat.losses, 0);
    });
  });
}
