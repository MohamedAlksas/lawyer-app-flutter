import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _userKey = 'currentUser';

  Future<User> login(String email, String password) async {
    final res = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data;
    await _api.setTokens(data['accessToken'], data['refreshToken']);
    final user = User.fromMap(data['user']);
    await _storage.write(key: _userKey, value: jsonEncode(data['user']));
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearTokens();
    await _storage.delete(key: _userKey);
  }

  Future<void> refreshToken() => _api.post('/auth/refresh');

  Future<bool> isLoggedIn() => _api.hasToken();

  Future<User?> getCurrentUser() async {
    try {
      final stored = await _storage.read(key: _userKey);
      if (stored != null) return User.fromMap(jsonDecode(stored));
      return null;
    } catch (_) {
      return null;
    }
  }
}
