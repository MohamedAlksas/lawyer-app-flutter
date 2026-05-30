import 'dart:convert';

class Document {
  final String id;
  final String caseId;
  final String fileName;
  final String fileUrl;
  final String category;
  final String createdById;
  final DateTime? createdAt;

  Document({
    required this.id,
    required this.caseId,
    required this.fileName,
    required this.fileUrl,
    required this.category,
    required this.createdById,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'caseId': caseId,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'category': category,
        'createdById': createdById,
      };

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'] ?? '',
        caseId: map['caseId'] ?? '',
        fileName: map['fileName'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
        category: map['category'] ?? '',
        createdById: map['createdById'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      );

  String toJson() => jsonEncode(toMap());
  factory Document.fromJson(String source) => Document.fromMap(jsonDecode(source));
}
