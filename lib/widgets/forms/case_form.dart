import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../models/case.dart';
import '../../models/user.dart';
import '../../providers/api_provider.dart';

class CaseForm extends ConsumerStatefulWidget {
  final Case? caseModel;
  final ScrollController scrollCtrl;

  const CaseForm({super.key, this.caseModel, required this.scrollCtrl});

  @override
  ConsumerState<CaseForm> createState() => _CaseFormState();
}

class _CaseFormState extends ConsumerState<CaseForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _caseNumberCtrl;
  late TextEditingController _caseYearCtrl;
  late TextEditingController _courtNameCtrl;
  late TextEditingController _circuitCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _opposingCtrl;
  late TextEditingController _feeCtrl;

  String _clientId = '';
  String _assignedLawyerId = '';
  String _caseType = 'CIVIL';
  DateTime _filingDate = DateTime.now();
  DateTime? _limitationDeadline;
  bool _submitting = false;

  List<Map<String, dynamic>> _clients = [];
  List<User> _lawyers = [];
  bool _loadingClients = false;

  @override
  void initState() {
    super.initState();
    final c = widget.caseModel;
    _caseNumberCtrl = TextEditingController(text: c?.caseNumber ?? '');
    _caseYearCtrl = TextEditingController(text: c?.caseYear ?? DateTime.now().year.toString());
    _courtNameCtrl = TextEditingController(text: c?.courtName ?? '');
    _circuitCtrl = TextEditingController(text: c?.circuitNumber ?? '');
    _subjectCtrl = TextEditingController(text: c?.subject ?? '');
    _opposingCtrl = TextEditingController(text: c?.opposingParty ?? '');
    _feeCtrl = TextEditingController(text: c?.agreedFee.toString() ?? '0');
    _clientId = c?.clientId ?? '';
    _assignedLawyerId = c?.assignedLawyerId ?? '';
    _caseType = c?.caseType ?? 'CIVIL';
    if (c != null) _filingDate = c.filingDate;
    _limitationDeadline = c?.limitationDeadline;
    _loadReferences();
  }

  @override
  void dispose() {
    _caseNumberCtrl.dispose();
    _caseYearCtrl.dispose();
    _courtNameCtrl.dispose();
    _circuitCtrl.dispose();
    _subjectCtrl.dispose();
    _opposingCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() => _loadingClients = true);
    try {
      final api = ref.read(apiServiceProvider);
      final cRes = await api.get('/clients', query: {'limit': 100});
      _clients = ((cRes.data['data'] ?? []) as List).cast<Map<String, dynamic>>();
      final uRes = await api.get('/users');
      _lawyers = (uRes.data as List).map((e) => User.fromMap(e)).toList();
    } catch (_) {}
    setState(() => _loadingClients = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client')));
      return;
    }
    setState(() => _submitting = true);

    final data = {
      'clientId': _clientId,
      'caseNumber': _caseNumberCtrl.text.trim(),
      'caseYear': _caseYearCtrl.text.trim(),
      'courtName': _courtNameCtrl.text.trim(),
      'circuitNumber': _circuitCtrl.text.trim(),
      'caseType': _caseType,
      'subject': _subjectCtrl.text.trim(),
      'opposingParty': _opposingCtrl.text.trim().isEmpty ? null : _opposingCtrl.text.trim(),
      'assignedLawyerId': _assignedLawyerId,
      'filingDate': _filingDate.toIso8601String(),
      'limitationDeadline': _limitationDeadline?.toIso8601String(),
      'agreedFee': double.tryParse(_feeCtrl.text) ?? 0,
    };

    try {
      final api = ref.read(apiServiceProvider);
      if (widget.caseModel != null) {
        await api.put('/cases/${widget.caseModel!.id}', data: data);
      } else {
        await api.post('/cases', data: data);
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
    final isEdit = widget.caseModel != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollCtrl,
        children: [
          Text(isEdit ? s.editCase : s.addCase, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _clientId.isEmpty ? null : _clientId,
                  items: _clients.map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['fullName'] ?? ''))).toList(),
                  onChanged: (v) => setState(() => _clientId = v ?? ''),
                  decoration: InputDecoration(labelText: s.clients, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _caseNumberCtrl,
                  decoration: InputDecoration(labelText: s.caseNumber, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? s.caseNumber : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _caseYearCtrl,
                  decoration: InputDecoration(labelText: s.caseYear, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courtNameCtrl,
                  decoration: InputDecoration(labelText: s.courtName, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _circuitCtrl,
                  decoration: InputDecoration(labelText: s.circuitNumber, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _caseType,
                  items: ['CIVIL', 'CRIMINAL', 'FAMILY', 'COMMERCIAL', 'ADMINISTRATIVE', 'LABOR']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _caseType = v ?? 'CIVIL'),
                  decoration: InputDecoration(labelText: s.caseType, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(labelText: s.subject, border: const OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _opposingCtrl,
                  decoration: InputDecoration(labelText: s.opposingParty, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _assignedLawyerId.isEmpty ? null : _assignedLawyerId,
                  items: _lawyers.map((u) => DropdownMenuItem(value: u.id, child: Text(u.fullName))).toList(),
                  onChanged: (v) => setState(() => _assignedLawyerId = v ?? ''),
                  decoration: InputDecoration(labelText: s.assignedLawyer, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (d != null) setState(() => _filingDate = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: s.filingDate, border: const OutlineInputBorder()),
                    child: Text(_filingDate.toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2040));
                    if (d != null) setState(() => _limitationDeadline = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: s.limitationDeadline,
                      border: const OutlineInputBorder(),
                      suffixIcon: _limitationDeadline != null
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _limitationDeadline = null))
                          : null,
                    ),
                    child: Text(_limitationDeadline?.toString().split(' ')[0] ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _feeCtrl,
                  decoration: InputDecoration(labelText: s.agreedFee, border: const OutlineInputBorder(), suffixText: 'EGP'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting || _loadingClients ? null : _submit,
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
