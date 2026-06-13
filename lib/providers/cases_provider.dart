import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/case.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'api_provider.dart';

class CasesState {
  final List<Case> items;
  final bool isLoading;
  final String? error;
  final int total;

  const CasesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
  });

  CasesState copyWith({
    List<Case>? items,
    bool? isLoading,
    String? error,
    int? total,
  }) =>
      CasesState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        total: total ?? this.total,
      );
}

class CasesNotifier extends StateNotifier<CasesState> {
  final ApiService _api;
  int _page = 1;
  String _query = '';
  String? _status;

  CasesNotifier(this._api) : super(const CasesState()) {
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
      final cacheKey = CacheService().cacheKey('/cases', {
        'page': _page,
        'search': _query,
        'status': _status,
      });

      if (refresh) {
        final cached = await CacheService().getCached(cacheKey);
        if (cached != null) {
          final items = (cached['items'] as List).map((e) => Case.fromMap(e)).toList();
          state = state.copyWith(items: items, total: cached['total']);
        }
      }

      final res = await _api.get('/cases', query: {
        'page': _page,
        'search': _query,
        'status': _status,
      });

      await CacheService().cache(cacheKey, res.data);

      final newItems = (res.data['items'] as List).map((e) => Case.fromMap(e)).toList();

      state = state.copyWith(
        isLoading: false,
        items: refresh ? newItems : _deduplicate([...state.items, ...newItems]),
        total: res.data['total'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<Case> _deduplicate(List<Case> items) {
    final ids = <String>{};
    return items.where((i) => ids.add(i.id)).toList();
  }

  Future<void> search(String query) {
    _query = query;
    return load(refresh: true);
  }

  Future<void> filterByStatus(String? status) {
    _status = status;
    return load(refresh: true);
  }

  Future<void> refresh() => load(refresh: true);
  Future<void> loadMore() {
    _page++;
    return load();
  }
}

final casesProvider = StateNotifierProvider<CasesNotifier, CasesState>((ref) {
  final api = ref.read(apiServiceProvider);
  return CasesNotifier(api);
});
