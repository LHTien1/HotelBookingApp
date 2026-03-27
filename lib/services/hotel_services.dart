import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_model.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';
import 'cloudinary_service.dart';

class HotelService {
  final FirebaseFirestore _db;
  final CloudinaryService _cloudinary;

  HotelService({FirebaseFirestore? db, CloudinaryService? cloudinary})
      : _db = db ?? FirebaseFirestore.instance,
        _cloudinary = cloudinary ?? CloudinaryService();

  CollectionReference<Map<String, dynamic>> get _hotelsCol => _db.collection('hotels');
  CollectionReference<Map<String, dynamic>> get _roomsCol => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _reviewsCol => _db.collection('reviews');

  // ================================
  // Upload helper
  // ================================
  Future<List<String>> _uploadHotelImages(List<CloudinaryBytesFile> files) async {
    if (files.isEmpty) return <String>[];

    final urls = await Future.wait<String>(
      files.map((f) => _cloudinary.uploadBytesFile(f)),
    );

    // loại bỏ rỗng
    return urls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  // ============================================================
  // HOTEL CRUD
  // ============================================================

  Future<void> createHotel({
    required String ownerId,
    required String name,
    required String description,
    required String address,
    required dynamic location, // GeoPoint
    required List<String> amenities,
    required List<CloudinaryBytesFile> imageFiles,
  }) async {
    final imageUrls = await _uploadHotelImages(imageFiles);

    // tạo doc id trước để có hotelId luôn (hữu ích cho join/cache)
    final docRef = _hotelsCol.doc();

    await docRef.set({
      'hotelId': docRef.id, // ✅ thêm hotelId field
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'location': location,
      'amenities': amenities,

      // ✅ thống nhất field ảnh với model
      'images': imageUrls,

      'isActive': true,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHotel({
    required String hotelId,
    String? name,
    String? description,
    String? address,
    dynamic location, // GeoPoint
    List<String>? amenities,
    List<CloudinaryBytesFile>? newImages,
  }) async {
    final update = <String, dynamic>{};

    if (name != null) update['name'] = name;
    if (description != null) update['description'] = description;
    if (address != null) update['address'] = address;
    if (location != null) update['location'] = location;
    if (amenities != null) update['amenities'] = amenities;

    if (newImages != null && newImages.isNotEmpty) {
      final newUrls = await _uploadHotelImages(newImages);
      if (newUrls.isNotEmpty) {
        // ✅ thêm dồn ảnh
        update['images'] = FieldValue.arrayUnion(newUrls);
      }
    }

    if (update.isEmpty) return;

    update['updatedAt'] = FieldValue.serverTimestamp();
    await _hotelsCol.doc(hotelId).update(update);
  }

  Future<void> deleteHotel(String hotelId) async {
    final roomsSnap = await _roomsCol.where('hotelId', isEqualTo: hotelId).get();

    final batch = _db.batch();
    for (final d in roomsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_hotelsCol.doc(hotelId));

    await batch.commit();
  }

  // ============================================================
  // HOTEL STREAMS
  // ============================================================

  Stream<List<HotelModel>> getOwnerHotels(String ownerId) {
    return _hotelsCol
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((s) => s.docs.map((d) => HotelModel.fromFirestore(d)).toList());
  }

  Stream<List<HotelModel>> getAllHotels() {
    return _hotelsCol
        .snapshots()
        .map((s) => s.docs.map((d) => HotelModel.fromFirestore(d)).toList());
  }

  Future<HotelModel?> getHotelById(String hotelId) async {
    final doc = await _hotelsCol.doc(hotelId).get();
    if (!doc.exists) return null;
    return HotelModel.fromFirestore(doc);
  }

  // ============================================================
  // ROOM CRUD
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

    // ✅ NEW
    double? area,
    String? hotelName,
    bool isActive = true,

    // ✅ Owner tạo: pending để Admin duyệt
    RoomStatus status = RoomStatus.pending,
  }) async {
    final docRef = _roomsCol.doc();

    await docRef.set({
      'roomId': docRef.id,
      'hotelId': hotelId,

      if (hotelName != null) 'hotelName': hotelName,
      if (area != null) 'area': area,
      'isActive': isActive,

      'roomNumber': roomNumber,
      'type': type,
      'price': price,
      'description': description,
      'maxGuests': maxGuests,
      'amenities': amenities,

      'imageUrls': imageUrls,

      'status': status.name,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    final update = <String, dynamic>{};

    if (roomNumber != null) update['roomNumber'] = roomNumber;
    if (type != null) update['type'] = type;
    if (price != null) update['price'] = price;
    if (description != null) update['description'] = description;
    if (maxGuests != null) update['maxGuests'] = maxGuests;
    if (amenities != null) update['amenities'] = amenities;
    if (imageUrls != null) update['imageUrls'] = imageUrls;

    if (status != null) update['status'] = status.name;

    if (area != null) update['area'] = area;
    if (isActive != null) update['isActive'] = isActive;

    if (update.isEmpty) return;

    update['updatedAt'] = FieldValue.serverTimestamp();
    await _roomsCol.doc(roomId).update(update);
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomsCol.doc(roomId).delete();
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    final doc = await _roomsCol.doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromFirestore(doc);
  }

  // ============================================================
  // ROOMS STREAMS / ADMIN
  // ============================================================

  Stream<List<RoomModel>> getHotelRooms(String hotelId) {
    return _roomsCol
        .where('hotelId', isEqualTo: hotelId)
        .snapshots()
        .map((s) => s.docs.map((d) => RoomModel.fromFirestore(d)).toList());
  }

  Stream<List<RoomModel>> getPendingRooms() {
    return _roomsCol
        .where('status', isEqualTo: RoomStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.map((d) => RoomModel.fromFirestore(d)).toList());
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _roomsCol.doc(roomId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<RoomModel>> fetchAllRooms() async {
    final snap = await _roomsCol.get();
    return snap.docs.map((d) => RoomModel.fromFirestore(d)).toList();
  }

  /// ✅ NEW: Dùng cho Chatbot (chỉ lấy phòng khả dụng + active)
  Future<List<RoomModel>> fetchAvailableRooms() async {
    final snap = await _roomsCol
        .where('status', isEqualTo: RoomStatus.available.name)
        .where('isActive', isEqualTo: true)
        .get();

    return snap.docs.map((d) => RoomModel.fromFirestore(d)).toList();
  }

  /// NOTE: bản này chỉ filter theo status/isActive.
  Future<List<RoomModel>> searchAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    String? hotelId,
  }) async {
    Query<Map<String, dynamic>> q = _roomsCol
        .where('status', isEqualTo: RoomStatus.available.name)
        .where('isActive', isEqualTo: true);

    if (hotelId != null && hotelId.trim().isNotEmpty) {
      q = q.where('hotelId', isEqualTo: hotelId.trim());
    }

    final snap = await q.get();
    return snap.docs.map((d) => RoomModel.fromFirestore(d)).toList();
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Stream<List<ReviewModel>> getHotelReviews(String hotelId) {
    return _reviewsCol
        .where('hotelId', isEqualTo: hotelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReviewModel.fromFirestore(d)).toList());
  }

  Future<void> addReview({
    required String roomId,
    required String hotelId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required double rating,
    required String comment,
  }) async {
    final docRef = _reviewsCol.doc();

    await docRef.set({
      'reviewId': docRef.id,
      'roomId': roomId,
      'hotelId': hotelId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
