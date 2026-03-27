import 'dart:async';
import 'dart:math';

import 'package:booking_app/models/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/hotel_services.dart';
import '../services/cloudinary_service.dart';

class HotelProvider extends ChangeNotifier {
  final HotelService _hotelService = HotelService();

  // data
  final List<HotelModel> _hotels = <HotelModel>[];
  final List<RoomModel> _rooms = <RoomModel>[];
  final List<ReviewModel> _reviews = <ReviewModel>[];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _hotelsSubscription;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _reviewsSubscription;

  List<HotelModel> get hotels => _hotels;
  List<RoomModel> get rooms => _rooms;
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================================
  // HOTEL NAME CACHE (hiện tên KS thay vì hotelId)
  // ============================================================
  final Map<String, String> _hotelNameCache = <String, String>{};
  String? getHotelNameCached(String hotelId) => _hotelNameCache[hotelId];

  // ✅ Debounce/Queue để tránh spam query khi stream rooms update liên tục
  Timer? _preloadDebounce;
  final Set<String> _preloadQueue = <String>{};
  bool _preloading = false;

  void queuePreloadHotelNames(Iterable<String> hotelIds) {
    for (final id in hotelIds) {
      final v = id.trim();
      if (v.isNotEmpty && !_hotelNameCache.containsKey(v)) {
        _preloadQueue.add(v);
      }
    }

    _preloadDebounce?.cancel();
    _preloadDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (_preloading || _preloadQueue.isEmpty) return;
      _preloading = true;

      final ids = _preloadQueue.toList();
      _preloadQueue.clear();

      try {
        await preloadHotelNames(ids);
      } finally {
        _preloading = false;
      }
    });
  }

  Future<void> preloadHotelNames(Iterable<String> hotelIds) async {
    final missing = hotelIds
        .where((id) => id.trim().isNotEmpty && !_hotelNameCache.containsKey(id))
        .toSet();

    if (missing.isEmpty) return;

    final fs = FirebaseFirestore.instance;
    final ids = missing.toList();

    // whereIn tối đa 10 phần tử / lần
    for (var i = 0; i < ids.length; i += 10) {
      final part = ids.sublist(i, min(i + 10, ids.length));

      final snapByDocId = await fs
          .collection('hotels')
          .where(FieldPath.documentId, whereIn: part)
          .get();

      for (final doc in snapByDocId.docs) {
        final data = doc.data();
        final name = (data['name'] ?? data['hotelName'] ?? data['tenKhachSan'] ?? '')
            .toString()
            .trim();

        if (name.isNotEmpty) {
          _hotelNameCache[doc.id] = name;
        }
      }

      final notFound = part.where((id) => !_hotelNameCache.containsKey(id)).toList();

      if (notFound.isNotEmpty) {
        final snapByField = await fs
            .collection('hotels')
            .where('hotelId', whereIn: notFound)
            .get();

        for (final doc in snapByField.docs) {
          final data = doc.data();
          final idVal = (data['hotelId'] ?? '').toString().trim();
          final name = (data['name'] ?? data['hotelName'] ?? data['tenKhachSan'] ?? '')
              .toString()
              .trim();

          if (idVal.isNotEmpty && name.isNotEmpty) {
            _hotelNameCache[idVal] = name;
          }
        }
      }
    }

    notifyListeners();
  }

  // ============================================================
  // Lifecycle
  // ============================================================
  @override
  void dispose() {
    _preloadDebounce?.cancel();
    disposeListeners();
    super.dispose();
  }

  void disposeListeners() {
    _hotelsSubscription?.cancel();
    _roomsSubscription?.cancel();
    _reviewsSubscription?.cancel();

    _hotelsSubscription = null;
    _roomsSubscription = null;
    _reviewsSubscription = null;
  }

  // ============================================================
  // HOTEL
  // ============================================================

  Future<bool> createHotel({
    required String ownerId,
    required String name,
    required String description,
    required String address,
    required GeoPoint location,
    required List<String> amenities,
    required List<CloudinaryBytesFile> images,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.createHotel(
        ownerId: ownerId,
        name: name,
        description: description,
        address: address,
        location: location,
        amenities: amenities,
        imageFiles: images,
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

  Future<bool> updateHotel({
    required String hotelId,
    String? name,
    String? description,
    String? address,
    GeoPoint? location,
    List<String>? amenities,
    List<CloudinaryBytesFile>? newImages,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.updateHotel(
        hotelId: hotelId,
        name: name,
        description: description,
        address: address,
        location: location,
        amenities: amenities,
        newImages: newImages,
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

  Future<HotelModel?> getHotelById(String hotelId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      return await _hotelService.getHotelById(hotelId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHotel(String hotelId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.deleteHotel(hotelId);
      _hotels.removeWhere((h) => h.hotelId == hotelId);

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

  // ============================================================
  // ROOMS
  // ============================================================

  Future<void> createRoom({
    required String hotelId,
    required String roomNumber,
    required String type,
    required double price,
    required String description,
    required int maxGuests,
    required List<String> amenities,
    required List<String> imageUrls,

    // ✅ NEW (optional)
    double? area,
    String? hotelName,
    RoomStatus status = RoomStatus.pending,
    bool isActive = true,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.createRoom(
        hotelId: hotelId,
        hotelName: hotelName,
        roomNumber: roomNumber,
        type: type,
        price: price,
        description: description,
        maxGuests: maxGuests,
        amenities: amenities,
        imageUrls: imageUrls,
        area: area,
        status: status,
        isActive: isActive,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRoom({
    required String roomId,
    String? roomNumber,
    String? type,
    double? price,
    String? description,
    int? maxGuests,
    List<String>? amenities,
    RoomStatus? status,
    List<String>? imageUrls,

    // ✅ NEW
    double? area,
    bool? isActive,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.updateRoom(
        roomId: roomId,
        roomNumber: roomNumber,
        type: type,
        price: price,
        description: description,
        maxGuests: maxGuests,
        amenities: amenities,
        status: status,
        imageUrls: imageUrls,
        area: area,
        isActive: isActive,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHotelRooms(String hotelId) async {
    await _roomsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _roomsSubscription = _hotelService.getHotelRooms(hotelId).listen(
          (rooms) {
        _rooms
          ..clear()
          ..addAll(rooms);

        _isLoading = false;

        queuePreloadHotelNames(rooms.map((e) => e.hotelId));
        _errorMessage = null;

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
        _errorMessage ??= 'Tải danh sách phòng quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<bool> deleteRoom(String roomId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.deleteRoom(roomId);
      _rooms.removeWhere((r) => r.roomId == roomId);

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

  // ✅ NEW: Load rooms thật cho Chatbot
  Future<void> fetchAvailableRoomsForChat() async {
    try {
      // hủy stream rooms khác nếu đang listen, tránh dữ liệu bị ghi đè liên tục
      await _roomsSubscription?.cancel();
      _roomsSubscription = null;

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final list = await _hotelService.fetchAvailableRooms();
      _rooms
        ..clear()
        ..addAll(list);

      queuePreloadHotelNames(list.map((e) => e.hotelId));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      return await _hotelService.getRoomById(roomId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Future<void> loadHotelReviews(String hotelId) async {
    await _reviewsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _reviewsSubscription = _hotelService.getHotelReviews(hotelId).listen(
          (reviews) {
        _reviews
          ..clear()
          ..addAll(reviews);

        _isLoading = false;
        _errorMessage = null;

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
        _errorMessage ??= 'Tải đánh giá quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<void> addReview({
    required String roomId,
    required String hotelId,
    required double rating,
    required String comment,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.addReview(
        roomId: roomId,
        hotelId: hotelId,
        userId: 'mock_user_id',
        userName: 'Mock User',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<void> loadPendingRooms() async {
    await _roomsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _roomsSubscription = _hotelService.getPendingRooms().listen(
          (rooms) {
        _rooms
          ..clear()
          ..addAll(rooms);

        queuePreloadHotelNames(rooms.map((e) => e.hotelId));

        _isLoading = false;
        _errorMessage = null;

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
        _errorMessage ??= 'Tải phòng chờ duyệt quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.updateRoomStatus(roomId, status);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<RoomModel>> searchRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    String? hotelId,
  }) async {
    try {
      return await _hotelService.searchAvailableRooms(
        checkIn: checkIn,
        checkOut: checkOut,
        hotelId: hotelId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> fetchAllRooms() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final allRooms = await _hotelService.fetchAllRooms();
      _rooms
        ..clear()
        ..addAll(allRooms);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UTILS
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
