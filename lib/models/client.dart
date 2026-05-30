import 'dart:convert';

class Client {
  final String id;
  final String fullName;
  final String? fullNameAr;
  final String? nationalId;
  final String? phone;
  final String? alternatePhone;
  final String? address;
  final String? notes;
  final String createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.fullName,
    this.fullNameAr,
    this.nationalId,
    this.phone,
    this.alternatePhone,
    this.address,
    this.notes,
    required this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'fullNameAr': fullNameAr,
        'nationalId': nationalId,
        'phone': phone,
        'alternatePhone': alternatePhone,
        'address': address,
        'notes': notes,
        'createdById': createdById,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] ?? '',
        fullName: map['fullName'] ?? '',
        fullNameAr: map['fullNameAr'],
        nationalId: map['nationalId'],
        phone: map['phone'],
        alternatePhone: map['alternatePhone'],
        address: map['address'],
        notes: map['notes'],
        createdById: map['createdById'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
        updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      );

  Map<String, dynamic> toCreatePayload() => {
        'fullName': fullName,
        'fullNameAr': fullNameAr,
        'nationalId': nationalId,
        'phone': phone,
        'alternatePhone': alternatePhone,
        'address': address,
        'notes': notes,
      };

  String toJson() => jsonEncode(toMap());
  factory Client.fromJson(String source) => Client.fromMap(jsonDecode(source));
}
