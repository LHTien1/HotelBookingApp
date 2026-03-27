import 'package:booking_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get hotelsCollection =>
      _firestore.collection('hotels');
  CollectionReference<Map<String, dynamic>> get roomsCollection =>
      _firestore.collection('rooms');
  CollectionReference<Map<String, dynamic>> get bookingsCollection =>
      _firestore.collection('bookings');
  CollectionReference<Map<String, dynamic>> get reviewsCollection =>
      _firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get chatsCollection =>
      _firestore.collection('chats');
  CollectionReference<Map<String, dynamic>> get reportsCollection =>
      _firestore.collection('reports');

  // ✅ NEW
  CollectionReference<Map<String, dynamic>> get roleRequestsCollection =>
      _firestore.collection('role_requests');
  CollectionReference<Map<String, dynamic>> get notificationsCollection =>
      _firestore.collection('notifications');

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ FIX: Không dùng enablePersistence() (nhiều version cloud_firestore không có)
    // Bật cache offline bằng settings (set trước khi dùng Firestore lần đầu)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      // cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // tuỳ chọn
    );
  }

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ✅ Lấy user doc ổn định:
  /// - Ưu tiên server
  /// - Nếu permission-denied ngay sau login -> refresh token rồi thử lại
  /// - Nếu vẫn fail -> fallback cache
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocSafe(String uid) async {
    try {
      return await usersCollection.doc(uid).get(
        const GetOptions(source: Source.server),
      );
    } on FirebaseException catch (e) {
      // permission-denied: token/rules chưa sync kịp ngay sau login
      if (e.code == 'permission-denied') {
        final u = currentUser;
        if (u != null) {
          await u.getIdToken(true);
        }

        // thử lại server
        try {
          return await usersCollection.doc(uid).get(
            const GetOptions(source: Source.server),
          );
        } catch (_) {
          // fallback cache
          return await usersCollection.doc(uid).get(
            const GetOptions(source: Source.cache),
          );
        }
      }

      // lỗi khác -> fallback cache
      return await usersCollection.doc(uid).get(
        const GetOptions(source: Source.cache),
      );
    }
  }
}
