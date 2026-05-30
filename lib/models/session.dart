import 'dart:convert';

class Session {
  final String id;
  final String caseId;
  final DateTime sessionDate;
  final String? result;
  final DateTime? nextSessionDate;
  final String? attendedBy;
  final String? notes;
  final String createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Session({
    required this.id,
    required this.caseId,
    required this.sessionDate,
    this.result,
    this.nextSessionDate,
    this.attendedBy,
    this.notes,
    required this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'caseId': caseId,
        'sessionDate': sessionDate.toIso8601String(),
        'result': result,
        'nextSessionDate': nextSessionDate?.toIso8601String(),
        'attendedBy': attendedBy,
        'notes': notes,
        'createdById': createdById,
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] ?? '',
        caseId: map['caseId'] ?? '',
        sessionDate: DateTime.tryParse(map['sessionDate'] ?? '') ?? DateTime.now(),
        result: map['result'],
        nextSessionDate: map['nextSessionDate'] != null ? DateTime.tryParse(map['nextSessionDate']) : null,
        attendedBy: map['attendedBy'],
        notes: map['notes'],
        createdById: map['createdById'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
        updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      );

  Map<String, dynamic> toCreatePayload() => {
        'caseId': caseId,
        'sessionDate': sessionDate.toIso8601String(),
        'result': result,
        'nextSessionDate': nextSessionDate?.toIso8601String(),
        'attendedBy': attendedBy,
        'notes': notes,
      };

  String toJson() => jsonEncode(toMap());
  factory Session.fromJson(String source) => Session.fromMap(jsonDecode(source));
}
