import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_stats.dart';
import '../services/stats_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});

final gameStatsProvider = FutureProvider.autoDispose<List<GameStats>>((
  ref,
) async {
  final service = ref.watch(statsServiceProvider);
  return service.loadStats();
});

final specificGameStatsProvider = FutureProvider.autoDispose
    .family<GameStats, String>((ref, gameId) async {
      final service = ref.watch(statsServiceProvider);
      return service.getStatsForGame(gameId);
    });

// Controller for updating stats and refreshing the UI
class StatsController extends StateNotifier<AsyncValue<void>> {
  final StatsService _service;
  final Ref _ref;

  StatsController(this._service, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> recordWin(String gameId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.incrementWin(gameId);
      // Invalidate providers to trigger refresh
      _ref.invalidate(gameStatsProvider);
      _ref.invalidate(specificGameStatsProvider(gameId));
    });
  }

  Future<void> recordLoss(String gameId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.incrementLoss(gameId);
      // Invalidate providers to trigger refresh
      _ref.invalidate(gameStatsProvider);
      _ref.invalidate(specificGameStatsProvider(gameId));
    });
  }
}

final statsControllerProvider =
    StateNotifierProvider<StatsController, AsyncValue<void>>((ref) {
      final service = ref.watch(statsServiceProvider);
      return StatsController(service, ref);
    });
