import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  Directory? _cacheDir;

  Future<void> init() async {
    _cacheDir = Directory('${(await getApplicationDocumentsDirectory()).path}/cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w]'), '_');
  }

  Future<void> cache(String key, dynamic data) async {
    if (_cacheDir == null) return;
    final file = File('${_cacheDir!.path}/${_sanitizeKey(key)}.json');
    await file.writeAsString(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    }));
  }

  Future<dynamic> getCached(String key, {Duration? maxAge}) async {
    if (_cacheDir == null) return null;
    final file = File('${_cacheDir!.path}/${_sanitizeKey(key)}.json');
    if (!await file.exists()) return null;
    try {
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents);
      final timestamp = DateTime.parse(decoded['timestamp'] as String);
      if (maxAge != null && DateTime.now().difference(timestamp) > maxAge) {
        return null;
      }
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  String cacheKey(String endpoint, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return endpoint;
    final sorted = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final params = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '${endpoint}_$params';
  }

  Future<void> invalidate(String prefix) async {
    if (_cacheDir == null) return;
    final files = _cacheDir!.listSync().where((f) => f.path.contains(_sanitizeKey(prefix)));
    for (final f in files) {
      if (f is File) await f.delete();
    }
  }

  Future<void> clear() async {
    if (_cacheDir == null) return;
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }
}
