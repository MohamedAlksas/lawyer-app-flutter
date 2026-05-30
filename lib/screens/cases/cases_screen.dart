import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/cases_provider.dart';

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
    final cs = Theme.of(context).colorScheme;
    final filter = _statusFilter ?? 'ALL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.cases, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600))),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.add),
              onPressed: () => context.go('/cases/add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: s.search,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                    _searchCtrl.clear();
                    ref.read(casesProvider.notifier).search('');
                  })
                : null,
          ),
          onChanged: (v) => ref.read(casesProvider.notifier).search(v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _statuses.map((st) {
              final active = filter == st;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(st == 'ALL' ? s.all : st),
                  selected: active,
                  onSelected: (_) {
                    final next = active ? 'ALL' : st;
                    setState(() => _statusFilter = next);
                    ref.read(casesProvider.notifier).filterByStatus(next);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(state.error!, style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
            ),
          ),
        Expanded(
          child: state.isLoading && state.cases.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.cases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_outlined, size: 48, color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text(state.error ?? s.noData, style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.cases.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) {
                        final c = state.cases[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: c.status == 'ACTIVE' ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                            child: Icon(
                              c.status == 'ACTIVE' ? Icons.gavel : Icons.folder_off_outlined,
                              color: c.status == 'ACTIVE' ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text('${s.caseNumber}: ${c.caseNumber} / ${c.caseYear}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${c.courtName} | ${c.caseType}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                          trailing: _StatusBadge(c.status),
                          onTap: () => context.go('/cases/${c.id}'),
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
    final cs = Theme.of(context).colorScheme;
    Color color;
    String label;
    switch (status) {
      case 'ACTIVE':
        color = Colors.green;
        label = s.active;
        break;
      case 'CLOSED':
        color = Colors.grey;
        label = s.closed;
        break;
      case 'SUSPENDED':
        color = Colors.orange;
        label = s.suspended;
        break;
      default:
        color = cs.outlineVariant;
        label = status;
    }
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
