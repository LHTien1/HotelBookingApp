import 'package:cloud_firestore/cloud_firestore.dart';

enum HotelStatus { pending, approved, rejected }

class HotelModel {
  final String hotelId;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final GeoPoint location;
  final List<String> images;
  final List<String> amenities;
  final double rating;
  final int totalReviews;
  final HotelStatus status;
  final DateTime createdAt;
  final bool isActive;

  HotelModel({
    required this.hotelId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.location,
    required this.images,
    required this.amenities,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.status = HotelStatus.pending,
    required this.createdAt,
    this.isActive = true,
  });

  factory HotelModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    final ts = data['createdAt'];
    final created = (ts is Timestamp) ? ts.toDate() : DateTime.now();

    final loc = data['location'];
    final geo = (loc is GeoPoint) ? loc : const GeoPoint(0, 0);

    return HotelModel(
      hotelId: doc.id,
      ownerId: (data['ownerId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      location: geo,
      images: List<String>.from((data['images'] ?? const []) as List),
      amenities: List<String>.from((data['amenities'] ?? const []) as List),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (data['totalReviews'] as num?)?.toInt() ?? 0,
      status: _stringToStatus((data['status'] ?? 'pending').toString()),
      createdAt: created,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'location': location,
      'images': images,
      'amenities': amenities,
      'rating': rating,
      'totalReviews': totalReviews,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  static HotelStatus _stringToStatus(String statusStr) {
    switch (statusStr) {
      case 'approved':
        return HotelStatus.approved;
      case 'rejected':
        return HotelStatus.rejected;
      default:
        return HotelStatus.pending;
    }
  }

  HotelModel copyWith({
    String? hotelId,
    String? ownerId,
    String? name,
    String? description,
    String? address,
    GeoPoint? location,
    List<String>? images,
    List<String>? amenities,
    double? rating,
    int? totalReviews,
    HotelStatus? status,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return HotelModel(
      hotelId: hotelId ?? this.hotelId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      location: location ?? this.location,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
