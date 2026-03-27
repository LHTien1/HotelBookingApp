import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/screens/user/momo_payment_screen.dart'; // Import Momo payment screen
import 'package:booking_app/screens/user/vnpay_payment_screen.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.room});

  static const routeName = '/booking';

  final RoomModel room;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _ngayNhanPhong;
  DateTime? _ngayTraPhong;

  final _ghiChuCtrl = TextEditingController();

  String _payment = 'Thẻ tín dụng / Ghi nợ';

  @override
  void dispose() {
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  void _thongBao(String noiDung, {bool laLoi = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          noiDung,
          style: TextStyle(
            color: laLoi ? cs.onErrorContainer : cs.onTertiaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  Future<void> _chonNgay({required bool laNhanPhong}) async {
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
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

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

  int get _soDem {
    if (_ngayNhanPhong == null || _ngayTraPhong == null) return 0;
    final nights = _ngayTraPhong!.difference(_ngayNhanPhong!).inDays;
    return nights > 0 ? nights : 0;
  }

  double get _tongTien => widget.room.price * _soDem;

  Future<void> _datPhong() async {
    FocusScope.of(context).unfocus();

    if (_ngayNhanPhong == null || _ngayTraPhong == null || _soDem <= 0) {
      _thongBao('Vui lòng chọn ngày nhận phòng và ngày trả phòng hợp lệ.');
      return;
    }

    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _thongBao('Bạn cần đăng nhập để đặt phòng.', laLoi: true);
      return;
    }

    final bookingProvider = context.read<BookingProvider>();
    try {
      debugPrint('VNPay Debug: Creating booking...');
      debugPrint('VNPay Debug: Payment method = $_payment');

      final bookingId = await bookingProvider.createBooking(
        userId: uid,
        hotelId: widget.room.hotelId,
        roomId: widget.room.roomId,
        checkInDate: _ngayNhanPhong!,
        checkOutDate: _ngayTraPhong!,
        notes: _ghiChuCtrl.text.trim(),
      );

      debugPrint('VNPay Debug: bookingId = $bookingId');

      if (!mounted) {
        debugPrint('VNPay Debug: Widget not mounted!');
        return;
      }

      if (bookingId == null) {
        debugPrint(
          'VNPay Debug: bookingId is null! Error: ${bookingProvider.errorMessage}',
        );
        _thongBao(
          'Không thể tạo đơn đặt phòng: ${bookingProvider.errorMessage ?? "Lỗi không xác định"}',
          laLoi: true,
        );
        return;
      }

      // VNPay payment flow
      if (_payment == 'VNPay') {
        debugPrint('VNPay Debug: Navigating to VNPayPaymentScreen...');
        Navigator.of(context).pushNamed(
          VNPayPaymentScreen.routeName,
          arguments: {
            'bookingId': bookingId,
            'room': widget.room,
            'totalAmount': _tongTien,
            'checkInDate': _ngayNhanPhong!,
            'checkOutDate': _ngayTraPhong!,
          },
        );
        return;
      }

      // Momo payment flow
      if (_payment == 'Momo') {
        debugPrint('Momo Debug: Navigating to MomoPaymentScreen...');
        Navigator.of(context).pushNamed(
          MomoPaymentScreen.routeName,
          arguments: {
            'bookingId': bookingId,
            'room': widget.room,
            'totalAmount': _tongTien,
            'checkInDate': _ngayNhanPhong!,
            'checkOutDate': _ngayTraPhong!,
          },
        );
        return;
      }

      // Other payment methods
      final ok = await bookingProvider.makePayment(
        bookingId: bookingId,
        paymentMethod: _payment,
      );

      if (!mounted) return;

      if (ok) {
        _hienDialogThanhCong();
      } else {
        throw Exception(bookingProvider.errorMessage ?? 'Thanh toán thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      _thongBao('Không thể đặt phòng: $e', laLoi: true);
    }
  }

  void _hienDialogThanhCong() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Đặt phòng thành công!'),
          content: const Text(
            'Đơn đặt phòng của bạn đã được xác nhận. Bạn có thể xem lại trong mục “Đơn đặt phòng”.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/my-bookings',
                  (route) => route.isFirst,
                );
              },
              child: Text(
                'Xem đơn đặt phòng',
                style: TextStyle(color: cs.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat('#,###', 'vi_VN');
    final imageUrl = widget.room.images.isNotEmpty
        ? widget.room.images.first
        : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt phòng')),
      bottomNavigationBar: Consumer<BookingProvider>(
        builder: (context, p, _) => AppBottomPrimaryButton(
          text: 'Xác nhận đặt phòng',
          isLoading: p.isLoading,
          onPressed: p.isLoading ? null : _datPhong,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: imageUrl.trim().isEmpty
                          ? _thumbFallback(cs)
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbFallback(cs),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khách sạn',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phòng ${widget.room.type}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mã: ${widget.room.hotelId}',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text(
              'Thời gian lưu trú',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: 'Ngày nhận phòng',
                    value: _ngayNhanPhong,
                    onTap: () => _chonNgay(laNhanPhong: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: 'Ngày trả phòng',
                    value: _ngayTraPhong,
                    onTap: () => _chonNgay(laNhanPhong: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_soDem > 0)
              Align(
                alignment: Alignment.centerRight,
                child: AppPill(text: '$_soDem đêm', color: cs.primary),
              ),

            const SizedBox(height: 18),
            Text(
              'Ghi chú/Yêu cầu đặc biệt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ghiChuCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Phòng không hút thuốc, check-in muộn...',
              ),
            ),

            const SizedBox(height: 18),
            Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _PayOption(
              title: 'VNPay',
              subtitle: 'QR Code, ATM, Visa/Master/JCB',
              selected: _payment == 'VNPay',
              onTap: () => setState(() => _payment = 'VNPay'),
              icon: Icons.qr_code,
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            _PayOption(
              title: 'Thẻ Tín dụng / Ghi nợ',
              subtitle: 'Visa, Mastercard, JCB',
              selected: _payment == 'Thẻ tín dụng / Ghi nợ',
              onTap: () => setState(() => _payment = 'Thẻ tín dụng / Ghi nợ'),
            ),
            const SizedBox(height: 10),
            _PayOption(
              title: 'MoMo',
              subtitle: 'Ví điện tử MoMo',
              selected: _payment == 'Momo',
              onTap: () => setState(() => _payment = 'Momo'),
            ),
            const SizedBox(height: 10),
            _PayOption(
              title: 'Thanh toán tại khách sạn',
              subtitle: 'Không cần thẻ tín dụng',
              selected: _payment == 'Thanh toán tại khách sạn',
              onTap: () =>
                  setState(() => _payment = 'Thanh toán tại khách sạn'),
            ),

            const SizedBox(height: 18),
            Text(
              'Chi tiết giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _PriceRow(
                    left: '${money.format(widget.room.price)} x $_soDem đêm',
                    right: '${money.format(_tongTien)}đ',
                  ),
                  const SizedBox(height: 10),
                  Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 10),
                  _PriceRow(
                    left: 'Tổng cộng',
                    right: '${money.format(_tongTien)}đ',
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Icon(Icons.image, color: cs.onSurfaceVariant, size: 30),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                color: cs.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value == null ? 'Chọn ngày' : f.format(value!),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary && selected
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.75)
                : cs.outlineVariant.withValues(alpha: 0.55),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon ?? Icons.payment_outlined, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? cs.primary : cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.left, required this.right, this.bold = false});

  final String left;
  final String right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: bold ? 0.9 : 0.7),
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontSize: bold ? 18 : 14.5,
          ),
        ),
      ],
    );
  }
}
