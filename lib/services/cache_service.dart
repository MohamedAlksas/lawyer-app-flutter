import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  Future<void> init() async {
    // No-op for web
  }

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w]'), '_');
  }

  Future<void> cache(String key, dynamic data) async {
    // No-op for web
  }

  Future<dynamic> getCached(String key, {Duration? maxAge}) async {
    return null;
  }

  String cacheKey(String endpoint, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return endpoint;
    final sorted = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final params = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '${endpoint}_$params';
  }

  Future<void> invalidate(String prefix) async {
    // No-op for web
  }

  Future<void> clear() async {
    // No-op for web
  }
}
