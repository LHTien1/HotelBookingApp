import '../models/review_model.dart';
import '../models/room_model.dart';

final List<RoomModel> mockRooms = [
  RoomModel(
    roomId: 'r1',
    hotelId: 'h1',
    roomNumber: '101',
    type: 'Phòng Deluxe',
    price: 1500000,
    description:
        'Phòng rộng rãi với tầm nhìn ra thành phố, được trang bị đầy đủ tiện nghi hiện đại.',
    images: [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
    ],
    maxGuests: 2,
    amenities: ['Wifi miễn phí', 'TV màn hình phẳng', 'Điều hòa', 'Mini bar'],
    status: RoomStatus.available,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  RoomModel(
    roomId: 'r2',
    hotelId: 'h1',
    roomNumber: '102',
    type: 'Phòng Standard',
    price: 1000000,
    description: 'Phòng tiêu chuẩn, phù hợp cho các chuyến công tác ngắn ngày.',
    images: [
      'https://images.unsplash.com/photo-1582719508461-905c673771fd?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80',
    ],
    maxGuests: 2,
    amenities: ['Wifi miễn phí', 'TV', 'Điều hòa'],
    status: RoomStatus.available,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  ),
  RoomModel(
    roomId: 'r3',
    hotelId: 'h2',
    roomNumber: '205',
    type: 'Suite Hướng Biển',
    price: 2500000,
    description:
        'Suite sang trọng với ban công riêng nhìn ra biển, mang lại trải nghiệm nghỉ dưỡng tuyệt vời.',
    images: [
      'https://images.unsplash.com/photo-1568495248636-6432b97bd949?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80',
      'https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
    ],
    maxGuests: 3,
    amenities: [
      'Wifi miễn phí',
      'TV 50 inch',
      'Điều hòa',
      'Bồn tắm',
      'Ban công',
    ],
    status: RoomStatus.booked,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  RoomModel(
    roomId: 'r4',
    hotelId: 'h3',
    roomNumber: '301',
    type: 'Phòng Gia Đình',
    price: 2200000,
    description:
        'Phòng rộng rãi với 2 giường lớn, phù hợp cho gia đình có trẻ nhỏ.',
    images: [
      'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
    ],
    maxGuests: 4,
    amenities: ['Wifi miễn phí', 'TV', 'Điều hòa', 'Sofa'],
    status: RoomStatus.available,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
  ),
];

final List<ReviewModel> mockReviews = [
  ReviewModel(
    reviewId: 'rev1',
    userId: 'user101',
    userName: 'Nguyễn Văn A',
    userAvatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
    roomId: 'r1',
    rating: 5.0,
    comment:
        'Phòng rất sạch sẽ và tiện nghi. Nhân viên thân thiện. Tôi chắc chắn sẽ quay lại!',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  ReviewModel(
    reviewId: 'rev2',
    userId: 'user102',
    userName: 'Trần Thị B',
    userAvatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704e',
    roomId: 'r1',
    rating: 4.5,
    comment:
        'Vị trí tuyệt vời, gần trung tâm. Bữa sáng khá ngon. Sẽ giới thiệu cho bạn bè.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  ReviewModel(
    reviewId: 'rev3',
    userId: 'user103',
    userName: 'Lê Văn C',
    userAvatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704f',
    roomId: 'r3',
    rating: 3.5,
    comment:
        'Phòng hơi nhỏ so với mong đợi. View biển đẹp nhưng ban công hơi bụi.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
