import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../models/user.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('/users');
      final items = (res.data['users'] as List).map((e) => User.fromMap(e)).toList();
      setState(() => _users = items);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final user = ref.watch(authProvider).user;

    if (user == null || !user.isAdmin) {
      return Center(child: Text(s.readOnly));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.users, style: Theme.of(context).textTheme.headlineSmall)),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(s.addUser),
              onPressed: () => _showAddDialog(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(child: Text(s.noData))
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        return ListTile(
                          title: Text(u.fullName),
                          subtitle: Text('${u.email} | ${u.role}'),
                          trailing: Switch(
                            value: u.isActive,
                            onChanged: (v) => _toggleActive(u),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _toggleActive(User u) async {
    try {
      await ref.read(apiServiceProvider).put('/users/${u.id}', data: {'isActive': !u.isActive});
      _load();
    } catch (_) {}
  }

  void _showAddDialog() {
    final s = S.of(context);
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'LAWYER';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addUser),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: s.fullName, border: const OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: s.email, border: const OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, decoration: InputDecoration(labelText: s.password, border: const OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: role,
              items: ['LAWYER', 'ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => role = v ?? 'LAWYER',
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(apiServiceProvider).post('/users', data: {
                  'fullName': nameCtrl.text,
                  'email': emailCtrl.text,
                  'password': passCtrl.text,
                  'role': role,
                });
                Navigator.pop(ctx);
                _load();
              } catch (_) {}
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }
}
