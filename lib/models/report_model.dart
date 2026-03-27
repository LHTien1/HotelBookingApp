import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, resolved, dismissed }

class ReportModel {
  final String reportId;
  final String reporterUserId;
  final String reportedHotelId;
  final String? reportedRoomId;
  final String reason;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.reporterUserId,
    required this.reportedHotelId,
    this.reportedRoomId,
    required this.reason,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId: doc.id,
      reporterUserId: data['reporterUserId'],
      reportedHotelId: data['reportedHotelId'],
      reportedRoomId: data['reportedRoomId'],
      reason: data['reason'],
      description: data['description'],
      status: _stringToStatus(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterUserId': reporterUserId,
      'reportedHotelId': reportedHotelId,
      'reportedRoomId': reportedRoomId,
      'reason': reason,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ReportStatus _stringToStatus(String status) {
    switch (status) {
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}
