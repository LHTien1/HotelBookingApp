import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, hotelOwner, admin }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;

  /// ✅ NEW: hỗ trợ nhiều role
  final List<UserRole> roles;

  final String? avatarUrl;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.roles,
    this.avatarUrl,
    required this.createdAt,
    this.isActive = true,
  });

  // =========================
  // Helpers (quyền)
  // =========================
  bool hasRole(UserRole r) => roles.contains(r);

  /// ✅ Admin là super role
  bool get isAdmin => roles.contains(UserRole.admin);

  /// ✅ Owner: hotelOwner hoặc admin
  bool get isOwner => isAdmin || roles.contains(UserRole.hotelOwner);

  /// ✅ User: user hoặc admin
  bool get isUser => isAdmin || roles.contains(UserRole.user);

  /// ✅ role "mặc định" (để tương thích code cũ đang dùng user.role)
  UserRole get primaryRole {
    if (isAdmin) return UserRole.admin;
    if (roles.contains(UserRole.hotelOwner)) return UserRole.hotelOwner;
    return UserRole.user;
  }

  /// ✅ Backward compatibility: code cũ vẫn dùng user.role
  UserRole get role => primaryRole;

  /// ✅ Các role có thể chuyển chế độ trên UI
  /// - Admin: chuyển được 3 chế độ
  /// - Owner: chuyển Owner <-> User
  /// - User: chỉ User
  List<UserRole> get switchableRoles {
    if (isAdmin) return const [UserRole.admin, UserRole.hotelOwner, UserRole.user];
    if (roles.contains(UserRole.hotelOwner)) return const [UserRole.hotelOwner, UserRole.user];
    return const [UserRole.user];
  }

  static String roleToString(UserRole r) {
    switch (r) {
      case UserRole.admin:
        return 'admin';
      case UserRole.hotelOwner:
        return 'hotelOwner';
      case UserRole.user:
        return 'user';
    }
  }

  static UserRole stringToRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'hotelOwner':
        return UserRole.hotelOwner;
      default:
        return UserRole.user;
    }
  }

  /// ✅ Chuẩn hoá role thành roles (theo rule bạn muốn)
  /// - user -> [user]
  /// - hotelOwner -> [user, hotelOwner]
  /// - admin -> [user, hotelOwner, admin]  ✅ full 3 quyền
  static List<UserRole> normalizeRolesFromSingle(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [UserRole.user, UserRole.hotelOwner, UserRole.admin];
      case UserRole.hotelOwner:
        return [UserRole.user, UserRole.hotelOwner];
      case UserRole.user:
        return [UserRole.user];
    }
  }

  /// ✅ Expand admin:
  /// Nếu roles có 'admin' (dù chỉ 1 phần tử), tự bơm thêm user + hotelOwner
  static List<UserRole> _expandAdmin(List<UserRole> input) {
    final s = input.toSet();
    if (s.contains(UserRole.admin)) {
      s.addAll([UserRole.user, UserRole.hotelOwner]);
    }
    return s.toList();
  }

  // =========================
  // Firestore
  // =========================
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // ✅ Ưu tiên roles[] (mới), fallback role (cũ)
    final rawRoles = (data['roles'] as List?)?.cast<dynamic>();
    List<UserRole> parsedRoles;

    if (rawRoles != null && rawRoles.isNotEmpty) {
      parsedRoles = rawRoles
          .map((e) => stringToRole((e ?? '').toString()))
          .toSet()
          .toList();
    } else {
      final legacyRoleStr = (data['role'] ?? 'user').toString();
      parsedRoles = normalizeRolesFromSingle(stringToRole(legacyRoleStr));
    }

    if (parsedRoles.isEmpty) {
      parsedRoles = [UserRole.user];
    }

    // ✅ đảm bảo admin luôn có đủ 3 quyền
    parsedRoles = _expandAdmin(parsedRoles);

    final createdAtTs = data['createdAt'];
    final createdAt = (createdAtTs is Timestamp) ? createdAtTs.toDate() : DateTime.now();

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      roles: parsedRoles,
      avatarUrl: data['avatarUrl'],
      createdAt: createdAt,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final roleStrings = roles.map(roleToString).toSet().toList();

    return {
      'email': email,
      'name': name,
      'phone': phone,

      // ✅ NEW
      'roles': roleStrings,

      // ✅ Legacy fallback (để code cũ / data cũ không vỡ)
      'role': roleToString(primaryRole),

      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  // CopyWith
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    List<UserRole>? roles,

    /// ✅ giữ param role để code cũ gọi copyWith(role: ...)
    UserRole? role,

    String? avatarUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    final newRoles = roles ?? (role != null ? normalizeRolesFromSingle(role) : this.roles);

    // ✅ đảm bảo admin luôn full quyền (tránh ai đó set roles: [admin])
    final safeRoles = _expandAdmin(newRoles);

    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      roles: safeRoles,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
