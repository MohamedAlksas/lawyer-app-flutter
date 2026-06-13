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
import '../../widgets/shimmer_loader.dart';

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
  List<dynamic> _timelineItems = [];
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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('/cases/${widget.caseId}');
      final d = res.data;
      
      final c = Case.fromMap(d);
      final ssnList = (d['sessions'] as List?)?.map((e) => Session.fromMap(e)).toList() ?? [];
      final payList = (d['payments'] as List?)?.map((e) => Payment.fromMap(e)).toList() ?? [];
      final docList = (d['documents'] as List?)?.map((e) => Document.fromMap(e)).toList() ?? [];

      setState(() {
        _case = c;
        _sessions = ssnList;
        _payments = payList;
        _documents = docList;
        _totalPaid = (d['totalPaid'] ?? 0).toDouble();

        _timelineItems = [
          ...ssnList.map((s) => {'type': 'SESSION', 'date': s.sessionDate, 'title': s.result ?? 'Session', 'subtitle': c.courtName}),
          ...payList.map((p) => {'type': 'PAYMENT', 'date': p.paidAt, 'title': 'Payment Received', 'subtitle': '${p.amount} EGP'}),
          ...docList.map((doc) => {'type': 'DOCUMENT', 'date': doc.createdAt ?? DateTime.now(), 'title': 'Document Added', 'subtitle': doc.name}),
        ];
        _timelineItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_case == null) return Scaffold(appBar: AppBar(title: Text(s.caseDetail)), body: Center(child: Text(s.noData)));

    final c = _case!;
    final remaining = c.agreedFee - _totalPaid;
    final paymentProgress = c.agreedFee > 0 ? (_totalPaid / c.agreedFee).clamp(0.0, 1.0) : 0.0;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.caseInfo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      _StatusBadge(c.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Row(s.courtName, c.courtName),
                  _Row(s.circuitNumber, c.circuitNumber),
                  _Row(s.caseType, c.caseType),
                  _Row(s.subject, c.subject),
                  if (c.opposingParty != null) _Row(s.opposingParty, c.opposingParty!),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.financialSummary, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text('${_totalPaid.toStringAsFixed(0)} / ${c.agreedFee.toStringAsFixed(0)} EGP', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      CircularProgressIndicator(
                        value: paymentProgress,
                        backgroundColor: AppColors.border,
                        color: paymentProgress >= 1.0 ? AppColors.success : AppColors.primary,
                      ),
                    ],
                  ),
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
              color: daysLeft <= 0 ? AppColors.error.withOpacity(0.1) : AppColors.warning.withOpacity(0.15),
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
              Tab(text: s.sessions),
              Tab(text: s.payments),
              Tab(text: s.documents),
              Tab(text: 'الجدول الزمني'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SessionsTab(sessions: _sessions, caseId: c.id, onChanged: _load),
                _PaymentsTab(payments: _payments, caseId: c.id, caseNumber: c.caseNumber, caseYear: c.caseYear, clientName: c.clientName ?? '', onChanged: _load),
                _DocumentsTab(documents: _documents, caseId: c.id, onChanged: _load),
                _TimelineTab(items: _timelineItems),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    if (status == 'ACTIVE') color = AppColors.success;
    if (status == 'CLOSED') color = AppColors.onSurfaceDim;
    if (status == 'SUSPENDED') color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13))),
          Expanded(child: Text(value, style: valueStyle?.copyWith(fontSize: 14) ?? const TextStyle(fontSize: 14))),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
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
        ),
        Expanded(
          child: sessions.isEmpty
              ? Center(child: Text(s.noSessions))
              : ListView.builder(
                  itemCount: sessions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (_, i) {
                    final ssn = sessions[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.event, size: 20)),
                        title: Text(ssn.sessionDate.toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.result}: ${ssn.result ?? '-'}'),
                      ),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
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
        ),
        Expanded(
          child: payments.isEmpty
              ? Center(child: Text(s.noData))
              : ListView.builder(
                  itemCount: payments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (_, i) {
                    final p = payments[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${p.amount} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                        subtitle: Text(p.paidAt.toString().split(' ')[0]),
                        trailing: IconButton(
                          icon: const Icon(Icons.receipt, color: AppColors.primary),
                          onPressed: () => generateReceiptPdf(
                            clientName: clientName,
                            amount: p.amount.toString(),
                            caseNum: '$caseNumber / $caseYear',
                            date: p.paidAt.toString().split(' ')[0],
                            note: p.note,
                          ),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
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
        ),
        Expanded(
          child: documents.isEmpty
              ? Center(child: Text(s.noData))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (_, i) {
                    final d = documents[i];
                    return InkWell(
                      onTap: () => context.push(
                        Uri(path: '/preview', queryParameters: {'url': d.fileUrl, 'title': d.name}).toString(),
                      ),
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description, size: 32, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text(d.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(d.docCategory, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceDim)),
                          ],
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

class _TimelineTab extends StatelessWidget {
  final List<dynamic> items;
  const _TimelineTab({required this.items});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (items.isEmpty) return Center(child: Text(s.noData));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        
        IconData icon;
        Color color;
        switch (item['type']) {
          case 'SESSION': icon = Icons.event; color = AppColors.primary; break;
          case 'PAYMENT': icon = Icons.payments; color = AppColors.success; break;
          case 'DOCUMENT': icon = Icons.description; color = AppColors.secondary; break;
          default: icon = Icons.info; color = Colors.grey;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast) Container(width: 2, height: 60, color: color.withOpacity(0.3)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((item['date'] as DateTime).toString().split(' ')[0], 
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(item['subtitle'], style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceDim)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Icon(icon, color: color.withOpacity(0.5), size: 20),
          ],
        );
      },
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
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true,
      );
      if (result != null && mounted) {
        setState(() => _selectedFile = result.files.single);
      }
    } catch (_) {}
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
