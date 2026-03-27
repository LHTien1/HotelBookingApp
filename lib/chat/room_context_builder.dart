import '../models/room_model.dart';

String buildRoomsContext(List<RoomModel> rooms) {
  if (rooms.isEmpty) {
    return 'Hiện tại không có phòng nào.';
  }

  return rooms.map((room) {
    return '''
- roomId: ${room.roomId}
  tên phòng: ${room.type}
  giá: ${room.price} ${room.currency}
  số khách tối đa: ${room.maxGuests}
  trạng thái: ${room.status.name}
  tiện nghi: ${room.amenities.join(', ')}
''';
  }).join('\n');
}
