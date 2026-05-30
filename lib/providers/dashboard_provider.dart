import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
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

  DashboardNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final res = await _api.get('/dashboard/stats');
      state = AsyncValue.data(DashboardStats.fromMap(res.data));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
  final api = ref.read(apiServiceProvider);
  return DashboardNotifier(api);
});
