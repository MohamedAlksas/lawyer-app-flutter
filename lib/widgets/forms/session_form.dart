import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/api_provider.dart';

class SessionForm extends ConsumerStatefulWidget {
  final String caseId;
  final ScrollController scrollCtrl;
  final Function(Map<String, dynamic>, bool) onSaved;

  const SessionForm({
    super.key,
    required this.caseId,
    required this.scrollCtrl,
    required this.onSaved,
  });

  @override
  ConsumerState<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<SessionForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _sessionDate = DateTime.now();
  String? _result;
  DateTime? _nextSessionDate;
  String _attendedBy = '';
  String _notes = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollCtrl,
        children: [
          Text(s.addSession, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2040));
                    if (d != null) setState(() => _sessionDate = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: s.sessionDate, border: const OutlineInputBorder()),
                    child: Text(_sessionDate.toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _result,
                  items: [
                    DropdownMenuItem(value: null, child: Text('-')),
                    DropdownMenuItem(value: 'POSTPONED', child: Text(s.postponed)),
                    DropdownMenuItem(value: 'MEMORANDUM', child: Text(s.memorandum)),
                    DropdownMenuItem(value: 'JUDGMENT', child: Text(s.judgment)),
                    DropdownMenuItem(value: 'APPEAL', child: Text(s.appeal)),
                    DropdownMenuItem(value: 'OTHER', child: Text(s.other)),
                  ],
                  onChanged: (v) => setState(() => _result = v),
                  decoration: InputDecoration(labelText: s.result, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2040));
                    if (d != null) setState(() => _nextSessionDate = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: s.nextSessionDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: _nextSessionDate != null
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _nextSessionDate = null))
                          : null,
                    ),
                    child: Text(_nextSessionDate?.toString().split(' ')[0] ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: s.attendedBy, border: const OutlineInputBorder()),
                  onChanged: (v) => _attendedBy = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: s.notes, border: const OutlineInputBorder()),
                  maxLines: 3,
                  onChanged: (v) => _notes = v,
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

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final data = {
      'caseId': widget.caseId,
      'sessionDate': _sessionDate.toIso8601String(),
      'result': _result,
      'nextSessionDate': _nextSessionDate?.toIso8601String(),
      'attendedBy': _attendedBy.isEmpty ? null : _attendedBy,
      'notes': _notes.isEmpty ? null : _notes,
    };
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post('/sessions', data: data);
      if (mounted) {
        widget.onSaved(res.data, true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    setState(() => _submitting = false);
  }
}
