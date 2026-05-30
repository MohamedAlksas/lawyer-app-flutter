import 'dart:convert';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'isRead': isRead,
      };

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        type: map['type'] ?? '',
        relatedId: map['relatedId'],
        isRead: map['isRead'] ?? false,
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      );

  String toJson() => jsonEncode(toMap());
  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(jsonDecode(source));
}
