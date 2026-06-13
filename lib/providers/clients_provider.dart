import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'api_provider.dart';

class ClientsState {
  final List<Client> items;
  final bool isLoading;
  final String? error;
  final int total;

  const ClientsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
  });

  ClientsState copyWith({
    List<Client>? items,
    bool? isLoading,
    String? error,
    int? total,
  }) =>
      ClientsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        total: total ?? this.total,
      );
}

class ClientsNotifier extends StateNotifier<ClientsState> {
  final ApiService _api;
  int _page = 1;
  String _query = '';

  ClientsNotifier(this._api) : super(const ClientsState()) {
    load();
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      state = state.copyWith(isLoading: true);
    } else if (state.items.length >= state.total && state.total > 0) {
      return;
    }

    try {
      final cacheKey = CacheService().cacheKey('/clients', {'page': _page, 'search': _query});
      if (refresh) {
        final cached = await CacheService().getCached(cacheKey);
        if (cached != null) {
          final items = (cached['items'] as List).map((e) => Client.fromMap(e)).toList();
          state = state.copyWith(items: items, total: cached['total']);
        }
      }

      final res = await _api.get('/clients', query: {
        'page': _page,
        'search': _query,
      });

      await CacheService().cache(cacheKey, res.data);

      final newItems = (res.data['items'] as List).map((e) => Client.fromMap(e)).toList();

      state = state.copyWith(
        isLoading: false,
        items: refresh ? newItems : _deduplicate([...state.items, ...newItems]),
        total: res.data['total'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<Client> _deduplicate(List<Client> items) {
    final ids = <String>{};
    return items.where((i) => ids.add(i.id)).toList();
  }

  Future<void> search(String query) {
    _query = query;
    return load(refresh: true);
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
