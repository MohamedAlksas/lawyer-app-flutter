import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'api_provider.dart';

class ClientsState {
  final List<Client> clients;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final String searchQuery;

  const ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.searchQuery = '',
  });

  ClientsState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? error,
    int? totalCount,
    String? searchQuery,
  }) =>
      ClientsState(
        clients: clients ?? this.clients,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        totalCount: totalCount ?? this.totalCount,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class ClientsNotifier extends StateNotifier<ClientsState> {
  final ApiService _api;
  final CacheService _cache = CacheService();
  int _page = 1;
  static const int _limit = 20;

  ClientsNotifier(this._api) : super(const ClientsState());

  Future<void> load({String? query, bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      state = state.copyWith(isLoading: true, error: null);
    }
    final params = <String, dynamic>{'page': _page, 'limit': _limit};
    final sq = query ?? state.searchQuery;
    if (sq.isNotEmpty) params['search'] = sq;
    final cacheKey = _cache.cacheKey('/clients', params);
    try {
      if (await _cache.isOnline) {
        final res = await _api.get('/clients', query: params);
        final items = (res.data['data'] as List).map((e) => Client.fromMap(e)).toList();
        await _cache.cache(cacheKey, {'data': res.data['data'], 'total': res.data['total'] ?? items.length});
        state = state.copyWith(
          clients: refresh ? items : [...state.clients, ...items],
          totalCount: res.data['total'] ?? items.length,
          isLoading: false,
          searchQuery: sq,
        );
      } else {
        final cached = await _cache.getCached(cacheKey);
        if (cached != null) {
          final items = (cached['data'] as List).map((e) => Client.fromMap(e)).toList();
          state = state.copyWith(
            clients: refresh ? items : [...state.clients, ...items],
            totalCount: cached['total'] ?? items.length,
            isLoading: false,
            searchQuery: sq,
          );
        }
      }
    } catch (e) {
      final cached = await _cache.getCached(cacheKey);
      if (cached != null) {
        final items = (cached['data'] as List).map((e) => Client.fromMap(e)).toList();
        state = state.copyWith(
          clients: refresh ? items : [...state.clients, ...items],
          totalCount: cached['total'] ?? items.length,
          isLoading: false,
          searchQuery: sq,
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

  Future<void> refresh() => load(refresh: true);
  Future<void> loadMore() {
    _page++;
    return load();
  }
}

final clientsProvider = StateNotifierProvider<ClientsNotifier, ClientsState>((ref) {
  final api = ref.read(apiServiceProvider);
  return ClientsNotifier(api);
});
