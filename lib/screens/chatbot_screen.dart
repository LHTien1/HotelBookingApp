import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room_model.dart';
import '../providers/hotel_providers.dart';
import '../services/groq_service.dart';
import '../chat/room_context_builder.dart';
import 'room_details_screen.dart';

/// =======================
/// MODEL MESSAGE
/// =======================
class ChatMessage {
  final bool isUser;
  final String text;
  final String? roomId;
  final DateTime createdAt;

  ChatMessage({
    required this.isUser,
    required this.text,
    this.roomId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// =======================
/// CHATBOT SCREEN (UPGRADED UI)
/// =======================
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = <ChatMessage>[];
  final Set<String> _excludedRoomIds = <String>{}; // ✅ phòng đã gợi ý

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // ✅ Greeting + Load rooms thật cho chatbot
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1) Load rooms (dữ liệu thật) trước
      await _ensureRoomsLoaded(showBotMessageIfEmpty: false);

      // 2) Greeting
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: 'Xin chào! 👋 Tôi có thể giúp gì cho việc đặt phòng của bạn hôm nay?',
          ),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _ensureRoomsLoaded({bool showBotMessageIfEmpty = true}) async {
    final hp = context.read<HotelProvider>();

    // đã có rooms thì khỏi load lại
    if (hp.rooms.isNotEmpty) return;

    try {
      await hp.fetchAvailableRoomsForChat(); // ✅ rooms thật: status=available & isActive=true
    } catch (_) {
      // provider đã set errorMessage
    }

    if (!mounted) return;

    // Nếu vẫn rỗng và muốn báo cho user
    if (showBotMessageIfEmpty && hp.rooms.isEmpty) {
      final err = hp.errorMessage;
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: err == null || err.isEmpty
                ? 'Hiện chưa có phòng khả dụng để gợi ý.'
                : 'Không tải được dữ liệu phòng: $err',
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  // =======================
  // SEND MESSAGE
  // =======================
  Future<void> sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
      _loading = true;
    });

    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();

    try {
      // ✅ đảm bảo rooms đã được nạp
      final hp = context.read<HotelProvider>(); // ✅ lấy trước
      await hp.fetchAvailableRoomsForChat();
// giờ chỉ dùng hp, không cần context
      final rooms = hp.rooms;

      // ✅ chặn khi chưa có dữ liệu thật
      if (hp.isLoading && rooms.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            text: 'Mình đang tải danh sách phòng từ hệ thống… bạn chờ 1 chút nhé.',
          ));
        });
        _scrollToBottom();
        return;
      }

      if (hp.errorMessage != null && rooms.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            text: 'Không tải được dữ liệu phòng: ${hp.errorMessage}',
          ));
        });
        _scrollToBottom();
        return;
      }

      if (rooms.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            text: 'Hiện chưa có phòng khả dụng để gợi ý.',
          ));
        });
        _scrollToBottom();
        return;
      }

      // 2️⃣ BUILD CONTEXT PHÒNG (DỮ LIỆU THẬT)
      final roomsContext = buildRoomsContext(rooms);

      // 3️⃣ LOẠI TRỪ PHÒNG ĐÃ GỢI Ý
      final excludedText =
      _excludedRoomIds.isEmpty ? 'Không có' : _excludedRoomIds.join(', ');

      // 4️⃣ PROMPT
      final prompt = '''
Bạn là trợ lý AI cho hệ thống đặt phòng khách sạn.

DANH SÁCH PHÒNG (DỮ LIỆU THẬT):
$roomsContext

PHÒNG ĐÃ GỢI Ý TRƯỚC ĐÓ (KHÔNG ĐƯỢC GỢI Ý LẠI):
$excludedText

NHIỆM VỤ:
- Lọc phòng phù hợp với câu hỏi
- Nếu người dùng hỏi "còn phòng khác không", "xem thêm":
  → gợi ý phòng KHÁC với phòng đã gợi ý
- Nếu không còn phòng phù hợp → nói rõ là đã hết

QUY TẮC:
- KHÔNG bịa phòng
- KHÔNG bịa giá
- CHỈ dùng dữ liệu được cung cấp

ĐỊNH DẠNG JSON (BẮT BUỘC – KHÔNG THÊM CHỮ):
{
  "message": "Nội dung trả lời cho người dùng",
  "roomId": "roomId hoặc null"
}

CÂU HỎI KHÁCH:
$text
''';

      // 5️⃣ GỌI AI
      final raw = await GroqService.sendMessage(prompt);

      // ✅ parse JSON an toàn (lỡ model trả thêm chữ vẫn cắt JSON được)
      final jsonText = _extractJsonObject(raw);
      final data = jsonDecode(jsonText);

      final message = (data['message'] as String?)?.trim().isNotEmpty == true
          ? (data['message'] as String).trim()
          : 'Tôi chưa hiểu rõ yêu cầu. Bạn mô tả thêm giúp tôi nhé.';
      final String? roomId = (data['roomId'] as String?)?.trim();

      if (roomId != null && roomId.isNotEmpty) {
        _excludedRoomIds.add(roomId);
      }

      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: message,
            roomId: roomId?.isEmpty == true ? null : roomId,
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Chatbot error: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: 'Xin lỗi, hệ thống đang gặp lỗi 😥\nBạn thử lại sau nhé.',
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  /// Cắt JSON object đầu tiên trong chuỗi (tránh Groq trả thêm text)
  String _extractJsonObject(String raw) {
    final s = raw.trim();

    // Nếu raw đã là JSON object
    if (s.startsWith('{') && s.endsWith('}')) return s;

    // Tìm object { ... } đầu tiên
    final start = s.indexOf('{');
    if (start < 0) return '{"message":"Tôi chưa hiểu rõ yêu cầu.","roomId":null}';

    var depth = 0;
    for (int i = start; i < s.length; i++) {
      final ch = s[i];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (depth == 0) {
        final candidate = s.substring(start, i + 1);
        return candidate;
      }
    }

    // fallback
    return '{"message":"Tôi chưa hiểu rõ yêu cầu.","roomId":null}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              child: Icon(Icons.support_agent_rounded, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hỗ trợ tự động',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 1.2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Luôn sẵn sàng',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa lịch sử chat',
            onPressed: () {
              setState(() {
                _messages
                  ..clear()
                  ..add(ChatMessage(
                    isUser: false,
                    text: 'Xin chào! 👋 Tôi có thể giúp gì cho việc đặt phòng của bạn hôm nay?',
                  ));
                _excludedRoomIds.clear();
              });
              _scrollToBottom();
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'Tải lại dữ liệu phòng',
            onPressed: () async {
              await _ensureRoomsLoaded(showBotMessageIfEmpty: true);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Tùy chọn',
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface.withValues(alpha: 1),
              cs.surfaceContainerLowest.withValues(alpha: 1),
            ],
          ),
        ),
        child: Column(
          children: [
            // ===== CHAT LIST =====
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_loading && index == _messages.length) {
                    return const _TypingBubble();
                  }

                  final msg = _messages[index];
                  final prev = index > 0 ? _messages[index - 1] : null;

                  final showTimeDivider =
                      prev == null || !_isSameDay(prev.createdAt, msg.createdAt);

                  return Column(
                    children: [
                      if (showTimeDivider) _TimeDivider(time: msg.createdAt),
                      _ChatRow(
                        msg: msg,
                        onOpenRoom:
                        msg.roomId == null ? null : () => _openRoom(msg.roomId!),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ===== QUICK ACTIONS =====
            _QuickActions(onTap: (text) => sendMessage(text)),

            // ===== INPUT BAR =====
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Thêm',
                      onPressed: () {},
                      icon: Icon(Icons.add_circle_outline_rounded, color: cs.primary),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Emoji',
                              onPressed: () {},
                              icon: Icon(
                                Icons.emoji_emotions_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                            color: cs.primary.withValues(alpha: 0.25),
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: 'Gửi',
                        onPressed: _loading ? null : sendMessage,
                        icon: Icon(Icons.send_rounded, color: cs.onPrimary),
                      ),
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openRoom(String roomId) {
    final rooms = context.read<HotelProvider>().rooms;

    RoomModel? room;
    try {
      room = rooms.firstWhere((r) => r.roomId == roomId);
    } catch (_) {
      room = null;
    }

    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy phòng để mở chi tiết.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dynamic dyn = room;
    final String? hotelId = dyn.hotelId is String ? dyn.hotelId as String : null;

    Navigator.pushNamed(
      context,
      RoomDetailsScreen.routeName,
      arguments: {
        'roomId': room.roomId,
        if (hotelId != null) 'hotelId': hotelId,
      },
    );
  }
}

/// =======================
/// WIDGETS
/// =======================
class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.msg, this.onOpenRoom});

  final ChatMessage msg;
  final VoidCallback? onOpenRoom;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = msg.isUser;

    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
              cs.surfaceContainerHighest.withValues(alpha: 0.65),
              child: Icon(Icons.smart_toy_rounded,
                  size: 18, color: cs.primary),
            ),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? cs.primary
                        : cs.surfaceContainerHighest.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? cs.primary.withValues(alpha: 0.35)
                          : cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      height: 1.35,
                      color: isUser ? cs.onPrimary : cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isUser && msg.roomId != null && msg.roomId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onOpenRoom,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Xem chi tiết phòng'),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(Icons.person_rounded,
                  size: 18, color: cs.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
            cs.surfaceContainerHighest.withValues(alpha: 0.65),
            child: Icon(Icons.smart_toy_rounded,
                size: 18, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: const _DotTyping(),
          ),
        ],
      ),
    );
  }
}

class _DotTyping extends StatefulWidget {
  const _DotTyping();

  @override
  State<_DotTyping> createState() => _DotTypingState();
}

class _DotTypingState extends State<_DotTyping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1
        int k = (t * 3).floor() % 3; // 0,1,2
        final dots = ['•', '•', '•'];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = i <= k;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                dots[i],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: active
                      ? cs.onSurface.withValues(alpha: 0.75)
                      : cs.onSurface.withValues(alpha: 0.25),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});
  final void Function(String text) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <(IconData, String)>[
      (Icons.policy_outlined, 'Chính sách hoàn tiền'),
      (Icons.access_time_rounded, 'Giờ check-in'),
      (Icons.call_outlined, 'Liên hệ'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((it) {
            final icon = it.$1;
            final text = it.$2;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ActionChip(
                avatar: Icon(icon, size: 18, color: cs.primary),
                label: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                backgroundColor:
                cs.surfaceContainerHighest.withValues(alpha: 0.55),
                side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
                onPressed: () => onTap(text),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TimeDivider extends StatelessWidget {
  const _TimeDivider({required this.time});
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final isToday =
        now.year == time.year && now.month == time.month && now.day == time.day;
    final label = isToday
        ? 'Hôm nay, ${two(time.hour)}:${two(time.minute)}'
        : '${two(time.day)}/${two(time.month)}/${time.year}, ${two(time.hour)}:${two(time.minute)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
