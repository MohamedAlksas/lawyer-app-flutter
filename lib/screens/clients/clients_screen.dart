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
        builder: (_, scrollCtrl) => _ClientDetailSheet(client: client, scrollCtrl: scrollCtrl),
      ),
    );
  }

  void _showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                onPressed: _showAddForm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search text field
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
                      ref.read(clientsProvider.notifier).search('');
                    })
                : null,
          ),
          onChanged: (v) => ref.read(clientsProvider.notifier).search(v),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.isLoading && state.items.isEmpty
              ? ListView.builder(
                  itemCount: 8,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (_, __) => const ClientCardSkeleton(),
                )
              : state.items.isEmpty
                  ? Center(child: Text(s.noData))
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = state.items[i];
                        return GlassCard(
                          accentColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : 'C',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                c.phone ?? c.nationalId ?? '',
                                style: const TextStyle(color: AppColors.onSurfaceDim),
                              ),
                            ),
                            trailing: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                              color: AppColors.primary,
                            ),
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

class _ClientDetailSheet extends ConsumerWidget {
  final Client client;
  final ScrollController scrollCtrl;

  const _ClientDetailSheet({required this.client, required this.scrollCtrl});

  void _callNumber(String num) async {
    final uri = Uri.parse('tel:$num');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollCtrl,
        children: [
          // Horizontal grab bar
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Icon(Icons.person, size: 56, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            client.fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (client.fullNameAr != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                client.fullNameAr!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
          const Divider(height: 32),

          if (client.phone != null)
            _DetailTile(
              icon: Icons.phone_outlined,
              label: s.phone,
              value: client.phone!,
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppColors.success),
                onPressed: () => _callNumber(client.phone!),
              ),
            ),
          if (client.alternatePhone != null)
            _DetailTile(
              icon: Icons.phone_android_outlined,
              label: s.alternatePhone,
              value: client.alternatePhone!,
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppColors.success),
                onPressed: () => _callNumber(client.alternatePhone!),
              ),
            ),
          if (client.nationalId != null)
            _DetailTile(icon: Icons.badge_outlined, label: s.nationalId, value: client.nationalId!),
          if (client.address != null)
            _DetailTile(icon: Icons.location_on_outlined, label: s.address, value: client.address!),
          if (client.notes != null)
            _DetailTile(icon: Icons.notes_outlined, label: s.notes, value: client.notes!),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  label: Text(s.edit, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        maxChildSize: 0.95,
                        builder: (_, ctrl) => ClientForm(client: client, scrollCtrl: ctrl),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
