import 'dart:convert';

class Payment {
  final String id;
  final String caseId;
  final String? clientId;
  final double amount;
  final DateTime paidAt;
  final String? note;
  final String createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.caseId,
    this.clientId,
    required this.amount,
    required this.paidAt,
    this.note,
    required this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'caseId': caseId,
        'clientId': clientId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
        'note': note,
        'createdById': createdById,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] ?? '',
        caseId: map['caseId'] ?? '',
        clientId: map['clientId'],
        amount: (map['amount'] ?? 0).toDouble(),
        paidAt: DateTime.tryParse(map['paidAt'] ?? '') ?? DateTime.now(),
        note: map['note'],
        createdById: map['createdById'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
        updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      );

  Map<String, dynamic> toCreatePayload() => {
        'caseId': caseId,
        'clientId': clientId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
        'note': note,
      };

  String toJson() => jsonEncode(toMap());
  factory Payment.fromJson(String source) => Payment.fromMap(jsonDecode(source));
}
