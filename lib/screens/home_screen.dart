import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_providers.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

import 'room_details_screen.dart';
import 'notifications/notifications_screen.dart';
import 'hotel_owner/select_hotel_screen.dart';

import 'chatbot_screen.dart';

/// ✅ Bộ icon đẹp (Material Rounded)
class AppIcons {
  // AppBar
  static const notify = Icons.notifications_none_rounded;
  static const themeDark = Icons.dark_mode_rounded;
  static const themeLight = Icons.light_mode_rounded;
  static const logout = Icons.logout_rounded;

  // Switch role
  static const switchRole = Icons.swap_horiz_rounded;

  // User
  static const stay = Icons.hotel_rounded;
  static const search = Icons.travel_explore_rounded;

  // Search card fields
  static const where = Icons.location_on_outlined;
  static const calendar = Icons.calendar_month_rounded;
  static const people = Icons.people_alt_outlined;

  // Bottom nav
  static const home = Icons.home_rounded;
  static const profile = Icons.account_circle_rounded;
  static const bookings = Icons.event_available_rounded;

  // Owner nav
  static const dashboard = Icons.space_dashboard_rounded;
  static const rooms = Icons.meeting_room_rounded;
  static const chat = Icons.forum_rounded;

  // Admin tiles
  static const approve = Icons.fact_check_rounded;
  static const manage = Icons.domain_rounded;
  static const reports = Icons.report_problem_rounded;
  static const monitorBookings = Icons.event_note_rounded;

  // Owner tiles
  static const postRoom = Icons.add_home_work_rounded;
  static const stats = Icons.query_stats_rounded;
  static const reviews = Icons.rate_review_rounded;

  // UI
  static const chevron = Icons.chevron_right_rounded;
  static const imageFallback = Icons.broken_image_outlined;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _chiMucDuoi = 0;

  String? _lastUid;
  UserRole? _lastActiveRole;

  final _vnd = NumberFormat.decimalPattern('vi_VN');

  String? _roleToString(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.hotelOwner:
        return 'hotelOwner';
      case UserRole.user:
        return 'user';
      default:
        return null;
    }
  }

  String _labelRole(UserRole r) {
    switch (r) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.hotelOwner:
        return 'Chủ khách sạn';
      case UserRole.user:
        return 'Khách hàng';
    }
  }

  // ✅ mở màn chọn khách sạn trước khi đi route cần hotelId
  void _moChonKhachSan({
    required String targetRoute,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectHotelScreen(
          targetRoute: targetRoute,
          title: title,
        ),
      ),
    );
  }

  void _syncSideEffects(UserModel user, UserRole activeRole) {
    if (_lastUid == user.uid && _lastActiveRole == activeRole) return;

    _lastUid = user.uid;
    _lastActiveRole = activeRole;

    // ✅ listener badge thông báo theo activeRole
    context.read<NotificationProvider>().startUnreadListener(
      userId: user.uid,
      role: _roleToString(activeRole),
    );

    // ✅ load rooms cho chế độ user
    if (activeRole == UserRole.user) {
      context.read<HotelProvider>().fetchAllRooms();
    }
  }

  void _doiCheDo(UserModel user, UserRole newRole) {
    setState(() => _chiMucDuoi = 0);
    context.read<ThemeProvider>().setCurrentRole(newRole);
    _syncSideEffects(user, newRole);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final themeProvider = context.read<ThemeProvider>();

    // ✅ nếu currentRole null hoặc không nằm trong switchableRoles -> set về primaryRole
    final cur = themeProvider.currentRole;
    final allowed = (cur != null) && user.switchableRoles.contains(cur);
    if (!allowed) {
      themeProvider.setCurrentRole(user.primaryRole);
    }

    final activeRole = themeProvider.currentRole ?? user.primaryRole;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSideEffects(user, activeRole);
    });
  }

  void _chonTab(UserRole role, int index) {
    if (index == _chiMucDuoi) return;
    setState(() => _chiMucDuoi = index);

    if (role == UserRole.user) {
      switch (index) {
        case 0:
          return;
        case 1:
          Navigator.pushNamed(context, '/search');
          return;
        case 2:
          Navigator.pushNamed(context, '/my-bookings');
          return;
        case 3:
          Navigator.pushNamed(context, '/profile');
          return;
      }
    }

    if (role == UserRole.hotelOwner) {
      switch (index) {
        case 0:
          return;
        case 1:
          _moChonKhachSan(
            targetRoute: '/manage-rooms',
            title: 'Chọn khách sạn để quản lý phòng',
          );
          return;
        case 2:
          Navigator.pushNamed(context, '/chat-list');
          return;
        case 3:
          Navigator.pushNamed(context, '/profile');
          return;
      }
    }

    // Admin
    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.pushNamed(context, '/approve-rooms');
        return;
      case 2:
        Navigator.pushNamed(context, '/reports');
        return;
      case 3:
        Navigator.pushNamed(context, '/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeProvider = context.watch<ThemeProvider>();
    final activeRole = themeProvider.currentRole ?? user.primaryRole;
    final dangToi = themeProvider.isDark(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surface,
        title: _tieuDeAppBar(user, activeRole),
        actions: [
          if (user.switchableRoles.length > 1)
            PopupMenuButton<UserRole>(
              tooltip: 'Đổi chế độ',
              initialValue: activeRole,
              onSelected: (r) => _doiCheDo(user, r),
              itemBuilder: (context) => user.switchableRoles
                  .map(
                    (r) => PopupMenuItem<UserRole>(
                  value: r,
                  child: Text(_labelRole(r)),
                ),
              )
                  .toList(),
              icon: Icon(AppIcons.switchRole, color: cs.onSurface),
            ),
          _nutThongBao(user, activeRole),
          _circleIcon(
            icon: dangToi ? AppIcons.themeLight : AppIcons.themeDark,
            tooltip: dangToi ? 'Chuyển sang sáng' : 'Chuyển sang tối',
            onTap: () => context.read<ThemeProvider>().toggle(context),
          ),
          _circleIcon(
            icon: AppIcons.logout,
            tooltip: 'Đăng xuất',
            bg: cs.error.withValues(alpha: 0.12),
            fg: cs.error,
            onTap: () => _hopThoaiDangXuat(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _noiDungTheoVaiTro(context, activeRole, user),
      bottomNavigationBar: _thanhDieuHuongDuoi(activeRole),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        child: const Icon(Icons.smart_toy_rounded), // ✅ nhìn phát biết chatbot
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
      ),
    );
  }

  // =========================
  // AppBar title (giống mockup) ✅ FIX: Admin -> "Quản trị viên"
  // =========================
  Widget _tieuDeAppBar(UserModel user, UserRole activeRole) {
    final cs = Theme.of(context).colorScheme;
    final ten = user.name.trim();

    final subtitle = (activeRole == UserRole.user) ? 'Chào buổi sáng' : 'Welcome back';

    // ✅ FIX: nếu đang ở Admin thì không hiện tên user nữa
    final displayName = (activeRole == UserRole.admin)
        ? 'Quản trị viên'
        : (ten.isNotEmpty ? ten : 'Người dùng');

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/profile'),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(AppIcons.profile, color: cs.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.62),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (activeRole == UserRole.user) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleIcon({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? bg,
    Color? fg,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (bg ?? cs.surfaceContainerHighest.withValues(alpha: 0.55)),
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Icon(icon, color: fg ?? cs.onSurface, size: 20),
        ),
      ),
    );
  }

  // 🔔 Chuông + badge (role theo activeRole)
  Widget _nutThongBao(UserModel user, UserRole activeRole) {
    final cs = Theme.of(context).colorScheme;
    final roleStr = _roleToString(activeRole);

    return StreamBuilder<List<AppNotification>>(
      stream: context.read<NotificationProvider>().streamNotifications(
        userId: user.uid,
        role: roleStr,
        onlyUnread: true,
      ),
      builder: (context, snapshot) {
        final unread = snapshot.data?.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _circleIcon(
              icon: AppIcons.notify,
              tooltip: 'Thông báo',
              onTap: () => Navigator.pushNamed(context, NotificationsScreen.routeName),
            ),
            if (unread > 0)
              Positioned(
                right: 4,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    unread > 99 ? '99+' : unread.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onError,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // =========================
  // Body theo vai trò (activeRole)
  // =========================
  Widget _noiDungTheoVaiTro(BuildContext context, UserRole role, UserModel user) {
    switch (role) {
      case UserRole.admin:
        return _bangDieuKhienAdmin(context, user: user);
      case UserRole.hotelOwner:
        return _bangDieuKhienChuKS(context, user: user);
      case UserRole.user:
        return _bangTrangChuNguoiDung(context);
    }
  }

  // =========================
  // ✅ USER HOME (match mockup)
  // =========================
  Widget _bangTrangChuNguoiDung(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tìm kiếm khách sạn',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _searchCardUserMock(),
          const SizedBox(height: 12),
          _recentHeader(),
          _recentChipsRow(),
          const SizedBox(height: 14),
          _promoBannerMock(),
          const SizedBox(height: 10),
          _sectionHeader(
            title: 'Gợi ý nổi bật',
            actionText: 'Xem tất cả',
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          _featuredGridRooms(),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ✅ Card search 3 dòng + nút (giống mockup)
  Widget _searchCardUserMock() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget rowItem({
      required IconData icon,
      required String title,
      required String value,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface.withValues(alpha: 0.40),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget divider() => Divider(
      height: 1,
      thickness: 1,
      color: cs.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.65),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.65),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        children: [
          rowItem(
            icon: AppIcons.where,
            title: 'Điểm đến',
            value: 'Bạn muốn đi đâu?',
          ),
          divider(),
          rowItem(
            icon: AppIcons.calendar,
            title: 'Ngày',
            value: 'T2, 12 Th8 - T5, 15 Th8',
          ),
          divider(),
          rowItem(
            icon: AppIcons.people,
            title: 'Khách & phòng',
            value: '02 Khách, 01 Phòng',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(Icons.search_rounded),
              label: const Text(
                'Tìm kiếm',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentHeader() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tìm kiếm gần đây',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                'Xóa',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ chip giống mockup (icon history)
  Widget _recentChipsRow() {
    final cs = Theme.of(context).colorScheme;

    const chips = [
      'Đà Lạt',
      'Vũng Tàu',
      'Hồ Chí Minh',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.pushNamed(context, '/search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chips[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _promoBannerMock() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const imgUrl =
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1200&q=70';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imgUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ƯU ĐÃI HOT',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Mùa Thu Vàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giảm ngay 50% cho các điểm đến vùng núi phía Bắc.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          if (actionText != null)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // Featured grid giống mockup (2 cột)
  // =========================
  Widget _featuredGridRooms() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          final rooms = hotelProvider.rooms;
          if (hotelProvider.isLoading && rooms.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (rooms.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Chưa có gợi ý nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
              ),
            );
          }

          final show = rooms.take(4).toList();

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: show.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (_, i) => _roomFeatureCard(show[i]),
          );
        },
      ),
    );
  }

  String _tryPriceText(RoomModel room) {
    try {
      final dynamic any = room;
      final p = any.pricePerNight ?? any.price ?? any.pricePerDay ?? any.pricePerRoom;
      if (p == null) return '';
      if (p is num) return '${_vnd.format(p)}đ/đêm';
      return p.toString();
    } catch (_) {
      return '';
    }
  }

  String _tryLocationText(RoomModel room) {
    try {
      final dynamic any = room;
      final city = any.city ?? any.location ?? any.address;
      if (city == null) return 'Mã KS: ${room.hotelId}';
      return city.toString();
    } catch (_) {
      return 'Mã KS: ${room.hotelId}';
    }
  }

  Widget _roomFeatureCard(RoomModel room) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final anh = room.images.isNotEmpty ? room.images.first.trim() : '';
    final coAnh = anh.isNotEmpty;

    final price = _tryPriceText(room);
    final location = _tryLocationText(room);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).pushNamed(
        RoomDetailsScreen.routeName,
        arguments: room,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coAnh
                        ? Image.network(
                      anh,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _anhLoi(),
                    )
                        : _anhLoi(),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF2C94C)),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            price.isNotEmpty ? price : 'Xem chi tiết',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(AppIcons.chevron, color: cs.primary, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _anhLoi() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Icon(AppIcons.imageFallback, color: cs.onSurfaceVariant),
    );
  }

  // =========================
  // OWNER DASH
  // =========================
  Widget _bangDieuKhienChuKS(BuildContext context, {required UserModel user}) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        _segmentedOwnerGuest(user),
        const SizedBox(height: 12),
        _blueWelcomeBanner(
          title: 'Chào mừng trở lại!',
          subtitle: 'Hôm nay là một ngày tuyệt vời để\nquản lý khách sạn của bạn.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statMiniMock(
                icon: Icons.home_work_rounded,
                label: 'Đặt phòng mới',
                value: '12',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statMiniMock(
                icon: Icons.payments_rounded,
                label: 'Doanh thu',
                value: '5.2tr',
                suffix: 'VND',
                tint: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Quản lý',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _tileMock(
              title: 'Đăng phòng',
              subtitle: 'Thêm phòng trống mới',
              imageUrl:
              'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.postRoom,
              onTap: () => _moChonKhachSan(
                targetRoute: '/post-room',
                title: 'Chọn khách sạn để đăng phòng',
              ),
            ),
            _tileMock(
              title: 'Quản lý phòng',
              subtitle: 'Chỉnh sửa & cập nhật',
              imageUrl:
              'https://images.unsplash.com/photo-1560067174-8943bd8f8d23?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.manage,
              onTap: () => _moChonKhachSan(
                targetRoute: '/manage-rooms',
                title: 'Chọn khách sạn để quản lý phòng',
              ),
            ),
            _tileMock(
              title: 'Thống kê',
              subtitle: 'Báo cáo chi tiết',
              imageUrl:
              'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.stats,
              onTap: () => Navigator.of(context).pushNamed('/revenue-stats'),
            ),
            _tileMock(
              title: 'Đánh giá',
              subtitle: 'Xem phản hồi khách',
              imageUrl:
              'https://images.unsplash.com/photo-1522071901873-411886a10004?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.reviews,
              onTap: () => Navigator.of(context).pushNamed('/reviews'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _segmentedOwnerGuest(UserModel user) {
    final themeProvider = context.watch<ThemeProvider>();
    final activeRole = themeProvider.currentRole ?? user.primaryRole;

    final hasOwner = user.switchableRoles.contains(UserRole.hotelOwner);
    final hasUser = user.switchableRoles.contains(UserRole.user);
    if (!hasOwner || !hasUser) return const SizedBox.shrink();

    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment<UserRole>(value: UserRole.hotelOwner, label: Text('Chủ nhà')),
        ButtonSegment<UserRole>(value: UserRole.user, label: Text('Khách')),
      ],
      selected: {activeRole == UserRole.user ? UserRole.user : UserRole.hotelOwner},
      onSelectionChanged: (set) => _doiCheDo(user, set.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
      ),
    );
  }

  Widget _blueWelcomeBanner({required String title, required String subtitle}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.grid_view_rounded, color: cs.onPrimary, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _statMiniMock({
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
    Color? tint,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (tint ?? cs.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint ?? cs.primary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // ADMIN DASH
  // =========================
  Widget _bangDieuKhienAdmin(BuildContext context, {required UserModel user}) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: _miniSquareStat(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Chờ duyệt',
                value: '12',
                tint: const Color(0xFFF2994A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _bigPrimaryStat(
                label: 'Đặt phòng',
                value: '85',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniSquareStat(
                icon: Icons.trending_up_rounded,
                label: 'Tăng',
                value: '+5.2%',
                tint: const Color(0xFF27AE60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Chức năng quản lý',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _tileMock(
              title: 'Duyệt phòng',
              subtitle: 'Phê duyệt nhanh',
              imageUrl:
              'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.approve,
              onTap: () => Navigator.of(context).pushNamed('/approve-rooms'),
            ),
            _tileMock(
              title: 'Quản lý phòng',
              subtitle: 'Cập nhật trạng thái',
              badge: 'NEW',
              imageUrl:
              'https://images.unsplash.com/photo-1560067174-8943bd8f8d23?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.manage,
              onTap: () => _moChonKhachSan(
                targetRoute: '/manage-rooms',
                title: 'Chọn khách sạn để quản lý phòng',
              ),
            ),
            _tileMock(
              title: 'Báo cáo',
              subtitle: 'Thống kê chi tiết',
              imageUrl:
              'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.reports,
              onTap: () => Navigator.of(context).pushNamed('/reports'),
            ),
            _tileMock(
              title: 'Theo dõi',
              subtitle: 'Lịch trình hiện tại',
              imageUrl:
              'https://images.unsplash.com/photo-1522071901873-411886a10004?auto=format&fit=crop&w=900&q=70',
              icon: AppIcons.monitorBookings,
              onTap: () => Navigator.of(context).pushNamed('/monitor-bookings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniSquareStat({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigPrimaryStat({required String label, required String value}) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_available_rounded, color: cs.onPrimary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: cs.onPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileMock({
    required String title,
    required String subtitle,
    required String imageUrl,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _anhLoi(),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: cs.primary, size: 18),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Bottom Navigation
  // =========================
  Widget _thanhDieuHuongDuoi(UserRole role) {
    final cs = Theme.of(context).colorScheme;

    BottomNavigationBar bar(List<BottomNavigationBarItem> items) {
      return BottomNavigationBar(
        currentIndex: _chiMucDuoi,
        onTap: (i) => _chonTab(role, i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.55),
        showUnselectedLabels: true,
        items: items,
      );
    }

    if (role == UserRole.user) {
      return bar(const [
        BottomNavigationBarItem(icon: Icon(AppIcons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(AppIcons.search), label: 'Tìm kiếm'),
        BottomNavigationBarItem(icon: Icon(AppIcons.bookings), label: 'Đặt phòng'),
        BottomNavigationBarItem(icon: Icon(AppIcons.profile), label: 'Tài khoản'),
      ]);
    }

    if (role == UserRole.hotelOwner) {
      return bar(const [
        BottomNavigationBarItem(icon: Icon(AppIcons.dashboard), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(AppIcons.rooms), label: 'Phòng'),
        BottomNavigationBarItem(icon: Icon(AppIcons.chat), label: 'Tin nhắn'),
        BottomNavigationBarItem(icon: Icon(AppIcons.profile), label: 'Hồ sơ'),
      ]);
    }

    return bar(const [
      BottomNavigationBarItem(icon: Icon(AppIcons.dashboard), label: 'Trang chủ'),
      BottomNavigationBarItem(icon: Icon(AppIcons.approve), label: 'Duyệt'),
      BottomNavigationBarItem(icon: Icon(AppIcons.reports), label: 'Báo cáo'),
      BottomNavigationBarItem(icon: Icon(AppIcons.profile), label: 'Hồ sơ'),
    ]);
  }

  // =========================
  // Logout Dialog
  // =========================
  void _hopThoaiDangXuat(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthProvider>().signOut(context);
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text('Đăng xuất', style: TextStyle(color: cs.onError)),
          ),
        ],
      ),
    );
  }
}
