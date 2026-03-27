import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/booking_services.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _bookingsSubscription;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }

  void disposeListeners() {
    _bookingsSubscription?.cancel();
  }

  // Tạo đơn đặt phòng
  Future<String?> createBooking({
    required String userId,
    required String hotelId,
    required String roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String bookingId = await _bookingService.createBooking(
        userId: userId,
        hotelId: hotelId,
        roomId: roomId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();
      return bookingId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Load danh sách đặt phòng của user
  void loadUserBookings(String userId) {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _bookingService.getUserBookings(userId).listen((
      bookings,
    ) {
      _bookings = bookings;
      notifyListeners();
    });
  }

  // Load danh sách đặt phòng của khách sạn
  void loadHotelBookings(String hotelId) {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _bookingService.getHotelBookings(hotelId).listen((
      bookings,
    ) {
      _bookings = bookings;
      notifyListeners();
    });
  }

  // Load tất cả đặt phòng (admin)
  void loadAllBookings() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _bookingService.getAllBookings().listen((bookings) {
      _bookings = bookings;
      notifyListeners();
    });
  }

  // Thanh toán
  Future<bool> makePayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _bookingService.makePayment(
        bookingId: bookingId,
        paymentMethod: paymentMethod,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Xác nhận thanh toán VNPay
  Future<bool> confirmVNPayPayment({
    required String bookingId,
    required String vnpTransactionNo,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _bookingService.confirmVNPayPayment(
        bookingId: bookingId,
        vnpTransactionNo: vnpTransactionNo,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Xác nhận thanh toán Momo
  Future<bool> confirmMomoPayment({required String bookingId}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _bookingService.confirmMomoPayment(bookingId: bookingId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Hủy đặt phòng
  Future<bool> cancelBooking(String bookingId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _bookingService.cancelBooking(bookingId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check-in
  Future<bool> checkIn(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookingService.checkIn(bookingId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check-out
  Future<bool> checkOut(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookingService.checkOut(bookingId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Lấy lịch sử
  Future<List<BookingModel>> getHistory(String userId) async {
    try {
      return await _bookingService.getBookingHistory(userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Xác nhận đặt phòng
  Future<bool> confirmBooking(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _bookingService.confirmBooking(bookingId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Tính doanh thu
  Future<double> calculateRevenue({
    required String hotelId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _bookingService.calculateHotelRevenue(
        hotelId: hotelId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 0.0;
    }
  }

  // Lấy thống kê
  Future<Map<String, int>> getStatistics({required String hotelId}) async {
    try {
      return await _bookingService.getBookingStatistics(hotelId: hotelId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return {};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
