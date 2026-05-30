import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../models/client.dart';
import '../../providers/clients_provider.dart';
import '../../widgets/forms/client_form.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(clientsProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showClientDetail(Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => _ClientDetailSheet(client: client, scrollCtrl: scrollCtrl),
      ),
    );
  }

  void _showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ClientForm(scrollCtrl: ctrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(clientsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.clients, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.add),
              onPressed: _showAddForm,
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
                    ref.read(clientsProvider.notifier).search('');
                  })
                : null,
          ),
          onChanged: (v) => ref.read(clientsProvider.notifier).search(v),
        ),
        const SizedBox(height: 12),
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
          child: state.isLoading && state.clients.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.clients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text(state.error ?? s.noData, style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.clients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) {
                        final c = state.clients[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?', style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                          ),
                          title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(c.phone ?? c.nationalId ?? '', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                          trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: cs.onSurfaceVariant),
                          onTap: () => _showClientDetail(c),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ClientDetailSheet extends ConsumerWidget {
  final Client client;
  final ScrollController scrollCtrl;

  const _ClientDetailSheet({required this.client, required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollCtrl,
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: cs.primaryContainer,
              child: Text(client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?', style: TextStyle(fontSize: 28, color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Text(client.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          if (client.fullNameAr != null) Text(client.fullNameAr!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (client.phone != null) _InfoRow(s.phone, client.phone!),
                  if (client.alternatePhone != null) _InfoRow(s.alternatePhone, client.alternatePhone!),
                  if (client.nationalId != null) _InfoRow(s.nationalId, client.nationalId!),
                  if (client.address != null) _InfoRow(s.address, client.address!),
                  if (client.notes != null) _InfoRow(s.notes, client.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.95,
                builder: (_, ctrl) => ClientForm(client: client, scrollCtrl: ctrl),
              ),
            ),
            label: Text(s.edit),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
