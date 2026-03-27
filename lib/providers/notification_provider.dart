import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db;

  NotificationProvider({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSub;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  /// ✅ Stream danh sách thông báo
  Stream<List<AppNotification>> streamNotifications({
    required String userId,
    String? role,
    bool onlyUnread = false,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q =
    _col.where('userId', isEqualTo: userId);

    if (role != null && role.trim().isNotEmpty) {
      q = q.where('role', isEqualTo: role);
    }

    if (onlyUnread) {
      q = q.where('isRead', isEqualTo: false);
    }

    q = q.orderBy('createdAt', descending: true).limit(limit);

    return q.snapshots().map((snap) {
      return snap.docs.map(AppNotification.fromDoc).toList();
    });
  }

  /// ✅ Lắng nghe số chưa đọc (badge)
  void startUnreadListener({
    required String userId,
    String? role,
  }) {
    _unreadSub?.cancel();

    Query<Map<String, dynamic>> q =
    _col.where('userId', isEqualTo: userId).where('isRead', isEqualTo: false);

    if (role != null && role.trim().isNotEmpty) {
      q = q.where('role', isEqualTo: role);
    }

    _unreadSub = q.snapshots().listen((snap) {
      _unreadCount = snap.docs.length;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String id) async {
    await _col.doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead({
    required String userId,
    String? role,
  }) async {
    Query<Map<String, dynamic>> q =
    _col.where('userId', isEqualTo: userId).where('isRead', isEqualTo: false);

    if (role != null && role.trim().isNotEmpty) {
      q = q.where('role', isEqualTo: role);
    }

    final snap = await q.get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _col.doc(id).delete();
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }
}
