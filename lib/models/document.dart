import 'dart:convert';

class Document {
  final String id;
  final String caseId;
  final String name;
  final String fileUrl;
  final String docCategory;
  final String uploadedById;
  final DateTime? createdAt;

  Document({
    required this.id,
    required this.caseId,
    required this.name,
    required this.fileUrl,
    required this.docCategory,
    required this.uploadedById,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'caseId': caseId,
        'name': name,
        'fileUrl': fileUrl,
        'docCategory': docCategory,
        'uploadedById': uploadedById,
      };

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'] ?? '',
        caseId: map['caseId'] ?? '',
        name: map['name'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
        docCategory: map['docCategory'] ?? '',
        uploadedById: map['uploadedById'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      );

  String toJson() => jsonEncode(toMap());
  factory Document.fromJson(String source) => Document.fromMap(jsonDecode(source));
}
