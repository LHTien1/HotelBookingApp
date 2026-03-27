import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_providers.dart';
import '../../providers/notification_provider.dart';
import '../../models/user_model.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool onlyUnread = false;

  String? get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid;

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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((callbackContext) {
      final uid = _uid;
      if (uid == null) return;

      final userRole = context.read<AuthProvider>().currentUser?.role;
      context.read<NotificationProvider>().startUnreadListener(
        userId: uid,
        role: _roleToString(userRole),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final uid = _uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: const Center(child: Text('Bạn cần đăng nhập để xem thông báo.')),
      );
    }

    final userRole = context.watch<AuthProvider>().currentUser?.role;
    final roleStr = _roleToString(userRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () async {
              // ✅ cache trước await
              final notif = context.read<NotificationProvider>();
              final messenger = ScaffoldMessenger.of(context);

              await notif.markAllAsRead(userId: uid, role: roleStr);

              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc')),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: _chip(
                    label: 'Tất cả',
                    selected: !onlyUnread,
                    onTap: () => setState(() => onlyUnread = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _chip(
                    label: 'Chưa đọc',
                    selected: onlyUnread,
                    onTap: () => setState(() => onlyUnread = true),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: context.read<NotificationProvider>().streamNotifications(
                userId: uid,
                role: roleStr,
                onlyUnread: onlyUnread,
              ),
              builder: (buildContext, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snapshot.data ?? const <AppNotification>[];

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      onlyUnread
                          ? 'Không có thông báo chưa đọc.'
                          : 'Chưa có thông báo nào.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final n = list[index];

                    return NotificationTile(
                      n: n,
                      onTap: () async {
                        // ✅ cache trước await
                        final notif = context.read<NotificationProvider>();
                        final navigator = Navigator.of(context);

                        final route = n.actionRoute;
                        final args = n.actionArgs;

                        if (!n.isRead) {
                          await notif.markAsRead(n.id);
                        }

                        if (!mounted) return;

                        if (route != null && route.trim().isNotEmpty) {
                          navigator.pushNamed(route, arguments: args);
                        }
                      },
                      onDelete: () async {
                        // ✅ không dùng context sau await -> ok
                        await context
                            .read<NotificationProvider>()
                            .deleteNotification(n.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = selected ? cs.primary.withValues(alpha: 0.18) : cs.surface;
    final border = cs.outlineVariant.withValues(alpha: isDark ? 0.30 : 0.55);
    final textColor =
    selected ? cs.primary : cs.onSurface.withValues(alpha: 0.75);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
