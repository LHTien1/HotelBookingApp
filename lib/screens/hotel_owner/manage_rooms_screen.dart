import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_providers.dart';
import '../../models/room_model.dart';

class ManageRoomsScreen extends StatefulWidget {
  final String hotelId;
  final String? hotelName;

  const ManageRoomsScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
  });

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final _searchCtrl = TextEditingController();
  int _filterIndex = 0; // 0 all, 1 available, 2 booked

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ✅ RoomModel.status là enum (non-null) -> dùng name trực tiếp, không check type, không ??.
  String _statusKey(Enum status) => status.name.toLowerCase();

  String _statusLabel(Enum status) {
    switch (_statusKey(status)) {
      case 'pending':
        return 'Chờ duyệt';
      case 'available':
        return 'Trống';
      case 'booked':
        return 'Đang thuê';
      case 'maintenance':
        return 'Bảo trì';
      case 'rejected':
        return 'Từ chối';
      default:
        return status.name; // fallback an toàn
    }
  }

  bool _matchFilter(RoomModel r) {
    final s = _statusKey(r.status);
    if (_filterIndex == 1) return s == 'available';
    if (_filterIndex == 2) return s == 'booked';
    return true;
  }

  bool _matchSearch(RoomModel r) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final a = '${r.roomNumber} ${r.type} ${r.description}'.toLowerCase();
    return a.contains(q);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelProvider>().loadHotelRooms(widget.hotelId);
    });
  }

  Future<void> _reload() async {
    await context.read<HotelProvider>().loadHotelRooms(widget.hotelId);
  }

  Future<void> _xoaPhong(String maPhong) async {
    final hotelProvider = context.read<HotelProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    try {
      await hotelProvider.deleteRoom(maPhong);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã xóa phòng thành công.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.tertiaryContainer,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(hotelProvider.errorMessage ?? 'Không thể xóa phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    }
  }

  void _hoiXacNhanXoa(String maPhong) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa phòng này không?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _xoaPhong(maPhong);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hn = widget.hotelName?.trim();
    final hasName = hn != null && hn.isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(hasName ? 'Quản lý phòng • $hn' : 'Quản lý phòng'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Đăng phòng mới',
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/post-room',
                arguments: {
                  'hotelId': widget.hotelId,
                  'hotelName': widget.hotelName,
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, _) {
          final rooms = hotelProvider.rooms;

          final int total = rooms.length;
          final int available =
              rooms.where((r) => _statusKey(r.status) == 'available').length;
          final int booked =
              rooms.where((r) => _statusKey(r.status) == 'booked').length;

          final filtered = rooms
              .where(_matchFilter)
              .where(_matchSearch)
              .toList(growable: false);

          if (hotelProvider.isLoading && rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tất cả ($total)',
                        selected: _filterIndex == 0,
                        onTap: () => setState(() => _filterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Trống ($available)',
                        selected: _filterIndex == 1,
                        onTap: () => setState(() => _filterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Đang thuê ($booked)',
                        selected: _filterIndex == 2,
                        onTap: () => setState(() => _filterIndex = 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (rooms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        'Bạn chưa đăng phòng nào.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        'Không tìm thấy phòng phù hợp.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                // ✅ bỏ .toList() sau map (spread không cần)
                  ...filtered.map((phong) {
                    final imageUrl =
                    phong.images.isNotEmpty ? phong.images.first.toString() : '';
                    final statusText = _statusLabel(phong.status);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoomCard(
                        imageUrl: imageUrl,
                        title: 'Phòng ${phong.roomNumber}',
                        subtitle: phong.type,
                        status: statusText,
                        priceText: '${phong.price.toStringAsFixed(0)} VNĐ/đêm',
                        maxGuests: phong.maxGuests,
                        description: phong.description,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/room-detail',
                            arguments: {
                              'hotelId': widget.hotelId,
                              'hotelName': widget.hotelName,
                              'room': phong,
                            },
                          );
                        },
                        onEdit: () {
                          Navigator.of(context).pushNamed(
                            '/edit-room',
                            arguments: {
                              'hotelId': widget.hotelId,
                              'hotelName': widget.hotelName,
                              'room': phong,
                            },
                          );
                        },
                        onDelete: () => _hoiXacNhanXoa(phong.roomId),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _SearchBar({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm theo số phòng, loại phòng…',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String status;
  final String priceText;
  final int maxGuests;
  final String description;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.priceText,
    required this.maxGuests,
    required this.description,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color badgeBg = cs.surfaceContainerHighest;
    Color badgeFg = cs.onSurfaceVariant;

    final s = status.toLowerCase();
    if (s.contains('trống')) {
      badgeBg = cs.tertiaryContainer;
      badgeFg = cs.onTertiaryContainer;
    } else if (s.contains('đang thuê') || s.contains('đã đặt')) {
      badgeBg = cs.errorContainer;
      badgeFg = cs.onErrorContainer;
    } else if (s.contains('chờ')) {
      badgeBg = cs.secondaryContainer;
      badgeFg = cs.onSecondaryContainer;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 72,
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  child: imageUrl.isEmpty
                      ? Icon(Icons.image_not_supported_outlined,
                      color: cs.onSurfaceVariant)
                      : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$title • $subtitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: badgeFg,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$priceText • Khách: $maxGuests',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Sửa',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: 'Xóa',
                          onPressed: onDelete,
                          icon: Icon(Icons.delete_rounded, color: cs.error),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
