import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import 'firebase_services.dart';
import 'cloudinary_service.dart';

class ChatService {
  final FirebaseService _firebaseService = FirebaseService();
  final CloudinaryService _cloudinary = CloudinaryService();

  // Tạo hoặc lấy chat giữa 2 người
  Future<String> getOrCreateChat({
    required String userId,
    required String ownerId,
    required String userName,
    required String ownerName,
  }) async {
    try {
      QuerySnapshot existingChats = await _firebaseService.chatsCollection
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in existingChats.docs) {
        List<String> participants = List<String>.from(doc['participants']);
        if (participants.contains(ownerId)) {
          return doc.id;
        }
      }

      ChatModel chat = ChatModel(
        chatId: '',
        participants: [userId, ownerId],
        participantNames: {userId: userName, ownerId: ownerName},
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: {userId: 0, ownerId: 0},
      );

      DocumentReference docRef =
      await _firebaseService.chatsCollection.add(chat.toMap());

      return docRef.id;
    } catch (e) {
      throw 'Không thể tạo chat: $e';
    }
  }

  // Gửi tin nhắn
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,

    /// ✅ ảnh dạng bytes (web + mobile)
    CloudinaryBytesFile? imageFile,
  }) async {
    try {
      String? imageUrl;

      // ✅ Upload ảnh lên Cloudinary nếu có
      if (imageFile != null) {
        imageUrl = await _cloudinary.uploadBytes(
          imageFile.bytes,
          fileName: imageFile.fileName,
          mimeType: imageFile.mimeType,
          folder: 'hotel_rooms/chat_images/$chatId',
        );
      }

      final message = MessageModel(
        messageId: '',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        // nếu MessageModel của bạn có isRead thì nên set mặc định:
        // isRead: false,
      );

      // Thêm message vào subcollection
      await _firebaseService.chatsCollection
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Cập nhật lastMessage trong chat
      final chatDoc = await _firebaseService.chatsCollection.doc(chatId).get();
      final chat = ChatModel.fromFirestore(chatDoc);
      final receiverId = chat.participants.firstWhere((id) => id != senderId);

      await _firebaseService.chatsCollection.doc(chatId).update({
        'lastMessage': (text.trim().isEmpty && imageUrl != null)
            ? '📷 Hình ảnh'
            : text,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Không thể gửi tin nhắn: $e';
    }
  }

  // Lấy danh sách chat của user
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firebaseService.chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  // Lấy danh sách tin nhắn
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firebaseService.chatsCollection.doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      QuerySnapshot messages = await _firebaseService.chatsCollection
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      throw 'Không thể đánh dấu đã đọc: $e';
    }
  }

  // Xóa chat
  Future<void> deleteChat(String chatId) async {
    try {
      QuerySnapshot messages = await _firebaseService.chatsCollection
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      await _firebaseService.chatsCollection.doc(chatId).delete();
    } catch (e) {
      throw 'Không thể xóa chat: $e';
    }
  }

  // Lấy tổng số tin nhắn chưa đọc
  Stream<int> getTotalUnreadCount(String userId) {
    return _firebaseService.chatsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        ChatModel chat = ChatModel.fromFirestore(doc);
        total += chat.unreadCount[userId] ?? 0;
      }
      return total;
    });
  }
}
