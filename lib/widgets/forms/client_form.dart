import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../models/client.dart';
import '../../providers/api_provider.dart';

class ClientForm extends ConsumerStatefulWidget {
  final Client? client;
  final ScrollController scrollCtrl;

  const ClientForm({super.key, this.client, required this.scrollCtrl});

  @override
  ConsumerState<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _nameArCtrl;
  late TextEditingController _nationalCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _altPhoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameCtrl = TextEditingController(text: c?.fullName ?? '');
    _nameArCtrl = TextEditingController(text: c?.fullNameAr ?? '');
    _nationalCtrl = TextEditingController(text: c?.nationalId ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _altPhoneCtrl = TextEditingController(text: c?.alternatePhone ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _nationalCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = {
      'fullName': _nameCtrl.text.trim(),
      'fullNameAr': _nameArCtrl.text.trim().isEmpty ? null : _nameArCtrl.text.trim(),
      'nationalId': _nationalCtrl.text.trim().isEmpty ? null : _nationalCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'alternatePhone': _altPhoneCtrl.text.trim().isEmpty ? null : _altPhoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      final api = ref.read(apiServiceProvider);
      if (widget.client != null) {
        await api.put('/clients/${widget.client!.id}', data: data);
      } else {
        await api.post('/clients', data: data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isEdit = widget.client != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollCtrl,
        children: [
          Text(isEdit ? s.editClient : s.addClient, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: s.fullName, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? s.fullName : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameArCtrl,
                  decoration: InputDecoration(labelText: s.fullNameAr, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nationalCtrl,
                  decoration: InputDecoration(labelText: s.nationalId, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(labelText: s.phone, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _altPhoneCtrl,
                  decoration: InputDecoration(labelText: s.alternatePhone, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(labelText: s.address, border: const OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(labelText: s.notes, border: const OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.save),
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
