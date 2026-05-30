import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/api_provider.dart';

class PaymentForm extends ConsumerStatefulWidget {
  final String caseId;
  final String? clientId;
  final ScrollController scrollCtrl;
  final Function(Map<String, dynamic>) onSaved;

  const PaymentForm({
    super.key,
    required this.caseId,
    this.clientId,
    required this.scrollCtrl,
    required this.onSaved,
  });

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _paidAt = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollCtrl,
        children: [
          Text(s.addPayment, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountCtrl,
                  decoration: InputDecoration(labelText: s.amount, border: const OutlineInputBorder(), suffixText: 'EGP'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return s.amount;
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return s.amount;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (d != null) setState(() => _paidAt = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: s.paidAt, border: const OutlineInputBorder()),
                    child: Text(_paidAt.toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(labelText: s.paymentNote, border: const OutlineInputBorder()),
                  maxLines: 2,
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = {
      'caseId': widget.caseId,
      'clientId': widget.clientId,
      'amount': double.parse(_amountCtrl.text.trim()),
      'paidAt': _paidAt.toIso8601String(),
      'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    };

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post('/payments', data: data);
      if (mounted) {
        widget.onSaved(res.data);
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
