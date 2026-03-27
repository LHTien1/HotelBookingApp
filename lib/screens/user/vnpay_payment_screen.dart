import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/services/vnpay_service.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// VNPay Payment Screen
///
/// Shows payment summary and launches VNPay payment page.
class VNPayPaymentScreen extends StatefulWidget {
  const VNPayPaymentScreen({
    super.key,
    required this.bookingId,
    required this.room,
    required this.totalAmount,
    required this.checkInDate,
    required this.checkOutDate,
  });

  static const routeName = '/vnpay-payment';

  final String bookingId;
  final RoomModel room;
  final double totalAmount;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  @override
  State<VNPayPaymentScreen> createState() => _VNPayPaymentScreenState();
}

class _VNPayPaymentScreenState extends State<VNPayPaymentScreen> {
  final VNPayService _vnpayService = VNPayService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-launch payment after a short delay
    Future.delayed(const Duration(milliseconds: 500), _initiatePayment);
  }

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final orderInfo = 'Thanh toan dat phong ${widget.room.type}';

      final paymentUrl = _vnpayService.generatePaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.totalAmount,
        orderInfo: orderInfo,
      );

      final uri = Uri.parse(paymentUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không thể mở trang thanh toán VNPay');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  void _cancelPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy thanh toán?'),
        content: const Text(
          'Đơn đặt phòng của bạn sẽ được lưu với trạng thái chờ thanh toán. '
          'Bạn có thể thanh toán sau trong mục "Đơn đặt phòng".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tiếp tục thanh toán'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/my-bookings',
                (route) => route.isFirst,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat('#,###', 'vi_VN');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nights = widget.checkOutDate.difference(widget.checkInDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelPayment,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment summary card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.payment, color: cs.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thanh toán qua VNPay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'QR Code, ATM, Visa/Master/JCB',
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
                  const SizedBox(height: 20),
                  Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 16),

                  // Booking details
                  _buildInfoRow('Phòng', widget.room.type, cs),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'Nhận phòng',
                    dateFormat.format(widget.checkInDate),
                    cs,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'Trả phòng',
                    dateFormat.format(widget.checkOutDate),
                    cs,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('Số đêm', '$nights đêm', cs),
                  const SizedBox(height: 16),
                  Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 16),

                  // Total amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${money.format(widget.totalAmount)}đ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status section
            if (_isProcessing)
              _buildStatusSection(
                cs,
                icon: Icons.open_in_browser,
                title: 'Đang mở trang thanh toán...',
                subtitle: 'Vui lòng hoàn tất thanh toán trên trình duyệt',
                isLoading: true,
              ),

            if (_errorMessage != null)
              _buildStatusSection(
                cs,
                icon: Icons.error_outline,
                title: 'Không thể mở trang thanh toán',
                subtitle: _errorMessage!,
                isError: true,
              ),

            const SizedBox(height: 24),

            // Action buttons
            if (_errorMessage != null) ...[
              FilledButton.icon(
                onPressed: _initiatePayment,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
            ],

            OutlinedButton(
              onPressed: _cancelPayment,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Thanh toán sau'),
            ),

            const SizedBox(height: 32),

            // Instructions
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hướng dẫn thanh toán',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    '1',
                    'Chọn phương thức thanh toán (QR, ATM, Thẻ quốc tế)',
                    cs,
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    '2',
                    'Nhập thông tin thẻ hoặc quét mã QR',
                    cs,
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem('3', 'Xác nhận OTP từ ngân hàng', cs),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    '4',
                    'Quay lại ứng dụng sau khi thanh toán',
                    cs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _buildStatusSection(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLoading = false,
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isError
            ? cs.errorContainer.withValues(alpha: 0.3)
            : cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (isLoading)
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            )
          else
            Icon(icon, size: 48, color: isError ? cs.error : cs.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isError ? cs.error : cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// VNPay Payment Result Screen
///
/// Displayed after user returns from VNPay payment page.
class VNPayResultScreen extends StatefulWidget {
  const VNPayResultScreen({super.key, required this.queryParams});

  static const routeName = '/vnpay-result';

  final Map<String, String> queryParams;

  @override
  State<VNPayResultScreen> createState() => _VNPayResultScreenState();
}

class _VNPayResultScreenState extends State<VNPayResultScreen> {
  final VNPayService _vnpayService = VNPayService();
  late VNPayResult _result;
  bool _isUpdating = true;

  @override
  void initState() {
    super.initState();
    _processResult();
  }

  Future<void> _processResult() async {
    _result = _vnpayService.parseReturnUrl(widget.queryParams);

    if (_result.isSuccess) {
      // Update booking status in Firebase
      try {
        final bookingProvider = context.read<BookingProvider>();
        await bookingProvider.confirmVNPayPayment(
          bookingId: _result.txnRef,
          vnpTransactionNo: _result.transactionNo,
        );
      } catch (e) {
        // Error updating, but payment was successful
        debugPrint('Error updating booking: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        automaticallyImplyLeading: false,
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Result icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _result.isSuccess
                          ? Colors.green.withValues(alpha: 0.15)
                          : cs.errorContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _result.isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 56,
                      color: _result.isSuccess ? Colors.green : cs.error,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Result title
                  Text(
                    _result.isSuccess
                        ? 'Thanh toán thành công!'
                        : 'Thanh toán thất bại',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _result.isSuccess ? Colors.green : cs.error,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _result.statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Transaction details
                  if (_result.isSuccess) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Mã giao dịch',
                            _result.transactionNo,
                            cs,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Mã đơn hàng', _result.txnRef, cs),
                          const SizedBox(height: 12),
                          _buildDetailRow('Ngân hàng', _result.bankCode, cs),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Số tiền',
                            '${money.format(_result.amount / 100)}đ',
                            cs,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/my-bookings',
                          (route) => route.isFirst,
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Xem đơn đặt phòng'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Về trang chủ'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
      ],
    );
  }
}
