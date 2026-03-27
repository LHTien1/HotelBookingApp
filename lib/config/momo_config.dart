/// Momo Payment Configuration
///
/// Đăng ký credentials tại: https://business.momo.vn/
class MomoConfig {
  // Credentials (Momo Official Sandbox)
  static const String partnerCode = 'MOMO';
  static const String accessKey = 'F8BBA842ECF85';
  static const String secretKey = 'K951B6PE1waDMi640xX08PD3vg6EkVlz';

  // Endpoint Sandbox
  static const String paymentUrl =
      'https://test-payment.momo.vn/v2/gateway/api/create';

  // App Return URL
  static const String returnUrl = 'bookingapp://momo/return';
  static const String notifyUrl = 'https://momo.vn'; // Dummy notify for sandbox
}
