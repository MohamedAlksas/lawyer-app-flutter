import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'api_provider.dart';

class DashboardStats {
  final int activeCases;
  final int todaySessions;
  final int upcomingDeadlines;

  const DashboardStats({
    this.activeCases = 0,
    this.todaySessions = 0,
    this.upcomingDeadlines = 0,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> m) => DashboardStats(
        activeCases: m['activeCases'] ?? 0,
        todaySessions: m['todaySessions'] ?? 0,
        upcomingDeadlines: m['upcomingDeadlines'] ?? 0,
      );
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final ApiService _api;
  final CacheService _cache = CacheService();

  DashboardNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      if (await _cache.isOnline) {
        final res = await _api.get('/dashboard/stats');
        await _cache.cache('dashboard_stats', res.data);
        state = AsyncValue.data(DashboardStats.fromMap(res.data));
      } else {
        final cached = await _cache.getCached('dashboard_stats');
        if (cached != null) {
          state = AsyncValue.data(DashboardStats.fromMap(cached as Map<String, dynamic>));
        }
      }
    } catch (e) {
      final cached = await _cache.getCached('dashboard_stats');
      if (cached != null) {
        state = AsyncValue.data(DashboardStats.fromMap(cached as Map<String, dynamic>));
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
  final api = ref.read(apiServiceProvider);
  return DashboardNotifier(api);
});
