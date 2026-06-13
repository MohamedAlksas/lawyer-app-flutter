import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  static const String _boxName = 'app_cache';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> cache(String key, dynamic data) async {
    await _box.put(key, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    });
  }

  Future<dynamic> getCached(String key, {Duration? maxAge}) async {
    final val = _box.get(key);
    if (val == null) return null;

    final timestamp = val['timestamp'] as int;
    if (maxAge != null) {
      final cachedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedDate) > maxAge) {
        return null;
      }
    }
    return val['data'];
  }

  String cacheKey(String endpoint, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return endpoint;
    final sorted = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final params = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '${endpoint}_$params';
  }

  Future<void> invalidate(String prefix) async {
    final keys = _box.keys.where((k) => k.toString().startsWith(prefix));
    await _box.deleteAll(keys);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
