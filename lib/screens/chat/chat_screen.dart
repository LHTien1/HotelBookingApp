import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_model.dart';
import '../../services/chat_services.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _dichVuChat = ChatService();
  final TextEditingController _boDieuKhienTinNhan = TextEditingController();
  final ScrollController _boDieuKhienCuon = ScrollController();

  @override
  void initState() {
    super.initState();
    _dichVuChat.markAsRead(widget.chatId, widget.currentUserId);
  }

  @override
  void dispose() {
    _boDieuKhienTinNhan.dispose();
    _boDieuKhienCuon.dispose();
    super.dispose();
  }

  Future<void> _guiTinNhan() async {
    final noiDung = _boDieuKhienTinNhan.text.trim();
    if (noiDung.isEmpty) return;

    _boDieuKhienTinNhan.clear();

    try {
      await _dichVuChat.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        text: noiDung,
      );

      if (_boDieuKhienCuon.hasClients) {
        _boDieuKhienCuon.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi tin nhắn không thành công: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.error,
        ),
      );
    }
  }

  // đọc time an toàn (không đổi model)
  DateTime? _msgTime(MessageModel m) {
    dynamic t;
    try {
      t = (m as dynamic).createdAt;
    } catch (_) {}
    if (t == null) {
      try {
        t = (m as dynamic).sentAt;
      } catch (_) {}
    }
    if (t == null) {
      try {
        t = (m as dynamic).timestamp;
      } catch (_) {}
    }
    if (t == null) return null;

    if (t is DateTime) return t;
    if (t is int) return DateTime.fromMillisecondsSinceEpoch(t);

    try {
      return t.toDate() as DateTime; // Firestore Timestamp
    } catch (_) {
      return null;
    }
  }

  String _hhmm(DateTime? dt) => dt == null ? '' : DateFormat('HH:mm').format(dt);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayPill(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d0 = DateTime(dt.year, dt.month, dt.day);

    if (_sameDay(d0, today)) return 'Hôm nay, ${DateFormat('HH:mm').format(dt)}';
    return DateFormat('dd/MM, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.22 : 0.35),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.secondary.withValues(alpha: 0.18),
                  child: Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : '•',
                    style: TextStyle(
                      color: cs.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      fontSize: 16.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vừa truy cập',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gọi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gọi (đang phát triển)')),
              );
            },
            icon: Icon(Icons.call, color: cs.primary),
          ),
          IconButton(
            tooltip: 'Tuỳ chọn',
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: cs.onSurface),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dichVuChat.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ds = snapshot.data ?? <MessageModel>[];
                if (ds.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có tin nhắn nào.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                // reverse:true => index 0 là mới nhất
                return ListView.builder(
                  controller: _boDieuKhienCuon,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  itemCount: ds.length,
                  itemBuilder: (context, index) {
                    final m = ds[index];
                    final laToi = m.senderId == widget.currentUserId;

                    final t = _msgTime(m);
                    final prev = (index + 1 < ds.length) ? ds[index + 1] : null;
                    final prevTime = prev == null ? null : _msgTime(prev);

                    final showDayPill = t != null &&
                        (prevTime == null || !_sameDay(t, prevTime));

                    return Column(
                      children: [
                        if (showDayPill) ...[
                          const SizedBox(height: 8),
                          _DayPill(text: _dayPill(t)),
                          const SizedBox(height: 12),
                        ],
                        _MessageRow(
                          text: m.text,
                          isMe: laToi,
                          timeText: _hhmm(t),
                          otherInitial: widget.otherUserName.isNotEmpty
                              ? widget.otherUserName[0].toUpperCase()
                              : 'H',
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          _InputBar(
            controller: _boDieuKhienTinNhan,
            onSend: _guiTinNhan,
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final String text;
  const _DayPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.70),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final String text;
  final bool isMe;
  final String timeText;
  final String otherInitial;

  const _MessageRow({
    required this.text,
    required this.isMe,
    required this.timeText,
    required this.otherInitial,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isMe ? cs.primary : cs.surface;
    final bubbleFg = isMe ? cs.onPrimary : cs.onSurface;

    final border = cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.35);

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: bubbleFg,
          fontWeight: FontWeight.w600,
          height: 1.25,
          fontSize: 15.5,
        ),
      ),
    );

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [bubble],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  timeText,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.done_all_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.45)),
              ],
            ),
          ],
        ),
      );
    }

    // incoming
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.secondary.withValues(alpha: 0.18),
            child: Text(
              otherInitial,
              style: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bubble,
              const SizedBox(height: 4),
              Text(
                timeText,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Plus button giống ảnh
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.70),
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.30)),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: cs.onSurface.withValues(alpha: 0.65)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đính kèm (đang phát triển)')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            // Input pill
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.70),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.30)),
                ),
                padding: const EdgeInsets.only(left: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 1,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Emoji',
                      onPressed: () {},
                      icon: Icon(Icons.emoji_emotions_outlined,
                          color: cs.onSurface.withValues(alpha: 0.60)),
                    ),
                    IconButton(
                      tooltip: 'Gửi',
                      onPressed: onSend,
                      icon: Icon(Icons.send_rounded, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
