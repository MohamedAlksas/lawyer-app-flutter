import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({User? user, bool? isLoading, String? error, bool? isInitialized}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isInitialized: isInitialized ?? this.isInitialized,
      );

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  String? _fcmToken;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> init() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final user = await _authService.getCurrentUser();
      state = AuthState(user: user, isInitialized: true);
      if (user != null) _registerFcm();
    } else {
      state = const AuthState(isInitialized: true);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      state = AuthState(user: user, isInitialized: true);
      _registerFcm();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    if (_fcmToken != null) {
      await NotificationService().unregisterToken(_fcmToken);
    }
    state = const AuthState(isInitialized: true);
  }

  Future<void> _registerFcm() async {
    final token = await NotificationService().getToken();
    if (token != null) {
      _fcmToken = token;
      await NotificationService().registerToken(token);
    }
  }

  String _parseError(Object e) {
    if (e is Exception) {
      final s = e.toString();
      if (s.contains('Invalid email or password')) return 'Invalid email or password';
      if (s.contains('401')) return 'Invalid email or password';
    }
    return 'Login failed. Check your connection and try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = AuthService();
  return AuthNotifier(service);
});
