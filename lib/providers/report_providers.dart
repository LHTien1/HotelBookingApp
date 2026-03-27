import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:booking_app/models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<ReportModel> _reports = <ReportModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _reportsSub;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    disposeListeners(); // ✅ thêm
    super.dispose();
  }

  // ✅ thêm để AuthProvider gọi được
  void disposeListeners() {
    _reportsSub?.cancel();
    _reportsSub = null;
  }

  // ============================================================
  // CREATE REPORT (User) ✅ THÊM
  // ============================================================
  Future<void> addReport({
    required String hotelId,
    String? roomId,
    required String reason,
    required String description,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw 'Bạn cần đăng nhập để gửi báo cáo.';
      }

      final docRef = _db.collection('reports').doc();

      await docRef.set({
        'reportId': docRef.id,
        'reporterUserId': user.uid,
        'reportedHotelId': hotelId,
        'reportedRoomId': roomId,
        'reason': reason,
        'description': description,
        'status': ReportStatus.pending.name,
        // dùng Timestamp.now() để tránh null lúc mới tạo
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOAD REPORTS (Admin)
  // ============================================================
  Future<void> loadReports() async {
    _reportsSub?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _reportsSub = _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
        final list = snap.docs.map((d) => ReportModel.fromFirestore(d)).toList();

        _reports
          ..clear()
          ..addAll(list);

        _isLoading = false;
        notifyListeners();

        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();

        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _isLoading = false;
        _errorMessage ??= 'Tải báo cáo quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  // ============================================================
  // UPDATE STATUS (Admin)
  // ============================================================
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _db.collection('reports').doc(reportId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
