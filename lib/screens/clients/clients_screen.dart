import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../models/client.dart';
import '../../providers/clients_provider.dart';
import '../../widgets/forms/client_form.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

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
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => _LuxuryClientDetailSheet(client: client, scrollCtrl: scrollCtrl),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client Dossier', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${state.total} registered entries', style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 13)),
                ],
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    builder: (_, ctrl) => ClientForm(scrollCtrl: ctrl),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: s.search,
            ),
            onChanged: (v) => ref.read(clientsProvider.notifier).search(v),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.isLoading && state.items.isEmpty
              ? ListView.builder(
                  itemCount: 8,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, __) => const ClientCardSkeleton(),
                )
              : state.items.isEmpty
                  ? Center(child: Text(s.noData))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = state.items[i];
                        return GlassCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : 'C',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ),
                            title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(c.phone ?? '', style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.border),
                            onTap: () => _showClientDetail(c),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _LuxuryClientDetailSheet extends StatelessWidget {
  final Client client;
  final ScrollController scrollCtrl;

  const _LuxuryClientDetailSheet({required this.client, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.person_outline, size: 64, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(client.fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                
                _LuxuryInfoTile(Icons.phone_outlined, s.phone, client.phone ?? '-'),
                _LuxuryInfoTile(Icons.badge_outlined, s.nationalId, client.nationalId ?? '-'),
                _LuxuryInfoTile(Icons.location_on_outlined, s.address, client.address ?? '-'),
                _LuxuryInfoTile(Icons.notes_outlined, s.notes, client.notes ?? '-'),

                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        child: Text(s.edit, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      onPressed: () => launchUrl(Uri.parse('tel:${client.phone}')),
                      icon: const Icon(Icons.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LuxuryInfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceDim, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
