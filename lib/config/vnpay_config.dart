/// VNPay Payment Gateway Configuration
///
/// Đăng ký lấy credentials tại: http://sandbox.vnpayment.vn/devreg/
/// Sau khi đăng ký, thay thế vnpTmnCode và vnpHashSecret bằng giá trị thực.
class VNPayConfig {
  // ── Sandbox Environment ──────────────────────────────────────────────────
  static const String vnpUrl =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

  static const String vnpTmnCode = 'HVSBMH97';
  static const String vnpHashSecret = 'PFPZ876M5WLQZ1OCJTC3N45BV2EZRH3F';

  static const String vnpVersion = '2.1.0';
  static const String vnpCommand = 'pay';
  static const String vnpCurrCode = 'VND';
  static const String vnpLocale = 'vn';
  static const String vnpOrderType = 'other';

  static const String vnpReturnUrl = 'https://sandbox.vnpayment.vn';

  static const int paymentExpiryMinutes = 15;
}
