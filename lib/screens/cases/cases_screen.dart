import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/cases_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;

  final _statuses = ['ALL', 'ACTIVE', 'CLOSED', 'SUSPENDED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(casesProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(casesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.cases, style: Theme.of(context).textTheme.headlineSmall)),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(s.add, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/cases/add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: s.search,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(casesProvider.notifier).search('');
                    })
                : null,
          ),
          onChanged: (v) => ref.read(casesProvider.notifier).search(v),
        ),
        const SizedBox(height: 12),
        // Filter Chips Row
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: _statuses.map((st) {
              final active = (_statusFilter ?? 'ALL') == st;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(
                    st == 'ALL'
                        ? 'الكل'
                        : st == 'ACTIVE'
                            ? s.active
                            : st == 'CLOSED'
                                ? s.closed
                                : s.suspended,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: active ? AppColors.onPrimary : AppColors.onSurface,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: active,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: active ? AppColors.primary : AppColors.border),
                  ),
                  showCheckmark: false,
                  onSelected: (_) {
                    final newStatus = st == 'ALL' ? null : st;
                    setState(() => _statusFilter = st);
                    ref.read(casesProvider.notifier).filterByStatus(newStatus);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.isLoading && state.items.isEmpty
              ? ListView.builder(
                  itemCount: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (_, __) => const CaseCardSkeleton(),
                )
              : state.items.isEmpty
                  ? Center(child: Text(s.noData))
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = state.items[i];

                        Color accentColor;
                        switch (c.status) {
                          case 'ACTIVE':
                            accentColor = AppColors.success;
                            break;
                          case 'CLOSED':
                            accentColor = AppColors.onSurfaceDim;
                            break;
                          case 'SUSPENDED':
                            accentColor = AppColors.warning;
                            break;
                          default:
                            accentColor = AppColors.primary;
                        }

                        return GlassCard(
                          accentColor: accentColor,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              '${s.caseNumber}: ${c.caseNumber} / ${c.caseYear}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${c.courtName} | ${c.caseType}',
                                style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 13),
                              ),
                            ),
                            trailing: _StatusBadge(c.status),
                            onTap: () => context.go('/cases/${c.id}'),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Color color;
    String label;
    switch (status) {
      case 'ACTIVE':
        color = AppColors.success;
        label = s.active;
        break;
      case 'CLOSED':
        color = AppColors.onSurfaceDim;
        label = s.closed;
        break;
      case 'SUSPENDED':
        color = AppColors.warning;
        label = s.suspended;
        break;
      default:
        color = AppColors.secondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),
    );
  }
}
