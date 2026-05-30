import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(notificationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.notifications, style: Theme.of(context).textTheme.headlineSmall)),
            if (state.unreadCount > 0)
              TextButton(
                onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                child: Text(s.markAllRead),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.notifications.isEmpty
                  ? Center(child: Text(s.noData))
                  : ListView.separated(
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = state.notifications[i];
                        return ListTile(
                          leading: Icon(
                            n.isRead ? Icons.notifications_none : Icons.notifications,
                            color: n.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                          subtitle: Text(n.body),
                          trailing: n.createdAt != null
                              ? Text(
                                  '${n.createdAt!.hour}:${n.createdAt!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          onTap: n.isRead ? null : () => ref.read(notificationsProvider.notifier).markRead(n.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
