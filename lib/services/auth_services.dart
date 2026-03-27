import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'firebase_services.dart';

class AuthService {
  final FirebaseService _firebase = FirebaseService();

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDocWithRetry(String uid) async {
    try {
      return await _firebase.usersCollection
          .doc(uid)
          .get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      // ✅ trường hợp token chưa kịp sync sang Firestore
      if (e.code == 'permission-denied') {
        final u = _firebase.currentUser;
        if (u != null) {
          await u.getIdToken(true);
        }
        await Future.delayed(const Duration(milliseconds: 350));
        return await _firebase.usersCollection
            .doc(uid)
            .get(const GetOptions(source: Source.server));
      }
      rethrow;
    }
  }

  Future<void> _ensureUserDocExists(User user, {String? fallbackName}) async {
    final uid = user.uid;
    final doc = await _getUserDocWithRetry(uid);

    if (doc.exists) return;

    // ✅ auto-heal: nếu Auth có user nhưng Firestore chưa có doc users/{uid}
    final email = (user.email ?? '').trim().toLowerCase();
    final name = (user.displayName ?? fallbackName ?? 'Người dùng').trim();

    final u = UserModel(
      uid: uid,
      email: email,
      name: name.isEmpty ? 'Người dùng' : name,
      phone: null,
      roles: const [UserRole.user],
      createdAt: DateTime.now(),
      isActive: true,
    );

    await _firebase.usersCollection.doc(uid).set(u.toMap());
  }

  // =========================
  // ✅ API thuần Việt
  // =========================

  /// Đăng ký:
  /// - Luôn tạo users/{uid} với roles=['user']
  /// - Nếu user chọn hotelOwner => tạo role_requests/{uid} để admin duyệt
  Future<UserModel> dangKy({
    required String email,
    required String matKhau,
    required String hoTen,
    required UserRole vaiTro,
    String? soDienThoai,
  }) async {
    try {
      final emailSach = email.trim().toLowerCase();
      final matKhauSach = matKhau.trim();
      final hoTenSach = hoTen.trim();

      final userCredential = await _firebase.auth.createUserWithEmailAndPassword(
        email: emailSach,
        password: matKhauSach,
      );

      final fbUser = userCredential.user!;
      final uid = fbUser.uid;

      await fbUser.updateDisplayName(hoTenSach);

      final nguoiDungMoi = UserModel(
        uid: uid,
        email: emailSach,
        name: hoTenSach,
        phone: soDienThoai?.trim(),
        roles: const [UserRole.user],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firebase.usersCollection.doc(uid).set(nguoiDungMoi.toMap());

      if (vaiTro == UserRole.hotelOwner) {
        await _firebase.roleRequestsCollection.doc(uid).set({
          'type': 'hotelOwner',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'userId': uid,
          'email': emailSach,
          'name': hoTenSach,
          'phone': soDienThoai?.trim(),
        });
      }

      return nguoiDungMoi;
    } on FirebaseAuthException catch (e) {
      throw _xuLyLoiXacThuc(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  /// Đăng nhập
  Future<UserModel?> dangNhap({
    required String email,
    required String matKhau,
  }) async {
    try {
      final emailSach = email.trim().toLowerCase();
      final matKhauSach = matKhau.trim();

      final userCredential = await _firebase.auth.signInWithEmailAndPassword(
        email: emailSach,
        password: matKhauSach,
      );

      final u = userCredential.user;
      if (u == null) return null;

      // ✅ refresh token trước khi đọc Firestore
      await u.getIdToken(true);

      // ✅ auto-heal nếu users doc bị thiếu
      await _ensureUserDocExists(u, fallbackName: u.displayName);

      final doc = await _getUserDocWithRetry(u.uid);
      if (!doc.exists) return null;

      final user = UserModel.fromFirestore(doc);

      if (!user.isActive) {
        await _firebase.auth.signOut();
        throw 'Tài khoản đã bị vô hiệu hóa.';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _xuLyLoiXacThuc(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  Future<void> dangXuat() async {
    await _firebase.auth.signOut();
  }

  Future<UserModel?> layNguoiDungHienTai() async {
    final uid = _firebase.currentUserId;
    if (uid == null) return null;

    final doc = await _firebase.usersCollection
        .doc(uid)
        .get(const GetOptions(source: Source.server));

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> theoDoiNguoiDungHienTai() {
    final uid = _firebase.currentUserId;
    if (uid == null) return Stream.value(null);

    return _firebase.usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> guiEmailDatLaiMatKhau(String email) async {
    await _firebase.auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> capNhatHoSoNguoiDung({
    required String uid,
    String? hoTen,
    String? soDienThoai,
    String? duongDanAnhDaiDien,
  }) async {
    final updates = <String, dynamic>{};

    if (hoTen != null) updates['name'] = hoTen.trim();
    if (soDienThoai != null) updates['phone'] = soDienThoai.trim();
    if (duongDanAnhDaiDien != null) updates['avatarUrl'] = duongDanAnhDaiDien.trim();

    if (updates.isEmpty) return;

    await _firebase.usersCollection.doc(uid).update(updates);

    final u = _firebase.currentUser;
    if (u != null && u.uid == uid) {
      if (hoTen != null) await u.updateDisplayName(hoTen.trim());
      if (duongDanAnhDaiDien != null) await u.updatePhotoURL(duongDanAnhDaiDien.trim());
    }
  }

  Future<void> capNhatRoles({
    required String uid,
    required List<UserRole> roles,
  }) async {
    final roleStrings = roles.map(UserModel.roleToString).toSet().toList();

    final primaryRole = roles.contains(UserRole.admin)
        ? UserRole.admin
        : (roles.contains(UserRole.hotelOwner) ? UserRole.hotelOwner : UserRole.user);

    await _firebase.usersCollection.doc(uid).update({
      'roles': roleStrings,
      'role': UserModel.roleToString(primaryRole),
    });
  }

  Future<void> doiMatKhau({
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    final user = _firebase.currentUser;
    if (user == null) throw 'Người dùng chưa đăng nhập.';

    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw 'Tài khoản không có email để xác thực.';
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim().toLowerCase(),
      password: matKhauHienTai.trim(),
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(matKhauMoi.trim());
  }

  String _xuLyLoiXacThuc(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return 'Lỗi xác thực: [${e.code}] ${e.message ?? ''}'.trim();
    }
  }

  // alias tên cũ
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  }) =>
      dangKy(email: email, matKhau: password, hoTen: name, vaiTro: role, soDienThoai: phone);

  Future<UserModel?> signIn({required String email, required String password}) =>
      dangNhap(email: email, matKhau: password);

  Future<void> signOut() => dangXuat();
  Future<UserModel?> getCurrentUserData() => layNguoiDungHienTai();
  Stream<UserModel?> streamCurrentUserData() => theoDoiNguoiDungHienTai();
  Future<void> resetPassword(String email) => guiEmailDatLaiMatKhau(email);

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
  }) =>
      capNhatHoSoNguoiDung(uid: uid, hoTen: name, soDienThoai: phone, duongDanAnhDaiDien: avatarUrl);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      doiMatKhau(matKhauHienTai: currentPassword, matKhauMoi: newPassword);
}
