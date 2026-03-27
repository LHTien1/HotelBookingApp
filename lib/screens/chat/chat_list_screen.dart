import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_providers.dart';
import '../../providers/chat_providers.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<ChatProvider>().loadChats(uid);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayVi(DateTime d) {
    if (d.weekday == DateTime.sunday) return 'CN';
    return 'Thứ ${d.weekday + 1}'; // Mon=1 -> Thứ 2
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d0 = DateTime(dt.year, dt.month, dt.day);

    if (_isSameDay(d0, today)) return DateFormat('HH:mm').format(dt);
    if (_isSameDay(d0, yesterday)) return 'Hôm qua';
    if (diff.inDays < 7) return _weekdayVi(dt);

    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: Text(
              'Bạn cần đăng nhập để xem tin nhắn.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            final q = _searchCtrl.text.trim().toLowerCase();

            final listAll = chatProvider.chats;
            final list = q.isEmpty
                ? listAll
                : listAll.where((c) {
              final otherName = c.participantNames.entries
                  .where((e) => e.key != uid)
                  .map((e) => (e.value).toString())
                  .join(' ')
                  .toLowerCase();

              final lastMsg = (c.lastMessage).toString().toLowerCase();
              return otherName.contains(q) || lastMsg.contains(q);
            }).toList();

            return Column(
              children: [
                // ===== Header giống ảnh =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tin nhắn',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // UI-only: chưa có màn tạo chat => giữ chức năng hiện tại
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tạo cuộc trò chuyện (đang phát triển)'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit_rounded, color: cs.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Search =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.35 : 0.70),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                        hintText: 'Tìm kiếm cuộc trò chuyện',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                        suffixIcon: _searchCtrl.text.trim().isEmpty
                            ? null
                            : IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),

                // ===== List =====
                Expanded(
                  child: chatProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (list.isEmpty)
                      ? Center(
                    child: Text(
                      'Chưa có cuộc trò chuyện nào.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.22),
                    ),
                    itemBuilder: (context, index) {
                      final c = list[index];

                      final otherId = c.participants.firstWhere(
                            (id) => id != uid,
                        orElse: () => '',
                      );

                      final otherNameRaw =
                      (c.participantNames[otherId] ?? 'Người dùng')
                          .toString()
                          .trim();

                      final otherName =
                      otherNameRaw.isEmpty ? 'Người dùng' : otherNameRaw;

                      final lastMsg = c.lastMessage.toString().trim().isEmpty
                          ? 'Chưa có tin nhắn'
                          : c.lastMessage.toString();

                      final timeText = _timeLabel(c.lastMessageTime);

                      final unread = (c.unreadCount[uid] ?? 0);
                      final timeColor = unread > 0
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.55);

                      // UI-only: chấm xanh online “giả lập” theo thời gian nhắn gần đây
                      final isOnline = DateTime.now()
                          .difference(c.lastMessageTime)
                          .inMinutes <
                          8;

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: {
                              'chatId': c.chatId,
                              'currentUserId': uid,
                              'otherUserName': otherName,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Avatar + dot
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                    cs.secondary.withValues(alpha: 0.18),
                                    child: Text(
                                      otherName.isNotEmpty
                                          ? otherName[0].toUpperCase()
                                          : '•',
                                      style: TextStyle(
                                        color: cs.secondary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: cs.surface,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Name + last message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      otherName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: unread > 0
                                            ? FontWeight.w900
                                            : FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMsg,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.70),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Time + unread badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    timeText,
                                    style: TextStyle(
                                      color: timeColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (unread > 0)
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style: TextStyle(
                                          color: cs.onPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer giống ảnh
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tin nhắn được mã hóa đầu cuối',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
