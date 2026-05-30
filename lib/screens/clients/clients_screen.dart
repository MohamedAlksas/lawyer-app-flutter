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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.clients, style: Theme.of(context).textTheme.headlineSmall),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
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
            border: const OutlineInputBorder(),
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
        Expanded(
          child: state.isLoading && state.clients.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.clients.isEmpty
                  ? Center(child: Text(s.noData))
                  : ListView.separated(
                      itemCount: state.clients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = state.clients[i];
                        return ListTile(
                          title: Text(c.fullName),
                          subtitle: Text(c.phone ?? c.nationalId ?? ''),
                          trailing: const Icon(Icons.chevron_left),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollCtrl,
        children: [
          Center(child: Icon(Icons.person, size: 64, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          Text(client.fullName, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          if (client.fullNameAr != null) Text(client.fullNameAr!, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const Divider(height: 24),
          if (client.phone != null) _Row(s.phone, client.phone!),
          if (client.alternatePhone != null) _Row(s.alternatePhone, client.alternatePhone!),
          if (client.nationalId != null) _Row(s.nationalId, client.nationalId!),
          if (client.address != null) _Row(s.address, client.address!),
          if (client.notes != null) _Row(s.notes, client.notes!),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.95,
                builder: (_, ctrl) => ClientForm(client: client, scrollCtrl: ctrl),
              ),
            ),
            child: Text(s.edit),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(value))],
      ),
    );
  }
}
