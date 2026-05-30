import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiService _api;

  NotificationsNotifier(this._api) : super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get('/notifications');
      final rawList = (res.data['data'] ?? res.data['notifications'] ?? []) as List;
      final items = rawList.map((e) => NotificationModel.fromMap(e)).toList();
      final unread = (res.data['unreadCount'] ?? items.where((n) => !n.isRead).length) as int;
      state = NotificationsState(notifications: items, unreadCount: unread);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.put('/notifications/$id/read');
      await load();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.put('/notifications/read-all');
      await load();
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final api = ref.read(apiServiceProvider);
  return NotificationsNotifier(api);
});
