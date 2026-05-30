import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/api_service.dart';
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
  int _page = 1;
  static const int _limit = 20;

  ClientsNotifier(this._api) : super(const ClientsState());

  Future<void> load({String? query, bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final params = <String, dynamic>{'page': _page, 'limit': _limit};
      if ((query ?? state.searchQuery).isNotEmpty) {
        params['search'] = query ?? state.searchQuery;
      }
      final res = await _api.get('/clients', query: params);
      final items = (res.data['data'] as List).map((e) => Client.fromMap(e)).toList();
      state = state.copyWith(
        clients: refresh ? items : [...state.clients, ...items],
        totalCount: res.data['total'] ?? items.length,
        isLoading: false,
        searchQuery: query ?? state.searchQuery,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
