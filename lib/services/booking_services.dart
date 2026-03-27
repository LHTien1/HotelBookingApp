import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_model.dart';
import '../models/room_model.dart';
import 'firebase_services.dart';
import 'hotel_services.dart';

class BookingService {
  final FirebaseService _firebaseService = FirebaseService();
  final HotelService _hotelService = HotelService();

  // Tạo đơn đặt phòng mới
  Future<String> createBooking({
    required String userId,
    required String hotelId,
    required String roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    String? notes,
  }) async {
    try {
      // Lấy thông tin phòng để tính giá
      RoomModel? room = await _hotelService.getRoomById(roomId);
      if (room == null) {
        throw 'Không tìm thấy thông tin phòng';
      }

      // Tính tổng tiền
      int numberOfNights = checkOutDate.difference(checkInDate).inDays;
      if (numberOfNights <= 0) numberOfNights = 1;

      double totalPrice = room.price * numberOfNights;

      BookingModel booking = BookingModel(
        bookingId: '',
        userId: userId,
        hotelId: hotelId,
        roomId: roomId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        totalPrice: totalPrice,
        createdAt: DateTime.now(),
        notes: notes,
      );

      DocumentReference docRef = await _firebaseService.bookingsCollection.add(
        booking.toMap(),
      );

      // Update the booking with its own ID
      await docRef.update({'bookingId': docRef.id});

      return docRef.id;
    } catch (e) {
      throw 'Không thể đặt phòng: $e';
    }
  }

  // Lấy danh sách đặt phòng của người dùng
  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firebaseService.bookingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
        });
  }

  // Lấy danh sách đặt phòng của khách sạn (cho chủ KS)
  Stream<List<BookingModel>> getHotelBookings(String hotelId) {
    return _firebaseService.bookingsCollection
        .where('hotelId', isEqualTo: hotelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
        });
  }

  // Lấy tất cả đặt phòng (cho admin)
  Stream<List<BookingModel>> getAllBookings() {
    return _firebaseService.bookingsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
        });
  }

  // Lấy thông tin chi tiết đặt phòng
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      DocumentSnapshot doc = await _firebaseService.bookingsCollection
          .doc(bookingId)
          .get();

      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Không thể lấy thông tin đặt phòng: $e';
    }
  }

  // Thanh toán đặt phòng
  Future<void> makePayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    try {
      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'paymentStatus': 'paid',
        'paymentMethod': paymentMethod,
        'bookingStatus': 'confirmed',
      });

      // Cập nhật trạng thái phòng
      BookingModel? booking = await getBookingById(bookingId);
      if (booking != null) {
        await _firebaseService.roomsCollection.doc(booking.roomId).update({
          'status': 'booked',
        });
      }
    } catch (e) {
      throw 'Không thể thanh toán: $e';
    }
  }

  // Xác nhận thanh toán VNPay
  Future<void> confirmVNPayPayment({
    required String bookingId,
    required String vnpTransactionNo,
  }) async {
    try {
      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'paymentStatus': 'paid',
        'paymentMethod': 'VNPay',
        'bookingStatus': 'confirmed',
        'vnpTransactionNo': vnpTransactionNo,
        'paidAt': DateTime.now().toIso8601String(),
      });

      // Cập nhật trạng thái phòng
      BookingModel? booking = await getBookingById(bookingId);
      if (booking != null) {
        await _firebaseService.roomsCollection.doc(booking.roomId).update({
          'status': 'booked',
        });
      }
    } catch (e) {
      throw 'Không thể xác nhận thanh toán VNPay: $e';
    }
  }

  // Xác nhận thanh toán Momo
  Future<void> confirmMomoPayment({required String bookingId}) async {
    try {
      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'paymentStatus': 'paid',
        'paymentMethod': 'Momo',
        'bookingStatus': 'confirmed',
        'paidAt': DateTime.now().toIso8601String(),
      });

      // Cập nhật trạng thái phòng
      BookingModel? booking = await getBookingById(bookingId);
      if (booking != null) {
        await _firebaseService.roomsCollection.doc(booking.roomId).update({
          'status': 'booked',
        });
      }
    } catch (e) {
      throw 'Không thể xác nhận thanh toán Momo: $e';
    }
  }

  // Hủy đặt phòng
  Future<void> cancelBooking(String bookingId) async {
    try {
      BookingModel? booking = await getBookingById(bookingId);
      if (booking == null) {
        throw 'Không tìm thấy đơn đặt phòng';
      }

      // Kiểm tra có thể hủy không (ví dụ: trước 24h)
      DateTime now = DateTime.now();
      if (booking.checkInDate.difference(now).inHours < 24) {
        throw 'Không thể hủy phòng trong vòng 24h trước check-in';
      }

      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'bookingStatus': 'cancelled',
      });

      // Hoàn tiền nếu đã thanh toán
      if (booking.paymentStatus == PaymentStatus.paid) {
        await _firebaseService.bookingsCollection.doc(bookingId).update({
          'paymentStatus': 'refunded',
        });
      }

      // Cập nhật trạng thái phòng
      await _firebaseService.roomsCollection.doc(booking.roomId).update({
        'status': 'available',
      });
    } catch (e) {
      throw 'Không thể hủy đặt phòng: $e';
    }
  }

  // Check-in
  Future<void> checkIn(String bookingId) async {
    try {
      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'bookingStatus': 'checkedIn',
      });
    } catch (e) {
      throw 'Không thể check-in: $e';
    }
  }

  // Check-out
  Future<void> checkOut(String bookingId) async {
    try {
      BookingModel? booking = await getBookingById(bookingId);
      if (booking == null) {
        throw 'Không tìm thấy đơn đặt phòng';
      }

      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'bookingStatus': 'checkedOut',
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Cập nhật trạng thái phòng về available
      await _firebaseService.roomsCollection.doc(booking.roomId).update({
        'status': 'available',
      });
    } catch (e) {
      throw 'Không thể check-out: $e';
    }
  }

  // Lấy lịch sử đặt phòng (đã hoàn thành)
  Future<List<BookingModel>> getBookingHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firebaseService.bookingsCollection
          .where('userId', isEqualTo: userId)
          .where('bookingStatus', isEqualTo: 'checkedOut')
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Không thể lấy lịch sử: $e';
    }
  }

  // Tính doanh thu của khách sạn
  Future<double> calculateHotelRevenue({
    required String hotelId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firebaseService.bookingsCollection
          .where('hotelId', isEqualTo: hotelId)
          .where('paymentStatus', isEqualTo: 'paid');

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      QuerySnapshot snapshot = await query.get();

      double totalRevenue = 0;
      for (var doc in snapshot.docs) {
        BookingModel booking = BookingModel.fromFirestore(doc);
        totalRevenue += booking.totalPrice;
      }

      return totalRevenue;
    } catch (e) {
      throw 'Không thể tính doanh thu: $e';
    }
  }

  // Thống kê số lượng đặt phòng
  Future<Map<String, int>> getBookingStatistics({
    required String hotelId,
  }) async {
    try {
      QuerySnapshot snapshot = await _firebaseService.bookingsCollection
          .where('hotelId', isEqualTo: hotelId)
          .get();

      int total = snapshot.docs.length;
      int pending = 0;
      int confirmed = 0;
      int checkedIn = 0;
      int checkedOut = 0;
      int cancelled = 0;

      for (var doc in snapshot.docs) {
        BookingModel booking = BookingModel.fromFirestore(doc);
        switch (booking.bookingStatus) {
          case BookingStatus.pending:
            pending++;
            break;
          case BookingStatus.confirmed:
            confirmed++;
            break;
          case BookingStatus.checkedIn:
            checkedIn++;
            break;
          case BookingStatus.checkedOut:
            checkedOut++;
            break;
          case BookingStatus.cancelled:
            cancelled++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'checkedIn': checkedIn,
        'checkedOut': checkedOut,
        'cancelled': cancelled,
      };
    } catch (e) {
      throw 'Không thể lấy thống kê: $e';
    }
  }

  // Xác nhận đặt phòng (cho chủ KS)
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _firebaseService.bookingsCollection.doc(bookingId).update({
        'bookingStatus': 'confirmed',
      });
    } catch (e) {
      throw 'Không thể xác nhận: $e';
    }
  }

  // Kiểm tra xem người dùng đã từng đặt phòng này chưa
  Future<bool> hasUserBookedRoom(String userId, String roomId) async {
    try {
      QuerySnapshot snapshot = await _firebaseService.bookingsCollection
          .where('userId', isEqualTo: userId)
          .where('roomId', isEqualTo: roomId)
          .where('bookingStatus', isEqualTo: 'checkedOut')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
