import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import 'firebase_services.dart';

class ReportService {
  final FirebaseService _firebaseService = FirebaseService();

  Stream<List<ReportModel>> getReports() {
    return _firebaseService.reportsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _firebaseService.reportsCollection
          .doc(reportId)
          .update({'status': status.name});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReport({
    required String reporterUserId,
    required String reportedHotelId,
    String? reportedRoomId,
    required String reason,
    required String description,
  }) async {
    try {
      DocumentReference reportRef = _firebaseService.reportsCollection.doc();
      ReportModel newReport = ReportModel(
        reportId: reportRef.id,
        reporterUserId: reporterUserId,
        reportedHotelId: reportedHotelId,
        reportedRoomId: reportedRoomId,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
      );
      await reportRef.set(newReport.toMap());
    } catch (e) {
      rethrow;
    }
  }
}
