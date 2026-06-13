import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../models/case.dart';
import '../../models/session.dart';
import '../../models/payment.dart';
import '../../models/document.dart';
import '../../providers/api_provider.dart';
import '../../widgets/forms/session_form.dart';
import '../../widgets/forms/payment_form.dart';
import '../../theme/app_theme.dart';
import '../../services/receipt_service.dart';

DateTime calculateAppealDeadline(DateTime judgmentDate, String courtType) {
  if (courtType.contains('مستعجل')) {
    return judgmentDate.add(const Duration(days: 15));
  } else if (courtType.contains('نقض') || courtType.contains('إدارية')) {
    return judgmentDate.add(const Duration(days: 60));
  }
  return judgmentDate.add(const Duration(days: 40));
}

class CaseDetailScreen extends ConsumerStatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Case? _case;
  List<Session> _sessions = [];
  List<Payment> _payments = [];
  List<Document> _documents = [];
  List<dynamic> _actions = [];
  bool _loading = true;
  double _totalPaid = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('/cases/${widget.caseId}');
      final d = res.data;
      _case = Case.fromMap(d);
      _sessions = (d['sessions'] as List?)?.map((e) => Session.fromMap(e)).toList() ?? [];
      _payments = (d['payments'] as List?)?.map((e) => Payment.fromMap(e)).toList() ?? [];
      _documents = (d['documents'] as List?)?.map((e) => Document.fromMap(e)).toList() ?? [];
      _actions = (d['actions'] as List?) ?? [];
      _totalPaid = (d['totalPaid'] ?? 0).toDouble();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_case == null) return Scaffold(appBar: AppBar(title: Text(s.caseDetail)), body: Center(child: Text(s.noData)));

    final c = _case!;
    final remaining = c.agreedFee - _totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.caseNumber} ${c.caseNumber}/${c.caseYear}'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/cases/${c.id}/edit')),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.caseInfo, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _Row(s.courtName, c.courtName),
                  _Row(s.circuitNumber, c.circuitNumber),
                  _Row(s.caseType, c.caseType),
                  _Row(s.subject, c.subject),
                  if (c.opposingParty != null) _Row(s.opposingParty, c.opposingParty!),
                  _Row(s.status, c.status),
                  const Divider(),
                  Text(s.financialSummary, style: Theme.of(context).textTheme.titleSmall),
                  _Row(s.agreedFee, '${c.agreedFee} EGP'),
                  _Row(s.totalPaid, '$_totalPaid EGP'),
                  _Row(s.remaining, '$remaining EGP',
                      valueStyle: TextStyle(color: remaining > 0 ? Colors.red : Colors.green)),
                ],
              ),
            ),
          ),
          ..._sessions.where((ssn) => ssn.result == 'JUDGMENT').map((ssn) {
            final deadline = calculateAppealDeadline(ssn.sessionDate, c.courtName);
            final daysLeft = deadline.difference(DateTime.now()).inDays;
            if (daysLeft > 7) return const SizedBox.shrink();
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: daysLeft <= 0 ? AppColors.error : AppColors.warning.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(daysLeft <= 0 ? Icons.warning : Icons.schedule, color: daysLeft <= 0 ? AppColors.error : AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        daysLeft <= 0
                            ? 'انتهت مهلة الطعن! تاريخ الحكم: ${ssn.sessionDate.toString().split(' ')[0]}'
                            : 'مهلة الطعن تنتهي خلال $daysLeft أيام (${deadline.toString().split(' ')[0]})',
                        style: TextStyle(color: daysLeft <= 0 ? AppColors.error : AppColors.warning, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: [
              Tab(text: '${s.sessions} (${_sessions.length})'),
              Tab(text: '${s.payments} (${_payments.length})'),
              Tab(text: '${s.documents} (${_documents.length})'),
              Tab(text: '${s.actions} (${_actions.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SessionsTab(sessions: _sessions, caseId: c.id, onChanged: _load),
                _PaymentsTab(payments: _payments, caseId: c.id, caseNumber: c.caseNumber, caseYear: c.caseYear, clientName: c.clientName ?? '', onChanged: _load),
                _DocumentsTab(documents: _documents, caseId: c.id, onChanged: _load),
                _ActionsTab(actions: _actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _Row(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  final List<Session> sessions;
  final String caseId;
  final VoidCallback onChanged;

  const _SessionsTab({required this.sessions, required this.caseId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(s.addSession),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.8,
                maxChildSize: 0.95,
                builder: (_, ctrl) => SessionForm(caseId: caseId, scrollCtrl: ctrl, onSaved: (_, __) => onChanged()),
              ),
            ),
          ),
        ),
        Expanded(
          child: sessions.isEmpty
              ? Center(child: Text(s.noSessions))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (_, i) {
                    final ssn = sessions[i];
                    return ListTile(
                      title: Text(ssn.sessionDate.toString().split('.')[0]),
                      subtitle: Text('${s.result}: ${ssn.result ?? '-'}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<Payment> payments;
  final String caseId;
  final String caseNumber;
  final String caseYear;
  final String clientName;
  final VoidCallback onChanged;

  const _PaymentsTab({
    required this.payments,
    required this.caseId,
    required this.caseNumber,
    required this.caseYear,
    required this.clientName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(s.addPayment),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                maxChildSize: 0.9,
                builder: (_, ctrl) => PaymentForm(caseId: caseId, scrollCtrl: ctrl, onSaved: (_) => onChanged()),
              ),
            ),
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? Center(child: Text(s.noData))
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (_, i) {
                    final p = payments[i];
                    return ListTile(
                      title: Text('${p.amount} EGP'),
                      subtitle: Text(p.paidAt.toString().split('.')[0]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.note != null) Text(p.note!, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceDim)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.receipt, size: 20, color: AppColors.primary),
                            tooltip: 'طباعة سند قبض',
                            onPressed: () => generateReceiptPdf(
                              clientName: clientName,
                              amount: p.amount.toString(),
                              caseNum: '$caseNumber / $caseYear',
                              date: p.paidAt.toString().split('.')[0],
                              note: p.note,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  final List<Document> documents;
  final String caseId;
  final VoidCallback onChanged;

  const _DocumentsTab({required this.documents, required this.caseId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(s.uploadDocument),
            onPressed: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (_) => _UploadDocDialog(caseId: caseId),
              );
              if (result != null) onChanged();
            },
          ),
        ),
        Expanded(
          child: documents.isEmpty
              ? Center(child: Text(s.noData))
              : ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (_, i) {
                    final d = documents[i];
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(d.name),
                      subtitle: Text(d.docCategory),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_red_eye_outlined),
                        onPressed: () => context.push(
                          Uri(
                            path: '/preview',
                            queryParameters: {'url': d.fileUrl, 'title': d.name},
                          ).toString(),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UploadDocDialog extends StatefulWidget {
  final String caseId;
  const _UploadDocDialog({required this.caseId});

  @override
  State<_UploadDocDialog> createState() => _UploadDocDialogState();
}

class _UploadDocDialogState extends State<_UploadDocDialog> {
  fp.PlatformFile? _selectedFile;
  String _category = 'OTHER';
  bool _uploading = false;

  Future<void> _pickFile() async {
    fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.single);
    }
  }

  Future<void> _upload(WidgetRef ref) async {
    if (_selectedFile == null) return;
    setState(() => _uploading = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.uploadFile(
        '/documents',
        _selectedFile!.bytes,
        caseId: widget.caseId,
        docCategory: _category,
        name: _selectedFile!.name,
      );
      if (mounted) Navigator.pop(context, 'success');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          title: Text(s.uploadDocument),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                items: ['POA', 'MEMORANDUM', 'JUDGMENT', 'APPEAL', 'CONTRACT', 'OTHER']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'OTHER'),
                decoration: InputDecoration(labelText: s.docCategory, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Expanded(
                  child: Text(
                    _selectedFile == null ? s.selectFile : _selectedFile!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onPressed: _uploading ? null : _pickFile,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: _uploading ? null : () => Navigator.pop(context), child: Text(s.cancel)),
            FilledButton(
              onPressed: _selectedFile == null || _uploading ? null : () => _upload(ref),
              child: _uploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.save),
            ),
          ],
        );
      },
    );
  }
}

class _ActionsTab extends StatelessWidget {
  final List<dynamic> actions;
  const _ActionsTab({required this.actions});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (actions.isEmpty) return Center(child: Text(s.noData));
    return ListView.builder(
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final a = actions[i];
        return ListTile(
          title: Text(a['actionType'] ?? ''),
          subtitle: Text(a['createdAt']?.toString() ?? ''),
        );
      },
    );
  }
}
