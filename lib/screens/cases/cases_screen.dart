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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Litigation Explorer', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${state.total} active case files', style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 13)),
                ],
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                icon: const Icon(Icons.add),
                onPressed: () => context.go('/cases/add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: s.search,
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(casesProvider.notifier).search('');
                      })
                  : null,
            ),
            onChanged: (v) => ref.read(casesProvider.notifier).search(v),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: _statuses.map((st) {
              final active = (_statusFilter ?? 'ALL') == st;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    st == 'ALL' ? 'الكل' : st,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: active ? AppColors.onPrimary : AppColors.onSurface,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: active,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, __) => const CaseCardSkeleton(),
                )
              : state.items.isEmpty
                  ? Center(child: Text(s.noData))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(casesProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final c = state.items[i];
                          return GlassCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              title: Text(
                                '${c.caseNumber} / ${c.caseYear}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  c.courtName,
                                  style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 13),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _SimpleStatusBadge(c.status),
                                  const SizedBox(height: 4),
                                  Text(c.caseType, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceDim)),
                                ],
                              ),
                              onTap: () => context.go('/cases/${c.id}'),
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

class _SimpleStatusBadge extends StatelessWidget {
  final String status;
  const _SimpleStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    if (status == 'ACTIVE') color = AppColors.success;
    if (status == 'CLOSED') color = AppColors.onSurfaceDim;
    if (status == 'SUSPENDED') color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
