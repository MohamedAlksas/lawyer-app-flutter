import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'api_provider.dart';

class CalendarState {
  final List<Session> sessions;
  final bool isLoading;
  final String? error;
  final int year;
  final int month;

  const CalendarState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.year = 0,
    this.month = 0,
  });

  CalendarState copyWith({
    List<Session>? sessions,
    bool? isLoading,
    String? error,
    int? year,
    int? month,
  }) =>
      CalendarState(
        sessions: sessions ?? this.sessions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        year: year ?? this.year,
        month: month ?? this.month,
      );
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final ApiService _api;
  final CacheService _cache = CacheService();

  CalendarNotifier(this._api) : super(const CalendarState());

  Future<void> load(int year, int month) async {
    state = state.copyWith(isLoading: true, year: year, month: month);
    final params = {'year': year, 'month': month};
    final cacheKey = _cache.cacheKey('/sessions/calendar', params);
    try {
      if (await _cache.isOnline) {
        final res = await _api.get('/sessions/calendar', query: params);
        final items = (res.data as List?)?.map((e) => Session.fromMap(e)).toList() ?? [];
        await _cache.cache(cacheKey, res.data);
        state = state.copyWith(sessions: items, isLoading: false);
      } else {
        final cached = await _cache.getCached(cacheKey);
        if (cached != null) {
          final items = (cached as List).map((e) => Session.fromMap(e)).toList();
          state = state.copyWith(sessions: items, isLoading: false);
        }
      }
    } catch (e) {
      final cached = await _cache.getCached(cacheKey);
      if (cached != null) {
        final items = (cached as List).map((e) => Session.fromMap(e)).toList();
        state = state.copyWith(sessions: items, isLoading: false, error: 'بيانات مخزنة محلياً (غير متصل)');
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final api = ref.read(apiServiceProvider);
  return CalendarNotifier(api);
});
