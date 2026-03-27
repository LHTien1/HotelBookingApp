import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;

  final String userId; // ai nhận
  final String? role; // user | hotelOwner | admin (optional)

  final String title;
  final String body;

  final String type; // booking | payment | approval | message | system | promo ...
  final bool isRead;

  final DateTime createdAt;

  final String? actionRoute; // ví dụ: /my-bookings
  final Map<String, dynamic>? actionArgs; // ví dụ: {bookingId: "..."}
  final String? imageUrl;
  final String? priority; // low | normal | high

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.role,
    this.actionRoute,
    this.actionArgs,
    this.imageUrl,
    this.priority,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime parseCreatedAt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return AppNotification(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      role: data['role']?.toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      type: (data['type'] ?? 'system').toString(),
      isRead: (data['isRead'] ?? false) == true,
      createdAt: parseCreatedAt(data['createdAt']),
      actionRoute: data['actionRoute']?.toString(),
      actionArgs: (data['actionArgs'] is Map)
          ? Map<String, dynamic>.from(data['actionArgs'] as Map)
          : null,
      imageUrl: data['imageUrl']?.toString(),
      priority: data['priority']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionRoute': actionRoute,
      'actionArgs': actionArgs,
      'imageUrl': imageUrl,
      'priority': priority,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? role,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? actionRoute,
    Map<String, dynamic>? actionArgs,
    String? imageUrl,
    String? priority,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionRoute: actionRoute ?? this.actionRoute,
      actionArgs: actionArgs ?? this.actionArgs,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
    );
  }
}
