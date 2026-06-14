import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Executive Insights',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily briefing and strategic overview.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceDim),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 32),

          statsAsync.when(
            loading: () => const _DashboardSkeleton(),
            error: (e, _) => Center(child: Text('$e')),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glassmorphic Stat Tiles
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _LuxuryStatCard(
                      icon: Icons.account_balance_outlined,
                      label: 'Dockets',
                      value: '${stats.activeCases}',
                      trend: '+5%',
                      color: AppColors.primary,
                    ),
                    _LuxuryStatCard(
                      icon: Icons.event_note_outlined,
                      label: 'Today',
                      value: '${stats.todaySessions}',
                      trend: 'Priority',
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Case Load Gauge
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Case Load', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          const Text('Optimal capacity', style: TextStyle(color: AppColors.onSurfaceDim, fontSize: 12)),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: (stats.activeCases / 50).clamp(0.0, 1.0),
                              strokeWidth: 6,
                              backgroundColor: AppColors.border,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${((stats.activeCases / 50) * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Imminent Session Widget
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flash_on, color: AppColors.primary, size: 16),
                          SizedBox(width: 8),
                          Text('IMMINENT', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estate Settlement', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                const Text('Conference Room A • Partner Review', style: TextStyle(color: AppColors.onSurfaceDim, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('14:00', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Today', style: TextStyle(color: AppColors.onSurfaceDim, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Review Brief', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _LuxuryStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.onSurfaceDim, size: 20),
              Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 10, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: ShimmerLoader(width: double.infinity, height: 140, borderRadius: 16)),
            const SizedBox(width: 16),
            Expanded(child: ShimmerLoader(width: double.infinity, height: 140, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 16),
        const ShimmerLoader(width: double.infinity, height: 100, borderRadius: 16),
        const SizedBox(height: 16),
        const ShimmerLoader(width: double.infinity, height: 200, borderRadius: 16),
      ],
    );
  }
}
