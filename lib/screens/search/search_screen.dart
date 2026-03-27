import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/screens/room_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _tuKhoaCtrl = TextEditingController();

  DateTime? _ngayNhanPhong;
  DateTime? _ngayTraPhong;

  List<RoomModel> _ketQua = <RoomModel>[];
  bool _dangTai = false;

  @override
  void dispose() {
    _tuKhoaCtrl.dispose();
    super.dispose();
  }

  // ===== Utils =====
  bool _chuaDuNgay() => _ngayNhanPhong == null || _ngayTraPhong == null;

  String _fmtDay(DateTime d) {
    // UI giống ảnh: "T2, 12 Th08"
    final w = <int, String>{
      DateTime.monday: 'T2',
      DateTime.tuesday: 'T3',
      DateTime.wednesday: 'T4',
      DateTime.thursday: 'T5',
      DateTime.friday: 'T6',
      DateTime.saturday: 'T7',
      DateTime.sunday: 'CN',
    }[d.weekday]!;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$w, $dd Th$mm';
  }

  bool _coChua(String text, String keyword) {
    final t = text.toLowerCase();
    final k = keyword.toLowerCase();
    return t.contains(k);
  }

  List<RoomModel> _locTheoTuKhoa(List<RoomModel> ds, String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return ds;

    return ds.where((r) {
      final type = r.type.toString();
      final desc = r.description.toString();
      final hotelId = r.hotelId.toString();
      final roomNumber = r.roomNumber.toString();
      final amenities = (r.amenities).join(' ');

      return _coChua(type, k) ||
          _coChua(desc, k) ||
          _coChua(hotelId, k) ||
          _coChua(roomNumber, k) ||
          _coChua(amenities, k);
    }).toList();
  }

  Future<void> _chonNgay(BuildContext context, {required bool laNhanPhong}) async {
    final theme = Theme.of(context);

    final initial = laNhanPhong
        ? (_ngayNhanPhong ?? DateTime.now())
        : (_ngayTraPhong ??
        (_ngayNhanPhong?.add(const Duration(days: 1)) ?? DateTime.now()));

    final first = laNhanPhong
        ? DateTime.now()
        : (_ngayNhanPhong?.add(const Duration(days: 1)) ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (laNhanPhong) {
        _ngayNhanPhong = picked;
        if (_ngayTraPhong != null && !_ngayTraPhong!.isAfter(_ngayNhanPhong!)) {
          _ngayTraPhong = null;
        }
      } else {
        _ngayTraPhong = picked;
      }
    });
  }

  Future<void> _timKiem() async {
    final cs = Theme.of(context).colorScheme;

    if (_chuaDuNgay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn đủ ngày nhận phòng và ngày trả phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
      return;
    }

    setState(() => _dangTai = true);

    final hotelProvider = context.read<HotelProvider>();
    final tuKhoa = _tuKhoaCtrl.text.trim();

    try {
      final results = await hotelProvider.searchRooms(
        checkIn: _ngayNhanPhong!,
        checkOut: _ngayTraPhong!,
      );

      final loc = _locTheoTuKhoa(results, tuKhoa);

      if (!mounted) return;
      setState(() => _ketQua = loc);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tìm kiếm: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header giống ảnh =====
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    'Tìm phòng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // cân giữa như ảnh
                ],
              ),
            ),

            // ===== Form area =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Từ khóa',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Search box giống ảnh
                  TextField(
                    controller: _tuKhoaCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _timKiem(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: VIP, view biển, gần trung tâm',
                      filled: true,
                      fillColor: isDark
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.25)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.55), width: 1.2),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: _dangTai ? null : _timKiem,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Dates row giống ảnh (label + box)
                  Row(
                    children: [
                      Expanded(
                        child: _dateBox(
                          context: context,
                          label: 'Ngày nhận',
                          value: _ngayNhanPhong,
                          onTap: () => _chonNgay(context, laNhanPhong: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateBox(
                          context: context,
                          label: 'Ngày trả',
                          value: _ngayTraPhong,
                          onTap: () => _chonNgay(context, laNhanPhong: false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Button giống ảnh
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (!_chuaDuNgay() && !_dangTai) ? _timKiem : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _dangTai ? 'Đang tìm...' : 'Tìm kiếm',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ===== Results header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Kết quả phù hợp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_ketQua.length} phòng',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ===== List =====
            Expanded(
              child: _dangTai
                  ? const Center(child: CircularProgressIndicator())
                  : (_ketQua.isEmpty)
                  ? Center(
                child: Text(
                  'Chưa có phòng phù hợp trong khoảng ngày này.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _ketQua.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final room = _ketQua[index];
                  return RoomResultCard(room: room);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBox({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.20)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value == null ? 'Chọn ngày' : _fmtDay(value),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RoomResultCard extends StatelessWidget {
  const RoomResultCard({super.key, required this.room});
  final RoomModel room;

  String _money(num v) {
    final f = NumberFormat.decimalPattern('vi_VN');
    return '${f.format(v)}đ';
  }

  String? _badgeText() {
    final t = room.type.toString().toLowerCase();
    final d = room.description.toString().toLowerCase();

    if (t.contains('vip') || d.contains('vip')) return 'VIP Suite';
    if (d.contains('giảm') || d.contains('sale') || d.contains('discount')) return 'Giảm 20%';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageUrl = room.images.isNotEmpty ? room.images.first : '';
    final badge = _badgeText();

    // demo strike price nếu có "Giảm 20%" (UI giống ảnh)
    final showStrike = badge != null && badge.toLowerCase().contains('giảm');
    final oldPrice = showStrike ? (room.price / 0.8) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).pushNamed(
            RoomDetailsScreen.routeName,
            arguments: room,
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Image + overlays =====
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: SizedBox(
                  height: 175,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isEmpty)
                        Container(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                          alignment: Alignment.center,
                          child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
                        )
                      else
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
                          ),
                        ),

                      // Rating pill (demo UI giống ảnh)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: cs.secondary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(120)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Badge bottom-left
                      if (badge != null)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 16,
                                  spreadRadius: 0,
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.18),
                                ),
                              ],
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ===== Content =====
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // nếu chưa có hotelName thì hiển thị như ảnh (tạm)
                      'Khách sạn ${room.hotelId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Info mini chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _miniInfo(
                          context,
                          icon: Icons.person_rounded,
                          text: '2 người lớn',
                        ),
                        _miniInfo(
                          context,
                          icon: Icons.bed_rounded,
                          text: '1 giường đôi',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.30),
                    ),
                    const SizedBox(height: 12),

                    // Price + button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (oldPrice != null)
                                Text(
                                  _money(oldPrice),
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _money(room.price),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: cs.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / đêm',
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              // Giữ luồng cũ: onGenerateRoute '/booking' nhận RoomModel
                              Navigator.of(context).pushNamed('/booking', arguments: room);
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: cs.primary.withValues(alpha: 0.10),
                              foregroundColor: cs.primary,
                            ),
                            child: const Text(
                              'Đặt ngay',
                              style: TextStyle(fontWeight: FontWeight.w900),
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
      ),
    );
  }

  Widget _miniInfo(BuildContext context, {required IconData icon, required String text}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.20)
            : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withValues(alpha: 0.75),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
