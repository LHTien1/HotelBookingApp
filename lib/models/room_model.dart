import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { pending, available, booked, maintenance, rejected }

class RoomModel {
  // =========================
  // Identity / Relations
  // =========================
  final String roomId;
  final String hotelId;

  /// ✅ thêm: tên khách sạn (để hiển thị, tránh join)
  final String hotelName;

  /// ✅ thêm: id loại phòng (standard/deluxe/vip), tên hiển thị nếu muốn
  final String typeId;
  final String typeName;

  // =========================
  // Core room info
  // =========================
  final String roomNumber;

  /// ✅ thêm: để sort đúng 1,2,10 (nếu không có thì tự tính từ roomNumber)
  final int roomNumberInt;

  /// giữ field cũ (type) để UI/logic cũ không vỡ
  final String type;

  final double price;

  /// ✅ thêm: đơn vị tiền
  final String currency;

  final String description;

  /// ✅ thêm: số giường, diện tích
  final int beds;
  final double area;

  final int maxGuests;
  final List<String> amenities;

  // =========================
  // Media
  // =========================
  /// list ảnh (đọc được cả 'images' và 'imageUrls')
  final List<String> images;

  /// ✅ thêm: ảnh đại diện (tương thích field imageUrl nếu có)
  final String imageUrl;

  // =========================
  // Location (optional)
  // =========================
  final String address;
  final GeoPoint? location; // hoặc dùng lat/lng
  final double? lat;
  final double? lng;

  // =========================
  // Status / moderation
  // =========================
  final RoomStatus status;

  /// ✅ thêm: bật/tắt hiển thị
  final bool isActive;

  /// ✅ thêm: uid chủ khách sạn (nếu có)
  final String ownerId;

  // =========================
  // Quick stats (optional)
  // =========================
  /// ✅ thêm: điểm trung bình + số lượng đánh giá để load nhanh
  final double avgRating;
  final int reviewCount;

  /// ✅ thêm: tuỳ chọn thống kê khác
  final int bookingCount;
  final int viewCount;

  // =========================
  // Timestamps
  // =========================
  final DateTime createdAt;

  /// ✅ thêm: thời gian cập nhật
  final DateTime? updatedAt;

  RoomModel({
    required this.roomId,
    required this.hotelId,
    this.hotelName = '',

    this.typeId = '',
    this.typeName = '',

    required this.roomNumber,
    int? roomNumberInt,

    this.type = '',
    this.price = 0,
    this.currency = 'VND',

    this.description = '',

    this.beds = 0,
    this.area = 0,

    this.maxGuests = 1,
    this.amenities = const [],

    this.images = const [],
    this.imageUrl = '',

    this.address = '',
    this.location,
    this.lat,
    this.lng,

    this.status = RoomStatus.pending,

    this.isActive = true,
    this.ownerId = '',

    this.avgRating = 0,
    this.reviewCount = 0,
    this.bookingCount = 0,
    this.viewCount = 0,

    required this.createdAt,
    this.updatedAt,
  }) : roomNumberInt = roomNumberInt ?? _calcRoomNumberInt(roomNumber);

  // =========================
  // Firestore helpers
  // =========================
  static String _s(dynamic v) => (v ?? '').toString().trim();

  static double _d(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final t = _s(v).replaceAll(',', '');
    return double.tryParse(t) ?? fallback;
  }

  static int _i(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_s(v)) ?? fallback;
  }

  static bool _b(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final t = _s(v).toLowerCase();
    if (t == 'true' || t == '1' || t == 'yes') return true;
    if (t == 'false' || t == '0' || t == 'no') return false;
    return fallback;
  }

  static DateTime _toDate(dynamic v, {DateTime? fallback}) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return fallback ?? DateTime.now();
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
    }
    // nếu lỡ lưu dạng string "a,b,c"
    final raw = _s(v);
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[,;|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static int _calcRoomNumberInt(String roomNumber) {
    final onlyDigits = roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(onlyDigits) ?? 0;
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    // images: hỗ trợ cả images/imageUrls, imageUrl
    final imgs = _stringList(data['images']).isNotEmpty
        ? _stringList(data['images'])
        : _stringList(data['imageUrls']);

    final primaryImage = _s(data['imageUrl']).isNotEmpty
        ? _s(data['imageUrl'])
        : (imgs.isNotEmpty ? imgs.first : '');

    // location: GeoPoint hoặc lat/lng
    GeoPoint? geo;
    if (data['location'] is GeoPoint) geo = data['location'] as GeoPoint;

    final lat = (data['lat'] is num) ? (data['lat'] as num).toDouble() : null;
    final lng = (data['lng'] is num) ? (data['lng'] as num).toDouble() : null;

    // timestamps: hỗ trợ createdAt/created_at
    final created = _toDate(data['createdAt'] ?? data['created_at'],
        fallback: DateTime.now());
    final updatedRaw = data['updatedAt'] ?? data['updated_at'];
    final updated = updatedRaw == null ? null : _toDate(updatedRaw);

    final roomNumber = _s(data['roomNumber']);
    final roomNumberInt = _i(data['roomNumberInt'], fallback: _calcRoomNumberInt(roomNumber));

    return RoomModel(
      roomId: doc.id,
      hotelId: _s(data['hotelId']),
      hotelName: _s(data['hotelName']),

      typeId: _s(data['typeId']),
      typeName: _s(data['typeName']),

      roomNumber: roomNumber,
      roomNumberInt: roomNumberInt,

      // giữ tương thích: nếu không có typeName thì fallback từ type
      type: _s(data['type']).isNotEmpty ? _s(data['type']) : _s(data['typeName']),

      price: _d(data['price'], fallback: 0),
      currency: _s(data['currency']).isNotEmpty ? _s(data['currency']) : 'VND',

      description: _s(data['description']),

      beds: _i(data['beds'], fallback: 0),
      area: _d(data['area'], fallback: 0),

      maxGuests: _i(data['maxGuests'], fallback: 1),
      amenities: _stringList(data['amenities']),

      images: imgs,
      imageUrl: primaryImage,

      address: _s(data['address']),
      location: geo,
      lat: lat,
      lng: lng,

      status: _stringToStatus(_s(data['status']).isNotEmpty ? _s(data['status']) : 'pending'),

      isActive: _b(data['isActive'], fallback: true),
      ownerId: _s(data['ownerId']),

      avgRating: _d(data['avgRating'], fallback: 0),
      reviewCount: _i(data['reviewCount'], fallback: 0),
      bookingCount: _i(data['bookingCount'], fallback: 0),
      viewCount: _i(data['viewCount'], fallback: 0),

      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    final imgs = images;
    final primary = imageUrl.isNotEmpty ? imageUrl : (imgs.isNotEmpty ? imgs.first : '');

    return {
      // relations
      'hotelId': hotelId,
      'hotelName': hotelName,

      // identity
      'roomNumber': roomNumber,
      'roomNumberInt': roomNumberInt,

      // type
      'typeId': typeId,
      'typeName': typeName,
      'type': type, // giữ tương thích

      // pricing
      'price': price,
      'currency': currency,

      // details
      'description': description,
      'maxGuests': maxGuests,
      'beds': beds,
      'area': area,

      // amenities & images
      'amenities': amenities,
      'images': imgs,       // field cũ
      'imageUrls': imgs,    // field mới (tương thích các màn khác)
      'imageUrl': primary,  // ảnh đại diện

      // location
      'address': address,
      'location': location,
      'lat': lat,
      'lng': lng,

      // status & admin
      'status': status.name,
      'isActive': isActive,
      'ownerId': ownerId,

      // stats
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'bookingCount': bookingCount,
      'viewCount': viewCount,

      // timestamps (giữ cả 2 kiểu để tương thích)
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static RoomStatus _stringToStatus(String statusStr) {
    switch (statusStr) {
      case 'available':
        return RoomStatus.available;
      case 'booked':
        return RoomStatus.booked;
      case 'maintenance':
        return RoomStatus.maintenance;
      case 'rejected':
        return RoomStatus.rejected;
      default:
        return RoomStatus.pending;
    }
  }

  RoomModel copyWith({
    String? roomId,
    String? hotelId,
    String? hotelName,

    String? typeId,
    String? typeName,

    String? roomNumber,
    int? roomNumberInt,

    String? type,
    double? price,
    String? currency,

    String? description,
    int? beds,
    double? area,

    List<String>? images,
    String? imageUrl,

    int? maxGuests,
    List<String>? amenities,

    String? address,
    GeoPoint? location,
    double? lat,
    double? lng,

    RoomStatus? status,
    bool? isActive,
    String? ownerId,

    double? avgRating,
    int? reviewCount,
    int? bookingCount,
    int? viewCount,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,

      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,

      roomNumber: roomNumber ?? this.roomNumber,
      roomNumberInt: roomNumberInt ?? this.roomNumberInt,

      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency ?? this.currency,

      description: description ?? this.description,
      beds: beds ?? this.beds,
      area: area ?? this.area,

      images: images ?? this.images,
      imageUrl: imageUrl ?? this.imageUrl,

      maxGuests: maxGuests ?? this.maxGuests,
      amenities: amenities ?? this.amenities,

      address: address ?? this.address,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,

      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,

      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      bookingCount: bookingCount ?? this.bookingCount,
      viewCount: viewCount ?? this.viewCount,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
