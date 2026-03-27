import 'package:booking_app/providers/booking_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorBookingsScreen extends StatefulWidget {
  const MonitorBookingsScreen({super.key});

  @override
  State<MonitorBookingsScreen> createState() => _MonitorBookingsScreenState();
}

class _MonitorBookingsScreenState extends State<MonitorBookingsScreen> {
  String _filterKey = 'all'; // all | confirmed | pending | cancelled
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadAllBookings();
    });
  }

  // ✅ Map trạng thái sang tiếng Việt
  String _statusVi(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checkedin':
      case 'checkin':
        return 'Đã nhận phòng';
      case 'checkedout':
      case 'checkout':
        return 'Đã trả phòng';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn tất';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return statusName;
    }
  }

  bool _isCancelled(String statusName) {
    final s = statusName.toLowerCase();
    return s == 'cancelled' || s == 'canceled';
  }

  bool _matchFilter(String statusName) {
    final s = statusName.toLowerCase();
    if (_filterKey == 'all') return true;
    if (_filterKey == 'confirmed') return s == 'confirmed';
    if (_filterKey == 'pending') return s == 'pending';
    if (_filterKey == 'cancelled') return s == 'cancelled' || s == 'canceled';
    return true;
  }

  // ✅ tránh crash nếu model booking không có field guestName / roomNumber...
  T? _safeGet<T>(Object obj, T? Function(dynamic b) getter) {
    try {
      return getter(obj as dynamic);
    } catch (_) {
      return null;
    }
  }

  String? _safeGetString(Object obj, String? Function(dynamic b) getter) {
    final v = _safeGet<String>(obj, getter);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool _matchQuery(dynamic booking) {
    if (_query.trim().isEmpty) return true;
    final q = _query.trim().toLowerCase();

    final bookingId = (booking.bookingId ?? '').toString().toLowerCase();
    final hotelId = (booking.hotelId ?? '').toString().toLowerCase();
    final roomId = (booking.roomId ?? '').toString().toLowerCase();

    final guestName = _safeGetString(booking, (b) => b.guestName) ??
        _safeGetString(booking, (b) => b.customerName) ??
        _safeGetString(booking, (b) => b.userName) ??
        '';

    return bookingId.contains(q) ||
        hotelId.contains(q) ||
        roomId.contains(q) ||
        guestName.toLowerCase().contains(q);
  }

  String _formatDateVN(DateTime dt) {
    // giống ảnh: "20 Th10, 2023"
    return '${dt.day} Th${dt.month}, ${dt.year}';
  }

  String _roomLabel(dynamic booking) {
    // ưu tiên roomNumber nếu có
    final roomNumber =
        _safeGetString(booking, (b) => b.roomNumber) ?? booking.roomId.toString();

    final raw = roomNumber.trim();
    final onlyDigits = RegExp(r'^\d+$').hasMatch(raw);

    if (raw.toLowerCase().startsWith('p.')) return raw;
    if (onlyDigits) return 'P.$raw';
    return raw;
  }

  _StatusBadgeStyle _badgeStyle(String statusName, ColorScheme cs) {
    final s = statusName.toLowerCase();

    if (s == 'confirmed') {
      return _StatusBadgeStyle(
        label: 'ĐÃ XÁC NHẬN',
        bg: Colors.green.withValues(alpha: 0.14),
        fg: Colors.green.shade800,
      );
    }
    if (s == 'pending') {
      return _StatusBadgeStyle(
        label: 'CHỜ XỬ LÝ',
        bg: Colors.orange.withValues(alpha: 0.14),
        fg: Colors.orange.shade800,
      );
    }
    if (s == 'cancelled' || s == 'canceled') {
      return _StatusBadgeStyle(
        label: 'ĐÃ HỦY',
        bg: Colors.red.withValues(alpha: 0.12),
        fg: Colors.red.shade700,
      );
    }

    // fallback
    return _StatusBadgeStyle(
      label: _statusVi(statusName).toUpperCase(),
      bg: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      fg: cs.onSurface,
    );
  }

  Future<void> _openSearch() async {
    final ctrl = TextEditingController(text: _query);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tìm kiếm đặt phòng',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập mã đặt phòng / mã KS / mã phòng / tên khách...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ctrl.text.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () => ctrl.clear(),
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: const Text('Xóa lọc'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() => _query = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi đặt phòng'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // bạn muốn mở màn tạo booking thì thay ở đây
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Chức năng thêm đặt phòng đang phát triển.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: cs.primary,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.bookings.isEmpty) {
            return Center(
              child: Text(
                'Chưa có đơn đặt phòng nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          final all = bookingProvider.bookings;
          final filtered = all.where((b) {
            final statusName = b.bookingStatus.name;
            return _matchFilter(statusName) && _matchQuery(b);
          }).toList();

          return Column(
            children: [
              // Chips lọc như ảnh
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TopChip(
                        label: 'Tất cả',
                        selected: _filterKey == 'all',
                        onTap: () => setState(() => _filterKey = 'all'),
                      ),
                      const SizedBox(width: 10),
                      _TopChip(
                        label: 'Đã xác nhận',
                        selected: _filterKey == 'confirmed',
                        onTap: () => setState(() => _filterKey = 'confirmed'),
                      ),
                      const SizedBox(width: 10),
                      _TopChip(
                        label: 'Chờ xử lý',
                        selected: _filterKey == 'pending',
                        onTap: () => setState(() => _filterKey = 'pending'),
                      ),
                      const SizedBox(width: 10),
                      _TopChip(
                        label: 'Đã hủy',
                        selected: _filterKey == 'cancelled',
                        onTap: () => setState(() => _filterKey = 'cancelled'),
                      ),
                      if (_query.trim().isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 16, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                _query,
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _query = ''),
                                child: Icon(Icons.close, size: 16, color: cs.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // List card giống ảnh
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text(
                    'Không có dữ liệu phù hợp.',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 90),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final booking = filtered[i];
                    final statusName = booking.bookingStatus.name;
                    final isCancel = _isCancelled(statusName);

                    final badge = _badgeStyle(statusName, cs);

                    final bookingCode = booking.bookingId.toString();
                    final hotelId = booking.hotelId.toString();
                    final roomText = _roomLabel(booking);

                    final dateText = _formatDateVN(booking.checkInDate);

                    final guestName = _safeGetString(booking, (b) => b.guestName) ??
                        _safeGetString(booking, (b) => b.customerName) ??
                        _safeGetString(booking, (b) => b.userName) ??
                        '—';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: isDark ? 0 : 2,
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.55),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RoomThumb(
                              roomId: booking.roomId.toString(),
                              grayscale: isCancel,
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '#$bookingCode',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isCancel
                                                ? cs.onSurface.withValues(alpha: 0.40)
                                                : cs.primary,
                                            decoration: isCancel
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _StatusBadge(badge: badge),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  Text(
                                    '$hotelId • $roomText',
                                    style: TextStyle(
                                      color: isCancel
                                          ? cs.onSurface.withValues(alpha: 0.45)
                                          : cs.onSurface.withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: cs.onSurface.withValues(alpha: 0.55),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dateText,
                                          style: TextStyle(
                                            color: cs.onSurface.withValues(alpha: 0.85),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.person,
                                        size: 18,
                                        color: cs.onSurface.withValues(alpha: 0.55),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          guestName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: cs.onSurface.withValues(alpha: 0.75),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ====================== Widgets nhỏ ======================

class _TopChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : cs.onSurface,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primary,
      backgroundColor: cs.surface,
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}

class _StatusBadgeStyle {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusBadgeStyle({
    required this.label,
    required this.bg,
    required this.fg,
  });
}

class _StatusBadge extends StatelessWidget {
  final _StatusBadgeStyle badge;

  const _StatusBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: badge.fg,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RoomThumb extends StatelessWidget {
  final String roomId;
  final bool grayscale;

  const _RoomThumb({
    required this.roomId,
    required this.grayscale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget placeholder() {
      return Container(
        width: 110,
        height: 78,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.bed_outlined, size: 34, color: cs.primary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 110,
        height: 78,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          // ✅ rooms/{roomId} -> imageUrls[0]
          stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) {
              return placeholder();
            }

            final data = snap.data!.data() ?? <String, dynamic>{};
            final urls = (data['imageUrls'] is List) ? List.from(data['imageUrls']) : const [];
            final firstUrl = urls.isNotEmpty ? urls.first.toString() : '';

            if (firstUrl.trim().isEmpty) {
              return placeholder();
            }

            Widget img = Image.network(
              firstUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder(),
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                    ),
                  ),
                );
              },
            );

            if (grayscale) {
              img = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: img,
              );
            }

            return img;
          },
        ),
      ),
    );
  }
}
