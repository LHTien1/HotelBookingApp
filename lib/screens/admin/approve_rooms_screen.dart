import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ApproveRoomsScreen extends StatefulWidget {
  const ApproveRoomsScreen({super.key});

  @override
  State<ApproveRoomsScreen> createState() => _ApproveRoomsScreenState();
}

class _ApproveRoomsScreenState extends State<ApproveRoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<HotelProvider>();

      // load phòng chờ duyệt
      await p.loadPendingRooms();

      // preload tên KS để hiển thị
      await p.preloadHotelNames(p.rooms.map((e) => e.hotelId));
    });
  }

  Future<void> _duyetPhong(String maPhong) async {
    final hotelProvider = context.read<HotelProvider>();
    try {
      await hotelProvider.updateRoomStatus(maPhong, RoomStatus.available);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã duyệt phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hotelProvider.errorMessage ?? 'Có lỗi xảy ra.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _tuChoiPhong(String maPhong) async {
    final hotelProvider = context.read<HotelProvider>();
    try {
      await hotelProvider.updateRoomStatus(maPhong, RoomStatus.rejected);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã từ chối phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hotelProvider.errorMessage ?? 'Có lỗi xảy ra.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final themeProvider = context.watch<ThemeProvider>();
    final dangToi = themeProvider.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt phòng chờ'),
        actions: [
          IconButton(
            tooltip: dangToi ? 'Chuyển sang sáng' : 'Chuyển sang tối',
            icon: Icon(dangToi ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(context),
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading && hotelProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.rooms.isEmpty) {
            return Center(
              child: Text(
                'Không có phòng nào đang chờ duyệt.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          final danhSachPhongChoDuyet = hotelProvider.rooms;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: danhSachPhongChoDuyet.length,
            itemBuilder: (ctx, i) {
              final phong = danhSachPhongChoDuyet[i];

              // ✅ Lấy tên khách sạn từ cache (nếu chưa có thì fallback về hotelId)
              final tenKS = hotelProvider.getHotelNameCached(phong.hotelId) ?? phong.hotelId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                elevation: isDark ? 0 : 2,
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    foregroundColor: cs.primary,
                    child: Text(
                      phong.roomNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    phong.type,
                    style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  subtitle: Text(
                    'Tên khách sạn: $tenKS\n'
                        'Giá: ${phong.price.toStringAsFixed(0)} VNĐ',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Duyệt',
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _duyetPhong(phong.roomId),
                        ),
                        IconButton(
                          tooltip: 'Từ chối',
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _tuChoiPhong(phong.roomId),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
