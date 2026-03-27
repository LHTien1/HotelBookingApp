import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, paid, refunded }

enum BookingStatus { pending, confirmed, checkedIn, checkedOut, cancelled }

class BookingModel {
  final String bookingId;
  final String userId;
  final String hotelId;
  final String roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalPrice;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? paymentMethod;
  final String? notes;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    this.paymentStatus = PaymentStatus.pending,
    this.bookingStatus = BookingStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.paymentMethod,
    this.notes,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      hotelId: data['hotelId'] ?? '',
      roomId: data['roomId'] ?? '',
      checkInDate: (data['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      paymentStatus: _stringToPaymentStatus(data['paymentStatus'] ?? 'pending'),
      bookingStatus: _stringToBookingStatus(data['bookingStatus'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'totalPrice': totalPrice,
      'paymentStatus': paymentStatus.name,
      'bookingStatus': bookingStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  static PaymentStatus _stringToPaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  static BookingStatus _stringToBookingStatus(String status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'checkedIn':
        return BookingStatus.checkedIn;
      case 'checkedOut':
        return BookingStatus.checkedOut;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  // Tính số đêm
  int get numberOfNights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  BookingModel copyWith({
    String? bookingId,
    String? userId,
    String? hotelId,
    String? roomId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? totalPrice,
    PaymentStatus? paymentStatus,
    BookingStatus? bookingStatus,
    DateTime? createdAt,
    DateTime? completedAt,
    String? paymentMethod,
    String? notes,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      roomId: roomId ?? this.roomId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}
