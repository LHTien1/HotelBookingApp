import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ NEW: settings screen
import 'package:booking_app/screens/settings/general_settings_screen.dart'
    show GeneralSettingsScreen;

// ✅ FIX: dùng đúng routeName của NotificationsScreen
import 'package:booking_app/screens/notifications/notifications_screen.dart'
    show NotificationsScreen;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  void _xacNhanDangXuat(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),

            // ✅ FIX: không async/await => không còn lint “BuildContext across async gaps”
            onPressed: () {
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              auth.signOut(context); // giữ API cũ của bạn
            },

            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
        body: Center(
          child: Text(
            'Không tìm thấy thông tin người dùng.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    final name = (user.name).toString().trim();
    final email = (user.email).toString().trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: cs.surface,
                    child: Icon(Icons.person, size: 54, color: cs.onSurfaceVariant),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 3),
                    ),
                    child: Icon(Icons.photo_camera, color: cs.onPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              name.isNotEmpty ? name : 'Người dùng',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              email.isNotEmpty ? email : 'Chưa có email',
              style: TextStyle(
                fontSize: 15.5,
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.edit_outlined,
                  title: 'Chỉnh sửa hồ sơ',
                  onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                ),

                const Divider(height: 18),

                // ✅ NEW: Cài đặt chung
                _MenuTile(
                  icon: Icons.settings_rounded,
                  title: 'Cài đặt chung',
                  onTap: () => Navigator.of(context).pushNamed(
                    GeneralSettingsScreen.routeName,
                  ),
                ),

                const Divider(height: 18),

                _MenuTile(
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Sắp có',
                  onTap: () {},
                ),

                const Divider(height: 18),

                _MenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  // ✅ FIX: dùng đúng routeName
                  onTap: () => Navigator.of(context).pushNamed(
                    NotificationsScreen.routeName,
                  ),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          AppCard(
            child: _MenuTile(
              icon: Icons.receipt_long_outlined,
              title: 'Lịch sử đặt phòng',
              onTap: () => Navigator.of(context).pushNamed('/my-bookings'),
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _xacNhanDangXuat(context),
              icon: Icon(Icons.logout, color: cs.error),
              label: Text(
                'Đăng xuất',
                style: TextStyle(color: cs.error, fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 18),
          Center(
            child: Text(
              'Phiên bản 2.4.0',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: cs.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: cs.onSurface,
        ),
      ),
      subtitle: (subtitle ?? '').trim().isEmpty
          ? null
          : Text(
        subtitle!,
        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
      onTap: onTap,
    );
  }
}
