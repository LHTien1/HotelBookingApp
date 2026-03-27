import 'package:booking_app/models/hotel_model.dart';
import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/widgets/location_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({super.key});

  static const routeName = '/room-details';

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  HotelModel? _khachSan;
  RoomModel? _phong;

  bool _dangTaiPhong = true;
  bool _dangTaiHotel = true;
  bool _daTaiDuLieu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_daTaiDuLieu) return;
    _daTaiDuLieu = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _initFromArgs(args);
  }

  Future<void> _initFromArgs(dynamic args) async {
    // ✅ lấy provider TRƯỚC await để không dính lint async gap
    final hotelProvider = context.read<HotelProvider>();

    // Case 1: truyền thẳng RoomModel (các màn cũ)
    if (args is RoomModel) {
      _phong = args;
      setState(() {
        _dangTaiPhong = false;
        _dangTaiHotel = true;
      });
      await _taiThongTinKhachSan(hotelProvider, args.hotelId);
      return;
    }

    // Case 2: truyền Map (chatbot / điều hướng theo id)
    if (args is Map) {
      // nếu map có 'room' là RoomModel
      final roomArg = args['room'];
      if (roomArg is RoomModel) {
        _phong = roomArg;
        setState(() {
          _dangTaiPhong = false;
          _dangTaiHotel = true;
        });
        await _taiThongTinKhachSan(hotelProvider, roomArg.hotelId);
        return;
      }

      final roomId = (args['roomId'] ?? args['id'])?.toString().trim();
      final hotelIdArg = args['hotelId']?.toString().trim();

      if (roomId != null && roomId.isNotEmpty) {
        await _taiPhongTheoId(hotelProvider, roomId);

        if (!mounted) return;
        final room = _phong;
        if (room == null) {
          // không tìm thấy phòng
          setState(() {
            _dangTaiHotel = false;
          });
          return;
        }

        final hotelId = (hotelIdArg != null && hotelIdArg.isNotEmpty)
            ? hotelIdArg
            : room.hotelId;

        await _taiThongTinKhachSan(hotelProvider, hotelId);
        return;
      }
    }

    // fallback: không có dữ liệu
    if (!mounted) return;
    setState(() {
      _dangTaiPhong = false;
      _dangTaiHotel = false;
    });
  }

  Future<void> _taiPhongTheoId(HotelProvider hotelProvider, String roomId) async {
    try {
      if (!mounted) return;
      setState(() => _dangTaiPhong = true);

      final room = await hotelProvider.getRoomById(roomId);

      if (!mounted) return;
      setState(() {
        _phong = room;
        _dangTaiPhong = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dangTaiPhong = false);
    }
  }

  Future<void> _taiThongTinKhachSan(
      HotelProvider hotelProvider,
      String hotelId,
      ) async {
    try {
      if (!mounted) return;
      setState(() => _dangTaiHotel = true);

      final hotel = await hotelProvider.getHotelById(hotelId);

      if (!mounted) return;
      setState(() {
        _khachSan = hotel;
        _dangTaiHotel = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dangTaiHotel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // ✅ đang tải phòng theo roomId
    if (_phong == null && _dangTaiPhong) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng')),
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    final room = _phong;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng')),
        body: Center(
          child: Text(
            'Không nhận được dữ liệu phòng.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    final anh = room.images.isNotEmpty ? room.images.first.trim() : '';
    final coAnh = anh.isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: _BottomBookingBar(
        price: room.price,
        onBook: () => Navigator.of(context).pushNamed(
          '/booking',
          arguments: room, // ✅ booking cần RoomModel
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 320,
            backgroundColor: cs.surface,
            elevation: 0,
            leading: _RoundIconButton(
              icon: Icons.close,
              tooltip: 'Đóng',
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _RoundIconButton(
                  icon: Icons.report,
                  tooltip: 'Báo cáo',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/add-report',
                      arguments: {
                        'hotelId': room.hotelId,
                        'roomId': room.roomId,
                      },
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Hero(
                tag: 'room_image_${room.roomId}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coAnh)
                      Image.network(
                        anh,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _anhLoi(cs),
                      )
                    else
                      _anhLoi(cs),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            cs.surface.withValues(alpha: 0.75),
                            cs.surface.withValues(alpha: 0.05),
                            cs.surface.withValues(alpha: 0.90),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(
                    imageUrl: anh,
                    hasImage: coAnh,
                    roomType: room.type,
                    price: room.price,
                    isLoadingHotel: _dangTaiHotel,
                    hotelName: _khachSan?.name,
                    cs: cs,
                  ),

                  const SizedBox(height: 16),

                  if (_dangTaiHotel)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      ),
                    )
                  else if (_khachSan == null)
                    _InfoCard(
                      title: 'Thông tin khách sạn',
                      cs: cs,
                      child: Text(
                        'Không tìm thấy thông tin khách sạn.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    _RoomContent(
                      room: room,
                      hotel: _khachSan!,
                      cs: cs,
                      isDark: isDark,
                    ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _anhLoi(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: cs.onSurfaceVariant,
        size: 42,
      ),
    );
  }
}

class _RoomContent extends StatelessWidget {
  const _RoomContent({
    required this.room,
    required this.hotel,
    required this.cs,
    required this.isDark,
  });

  final RoomModel room;
  final HotelModel hotel;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Mô tả',
          cs: cs,
          child: Text(
            room.description.trim().isEmpty ? 'Chưa có mô tả.' : room.description,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.55,
              color: cs.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        _InfoCard(
          title: 'Tiện nghi',
          cs: cs,
          child: room.amenities.isEmpty
              ? Text(
            'Chưa cập nhật tiện nghi.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          )
              : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: room.amenities.map((t) {
              return Chip(
                label: Text(
                  t,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.86),
                  ),
                ),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(
                    alpha: isDark ? 0.25 : 0.6,
                  ),
                ),
                backgroundColor:
                cs.surfaceContainerHighest.withValues(alpha: 0.55),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        _InfoCard(
          title: 'Vị trí',
          cs: cs,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LocationMap(location: hotel.location, hotelName: hotel.name),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.imageUrl,
    required this.hasImage,
    required this.roomType,
    required this.price,
    required this.isLoadingHotel,
    required this.hotelName,
    required this.cs,
  });

  final String imageUrl;
  final bool hasImage;
  final String roomType;
  final num price;
  final bool isLoadingHotel;
  final String? hotelName;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 78,
              height: 78,
              child: hasImage
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  child: Icon(Icons.photo, color: cs.onSurfaceVariant),
                ),
              )
                  : Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                child: Icon(Icons.photo, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đang xem',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hotelName ??
                      (isLoadingHotel
                          ? 'Đang tải khách sạn...'
                          : 'Không rõ khách sạn'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roomType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${price.toStringAsFixed(0)} VNĐ\n/ đêm',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: cs.secondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    required this.cs,
  });

  final String title;
  final Widget child;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 10),
            color: cs.shadow.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BottomBookingBar extends StatelessWidget {
  const _BottomBookingBar({
    required this.price,
    required this.onBook,
  });

  final num price;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${price.toStringAsFixed(0)} VNĐ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: onBook,
                  child: const Text(
                    'Đặt phòng ngay',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: cs.surface.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
