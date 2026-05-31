import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/case.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'api_provider.dart';

class CasesState {
  final List<Case> cases;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final String searchQuery;
  final String? statusFilter;

  const CasesState({
    this.cases = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.searchQuery = '',
    this.statusFilter,
  });

  CasesState copyWith({
    List<Case>? cases,
    bool? isLoading,
    String? error,
    int? totalCount,
    String? searchQuery,
    String? statusFilter,
  }) =>
      CasesState(
        cases: cases ?? this.cases,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        totalCount: totalCount ?? this.totalCount,
        searchQuery: searchQuery ?? this.searchQuery,
        statusFilter: statusFilter ?? this.statusFilter,
      );
}

class CasesNotifier extends StateNotifier<CasesState> {
  final ApiService _api;
  final CacheService _cache = CacheService();
  int _page = 1;
  static const int _limit = 20;

  CasesNotifier(this._api) : super(const CasesState());

  Future<void> load({String? query, String? status, bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      state = state.copyWith(isLoading: true, error: null);
    }
    final params = <String, dynamic>{'page': _page, 'limit': _limit};
    final sq = query ?? state.searchQuery;
    final sf = status ?? state.statusFilter;
    if (sq.isNotEmpty) params['search'] = sq;
    if (sf != null && sf != 'ALL') params['status'] = sf;
    final cacheKey = _cache.cacheKey('/cases', params);
    try {
      if (await _cache.isOnline) {
        final res = await _api.get('/cases', query: params);
        final items = (res.data['data'] as List).map((e) => Case.fromMap(e)).toList();
        await _cache.cache(cacheKey, {'data': res.data['data'], 'total': res.data['total'] ?? items.length});
        state = state.copyWith(
          cases: refresh ? items : [...state.cases, ...items],
          totalCount: res.data['total'] ?? items.length,
          isLoading: false,
          searchQuery: sq,
          statusFilter: sf,
        );
      } else {
        final cached = await _cache.getCached(cacheKey);
        if (cached != null) {
          final items = (cached['data'] as List).map((e) => Case.fromMap(e)).toList();
          state = state.copyWith(
            cases: refresh ? items : [...state.cases, ...items],
            totalCount: cached['total'] ?? items.length,
            isLoading: false,
            searchQuery: sq,
            statusFilter: sf,
          );
        }
      }
    } catch (e) {
      final cached = await _cache.getCached(cacheKey);
      if (cached != null) {
        final items = (cached['data'] as List).map((e) => Case.fromMap(e)).toList();
        state = state.copyWith(
          cases: refresh ? items : [...state.cases, ...items],
          totalCount: cached['total'] ?? items.length,
          isLoading: false,
          searchQuery: sq,
          statusFilter: sf,
          error: 'بيانات مخزنة محلياً (غير متصل)',
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await load(query: query, refresh: true);
  }

  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(statusFilter: status);
    await load(status: status, refresh: true);
  }

  Future<void> refresh() => load(refresh: true);
}

final casesProvider = StateNotifierProvider<CasesNotifier, CasesState>((ref) {
  final api = ref.read(apiServiceProvider);
  return CasesNotifier(api);
});
