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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.cases, style: Theme.of(context).textTheme.headlineSmall)),
            FilledButton.icon(
              icon: const Icon(Icons.add),
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
            border: const OutlineInputBorder(),
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
              final active = (_statusFilter ?? 'ALL') == st;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s.status == st ? st : st),
                  selected: active,
                  onSelected: (_) {
                    setState(() => _statusFilter = active ? 'ALL' : st);
                    ref.read(casesProvider.notifier).filterByStatus(_statusFilter);
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
            child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ),
        Expanded(
          child: state.isLoading && state.cases.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.cases.isEmpty
                  ? Center(child: Text(state.error ?? s.noData))
                  : ListView.separated(
                      itemCount: state.cases.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = state.cases[i];
                        return ListTile(
                          title: Text('${s.caseNumber}: ${c.caseNumber} / ${c.caseYear}'),
                          subtitle: Text('${c.courtName} | ${c.caseType}'),
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
        color = Colors.blueGrey;
        label = status;
    }
    return Chip(label: Text(label, style: TextStyle(fontSize: 12, color: color)), backgroundColor: color.withValues(alpha: 0.1), visualDensity: VisualDensity.compact);
  }
}
