import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text('Legal Alerts', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
              if (state.unreadCount > 0)
                TextButton.icon(
                  icon: const Icon(Icons.done_all, size: 18),
                  onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                  label: Text(s.markAllRead),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (_, __) => const ShimmerLoader(width: double.infinity, height: 80, borderRadius: 16),
                )
              : state.notifications.isEmpty
                  ? Center(child: Text(s.noData))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(notificationsProvider.notifier).load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final n = state.notifications[i];
                          return GlassCard(
                            padding: EdgeInsets.zero,
                            accentColor: n.isRead ? null : AppColors.primary,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  n.isRead ? Icons.notifications_none_outlined : Icons.notifications_active_outlined,
                                  color: n.isRead ? AppColors.onSurfaceDim : AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                n.title, 
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  color: n.isRead ? AppColors.onSurfaceDim : AppColors.onSurface,
                                ),
                              ),
                              subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (n.createdAt != null)
                                    Text(
                                      '${n.createdAt!.hour}:${n.createdAt!.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceDim),
                                    ),
                                  if (!n.isRead)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              onTap: n.isRead ? null : () => ref.read(notificationsProvider.notifier).markRead(n.id),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
