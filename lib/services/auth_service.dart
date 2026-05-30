import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<User> login(String email, String password) async {
    final res = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data;
    await _api.setTokens(data['accessToken'], data['refreshToken']);
    return User.fromMap(data['user']);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearTokens();
  }

  Future<void> refreshToken() => _api.post('/auth/refresh');

  Future<bool> isLoggedIn() => _api.hasToken();

  Future<User?> getCurrentUser() async {
    try {
      final res = await _api.get('/auth/me');
      return User.fromMap(res.data['user']);
    } catch (_) {
      return null;
    }
  }
}
