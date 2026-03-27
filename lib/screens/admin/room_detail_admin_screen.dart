import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_providers.dart';
import '../../models/room_model.dart';

class AdminRoomDetailScreen extends StatelessWidget {
  final String hotelId;
  final String? hotelName;
  final RoomModel room;

  const AdminRoomDetailScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
    required this.room,
  });

  // ================== SAFE GETTERS (không crash nếu model thiếu field) ==================
  T? _safeGet<T>(Object obj, T? Function(dynamic r) getter) {
    try {
      return getter(obj as dynamic);
    } catch (_) {
      return null;
    }
  }

  String? _safeGetString(Object obj, String? Function(dynamic r) getter) {
    final v = _safeGet<String>(obj, getter);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  num? _safeGetNum(Object obj, num? Function(dynamic r) getter) {
    final v = _safeGet<num>(obj, getter);
    return v;
  }

  bool _safeGetBool(Object obj, bool? Function(dynamic r) getter) {
    final v = _safeGet<bool>(obj, getter);
    return v ?? false;
  }

  // ================== STATUS ==================
  String _statusLabel(dynamic status) {
    final s = (status is Enum)
        ? status.name.toLowerCase()
        : (status ?? '').toString().toLowerCase();

    switch (s) {
      case 'pending':
        return 'Chờ duyệt';
      case 'available':
        return 'Trống';
      case 'booked':
        return 'Đã đặt';
      case 'maintenance':
        return 'Bảo trì';
      case 'rejected':
        return 'Từ chối';
      default:
        return s.isEmpty ? '—' : s;
    }
  }

  Color _statusColor(String statusText) {
    final s = statusText.toLowerCase();
    if (s.contains('đã')) return Colors.orange;
    if (s.contains('từ')) return Colors.red;
    if (s.contains('bảo')) return Colors.blueGrey;
    if (s.contains('chờ')) return Colors.amber;
    return Colors.green;
  }

  // ================== FORMAT ==================
  String _money(num vnd) => NumberFormat.decimalPattern('vi').format(vnd);

  String _priceShort(num vnd) {
    final value = vnd.toDouble();
    if (value >= 1000000) {
      final tr = value / 1000000.0;
      final s = tr.toStringAsFixed(tr % 1 == 0 ? 0 : 1);
      return '${s}tr';
    }
    if (value >= 1000) {
      final k = value / 1000.0;
      final s = k.toStringAsFixed(k % 1 == 0 ? 0 : 1);
      return '${s}k';
    }
    return value.toStringAsFixed(0);
  }

  void _goEdit(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/edit-room',
      arguments: {
        'hotelId': hotelId,
        'hotelName': hotelName,
        'room': room,
      },
    );
  }

  // ✅ FIX lint: không dùng context sau await
  Future<void> _hoiXacNhanXoa(BuildContext context) async {
    // lấy sẵn các thứ cần dùng TRƯỚC async gap
    final cs = Theme.of(context).colorScheme;
    final provider = context.read<HotelProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa phòng này không?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await provider.deleteRoom(room.roomId);

      if (!messenger.mounted || !navigator.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã xóa phòng thành công.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.tertiaryContainer,
        ),
      );

      navigator.pop(); // quay lại
    } catch (_) {
      if (!messenger.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể xóa phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final images = (room.images).map((e) => e.toString()).toList();
    final statusText = _statusLabel(room.status);
    final statusColor = _statusColor(statusText);

    // optional fields (nếu model có thì tự hiện)
    final bedType = _safeGetString(room, (r) => r.bedType) ??
        _safeGetString(room, (r) => r.bed) ??
        'Double';

    final isVip = _safeGetBool(room, (r) => r.isVip) ||
        room.type.toLowerCase().contains('vip');

    final area = _safeGetNum(room, (r) => r.area) ??
        _safeGetNum(room, (r) => r.squareMeters);
    final floor = _safeGetNum(room, (r) => r.floor);

    final amenities = _safeGet<List>(room, (r) => r.amenities) ?? <dynamic>[];
    final amenityText = amenities
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phòng'),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _goEdit(context),
          ),
          IconButton(
            tooltip: 'Xóa',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _hoiXacNhanXoa(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // ===== Gallery =====
          _ImageGallery(images: images),

          const SizedBox(height: 16),

          // ===== Title + price =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Phòng ${room.type}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _priceShort(room.price),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/ đêm',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ===== Chips row =====
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(
                icon: Icons.circle,
                iconColor: statusColor,
                label: statusText,
                bg: statusColor.withValues(alpha: 0.12),
                fg: statusColor,
              ),
              _Pill(
                icon: Icons.bed_outlined,
                label: bedType,
                bg: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                fg: cs.onSurface,
              ),
              _Pill(
                icon: Icons.person_outline,
                label: '${room.maxGuests} Người lớn',
                bg: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                fg: cs.onSurface,
              ),
              if (isVip)
                _Pill(
                  icon: Icons.star,
                  label: 'VIP',
                  bg: Colors.orange.withValues(alpha: 0.16),
                  fg: Colors.orange.shade800,
                ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6)),
          const SizedBox(height: 14),

          // ===== Mô tả =====
          Row(
            children: [
              Icon(Icons.description_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                'Mô tả',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            room.description.trim().isEmpty ? 'Chưa có mô tả.' : room.description,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.82),
              height: 1.45,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 18),

          // ===== Action buttons =====
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _hoiXacNhanXoa(context),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Xóa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.35)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _goEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Chỉnh sửa'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== Info mini cards =====
          Row(
            children: [
              Expanded(
                child: _MiniInfoCard(
                  label: 'Diện tích',
                  value: area == null
                      ? '—'
                      : '${area.toString().replaceAll(RegExp(r'\.0$'), '')}m²',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInfoCard(
                  label: 'Tầng',
                  value: floor == null
                      ? '—'
                      : floor.toString().replaceAll(RegExp(r'\.0$'), ''),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== Amenities =====
          if (amenityText.trim().isNotEmpty)
            _WideInfoCard(
              label: 'Tiện ích đặc biệt',
              value: amenityText,
            ),

          const SizedBox(height: 12),

          _WideInfoCard(label: 'Mã phòng', value: room.roomId),
          const SizedBox(height: 10),
          _WideInfoCard(
            label: 'Khách sạn',
            value: hotelName?.trim().isNotEmpty == true ? hotelName! : hotelId,
          ),
          const SizedBox(height: 10),
          _WideInfoCard(label: 'Giá / đêm', value: '${_money(room.price)} VNĐ'),
        ],
      ),
    );
  }
}

// =================== UI Components ===================

class _ImageGallery extends StatefulWidget {
  final List<String> images;
  const _ImageGallery({required this.images});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final images = widget.images;

    if (images.isEmpty) {
      return Container(
        height: 230,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: cs.onSurfaceVariant,
          size: 44,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (_, i) => Image.network(
                images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: cs.onSurfaceVariant,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color? iconColor;

  const _Pill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor ?? fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideInfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _WideInfoCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
