import 'dart:convert';

class Case {
  final String id;
  final String clientId;
  final String caseNumber;
  final String caseYear;
  final String courtName;
  final String circuitNumber;
  final String caseType;
  final String subject;
  final String? clientName;
  final String? opposingParty;
  final String assignedLawyerId;
  final String status;
  final DateTime filingDate;
  final DateTime? limitationDeadline;
  final double agreedFee;
  final String createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Case({
    required this.id,
    required this.clientId,
    required this.caseNumber,
    required this.caseYear,
    required this.courtName,
    required this.circuitNumber,
    required this.caseType,
    required this.subject,
    this.clientName,
    this.opposingParty,
    required this.assignedLawyerId,
    required this.status,
    required this.filingDate,
    this.limitationDeadline,
    this.agreedFee = 0,
    required this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'caseNumber': caseNumber,
        'caseYear': caseYear,
        'courtName': courtName,
        'circuitNumber': circuitNumber,
        'caseType': caseType,
        'subject': subject,
        'opposingParty': opposingParty,
        'assignedLawyerId': assignedLawyerId,
        'status': status,
        'filingDate': filingDate.toIso8601String(),
        'limitationDeadline': limitationDeadline?.toIso8601String(),
        'agreedFee': agreedFee,
        'createdById': createdById,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Case.fromMap(Map<String, dynamic> map) => Case(
        id: map['id'] ?? '',
        clientId: map['clientId'] ?? '',
        caseNumber: map['caseNumber'] ?? '',
        caseYear: '${map['caseYear'] ?? ''}',
        courtName: map['courtName'] ?? '',
        circuitNumber: map['circuitNumber']?.toString() ?? '',
        caseType: map['caseType'] ?? '',
        subject: map['subject'] ?? '',
        clientName: map['client']?['fullName'],
        opposingParty: map['opposingParty'],
        assignedLawyerId: map['assignedLawyerId'] ?? '',
        status: map['status'] ?? 'ACTIVE',
        filingDate: map['filingDate'] != null ? DateTime.tryParse(map['filingDate']) ?? DateTime.now() : DateTime.now(),
        limitationDeadline: map['limitationDeadline'] != null ? DateTime.tryParse(map['limitationDeadline']) : null,
        agreedFee: (map['agreedFee'] ?? 0).toDouble(),
        createdById: map['createdById'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
        updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      );

  Map<String, dynamic> toCreatePayload() => {
        'clientId': clientId,
        'caseNumber': caseNumber,
        'caseYear': caseYear,
        'courtName': courtName,
        'circuitNumber': circuitNumber,
        'caseType': caseType,
        'subject': subject,
        'opposingParty': opposingParty,
        'assignedLawyerId': assignedLawyerId,
        'filingDate': filingDate.toIso8601String(),
        'limitationDeadline': limitationDeadline?.toIso8601String(),
        'agreedFee': agreedFee,
        'status': status,
      };

  String toJson() => jsonEncode(toMap());
  factory Case.fromJson(String source) => Case.fromMap(jsonDecode(source));
}
