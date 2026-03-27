import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/services/momo_service.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Momo Payment Screen
class MomoPaymentScreen extends StatefulWidget {
  const MomoPaymentScreen({
    super.key,
    required this.bookingId,
    required this.room,
    required this.totalAmount,
    required this.checkInDate,
    required this.checkOutDate,
  });

  static const routeName = '/momo-payment';

  final String bookingId;
  final RoomModel room;
  final double totalAmount;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  @override
  State<MomoPaymentScreen> createState() => _MomoPaymentScreenState();
}

class _MomoPaymentScreenState extends State<MomoPaymentScreen> {
  final MomoService _momoService = MomoService();
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

      // 1. Get payment URL from Momo API
      final paymentUrl = await _momoService.createPayment(
        bookingId: widget.bookingId,
        amount: widget.totalAmount,
        orderInfo: orderInfo,
      );

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Không nhận được link thanh toán từ Momo');
      }

      final uri = Uri.parse(paymentUrl);

      // 2. Launch URL in external browser/app
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không thể mở ứng dụng Momo hoặc trình duyệt');
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
        title: const Text('Thanh toán Momo'),
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
                          color: const Color(
                            0xFFA50064,
                          ).withValues(alpha: 0.1), // Momo color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFFA50064),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thanh toán qua Momo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ví điện tử an toàn, tiện lợi',
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
                          color: const Color(0xFFA50064), // Momo Color
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
                title: 'Đang mở Momo...',
                subtitle: 'Vui lòng hoàn tất thanh toán trên Momo',
                isLoading: true,
              ),

            if (_errorMessage != null)
              _buildStatusSection(
                cs,
                icon: Icons.error_outline,
                title: 'Lỗi khởi tạo',
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
                  backgroundColor: const Color(0xFFA50064),
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

            // Web Testing Debug Button
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                // Manually trigger success for Web Testing
                setState(() => _isProcessing = true);
                try {
                  await context.read<BookingProvider>().confirmMomoPayment(
                    bookingId: widget.bookingId,
                  );
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/my-bookings',
                      (route) => route.isFirst,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xác nhận thanh toán (Thủ công)'),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _errorMessage = e.toString());
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              label: const Text(
                'Đã thanh toán xong (Dùng cho Web)',
                style: TextStyle(color: Colors.green),
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
            : const Color(0xFFA50064).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFA50064),
              ),
            )
          else
            Icon(
              icon,
              size: 48,
              color: isError ? cs.error : const Color(0xFFA50064),
            ),
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
}

/// Momo Payment Result Screen
class MomoResultScreen extends StatefulWidget {
  const MomoResultScreen({super.key, required this.queryParams});

  static const routeName = '/momo-result';

  final Map<String, String> queryParams;

  @override
  State<MomoResultScreen> createState() => _MomoResultScreenState();
}

class _MomoResultScreenState extends State<MomoResultScreen> {
  bool _isSuccess = false;
  bool _isUpdating = true;
  String _message = 'Đang xử lý...';
  String _orderId = '';
  String _amount = '0';

  @override
  void initState() {
    super.initState();
    _processResult();
  }

  Future<void> _processResult() async {
    try {
      debugPrint('Momo Result Params: ${widget.queryParams}');

      // Momo return params (Sandbox):
      // partnerCode, orderId, requestId, amount, orderInfo, orderType, transId, resultCode, message, payType, responseTime, extraData, signature

      final resultCode = widget.queryParams['resultCode'];
      final message = widget.queryParams['message'] ?? 'Kết quả không xác định';
      _orderId = widget.queryParams['orderId'] ?? '';
      _amount = widget.queryParams['amount'] ?? '0';

      debugPrint('Momo Result Code: $resultCode');

      if (resultCode == '0') {
        _isSuccess = true;
        _message = 'Giao dịch thành công';

        // Update Firebase
        if (_orderId.isNotEmpty) {
          try {
            debugPrint('Updating booking $_orderId...');
            await context.read<BookingProvider>().confirmMomoPayment(
              bookingId: _orderId,
            );
            debugPrint('Booking updated successfully');
          } catch (e) {
            debugPrint('Error updating booking: $e');
            _message = 'Thanh toán thành công nhưng lỗi cập nhật đơn: $e';
          }
        }
      } else {
        _isSuccess = false;
        _message = message;
        if (resultCode == '1006')
          _message = 'Giao dịch bị từ chối bởi người dùng';
      }
    } catch (e) {
      debugPrint('Unexpected error in _processResult: $e');
      _isSuccess = false;
      _message = 'Lỗi xử lý kết quả: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
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

                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? Colors.green.withValues(alpha: 0.15)
                          : cs.errorContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 56,
                      color: _isSuccess ? Colors.green : cs.error,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    _isSuccess
                        ? 'Thanh toán thành công!'
                        : 'Thanh toán thất bại',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _isSuccess ? Colors.green : cs.error,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_isSuccess) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Mã đơn hàng', _orderId, cs),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Số tiền',
                            '${money.format(double.tryParse(_amount) ?? 0)}đ',
                            cs,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Phương thức', 'Momo Wallet', cs),
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
