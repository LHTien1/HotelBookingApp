import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../config/vnpay_config.dart';

class VNPayService {
  /// Generate VNPay payment URL
  ///
  /// [bookingId] - Unique booking/transaction reference
  /// [amount] - Payment amount in VND
  /// [orderInfo] - Order description (Vietnamese without accents)
  /// [ipAddress] - Client IP address
  ///
  String generatePaymentUrl({
    required String bookingId,
    required double amount,
    required String orderInfo,
    String ipAddress = '127.0.0.1',
  }) {
    final now = DateTime.now();
    final createDate = DateFormat('yyyyMMddHHmmss').format(now);
    final expireDate = DateFormat(
      'yyyyMMddHHmmss',
    ).format(now.add(Duration(minutes: VNPayConfig.paymentExpiryMinutes)));

    final vnpAmount = (amount * 100).toInt().toString();

    // Build parameters map
    final Map<String, String> vnpParams = {
      'vnp_Version': VNPayConfig.vnpVersion,
      'vnp_Command': VNPayConfig.vnpCommand,
      'vnp_TmnCode': VNPayConfig.vnpTmnCode,
      'vnp_Amount': vnpAmount,
      'vnp_CurrCode': VNPayConfig.vnpCurrCode,
      'vnp_TxnRef': bookingId,
      'vnp_OrderInfo': _sanitizeOrderInfo(orderInfo),
      'vnp_OrderType': VNPayConfig.vnpOrderType,
      'vnp_Locale': VNPayConfig.vnpLocale,
      'vnp_ReturnUrl': VNPayConfig.vnpReturnUrl,
      'vnp_IpAddr': ipAddress,
      'vnp_CreateDate': createDate,
      'vnp_ExpireDate': expireDate,
    };

    // Sort parameters by key (ascending)
    final sortedKeys = vnpParams.keys.toList()..sort();

    // Build hash data (raw values, not encoded) and query string (encoded)
    final hashParts = <String>[];
    final queryParts = <String>[];

    for (final key in sortedKeys) {
      final value = vnpParams[key]!;
      // Hash uses raw key=value
      hashParts.add('$key=$value');
      // Query string uses encoded
      queryParts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }

    final hashData = hashParts.join('&');
    final queryString = queryParts.join('&');

    // Generate HMAC-SHA512 secure hash
    final secureHash = _generateSecureHash(hashData);

    // Build final URL
    return '${VNPayConfig.vnpUrl}?$queryString&vnp_SecureHash=$secureHash';
  }

  /// Verify VNPay return URL checksum
  ///
  /// [queryParams] - Map of query parameters from return URL
  ///
  /// Returns true if checksum is valid
  bool verifyReturnUrl(Map<String, String> queryParams) {
    final receivedHash = queryParams['vnp_SecureHash'] ?? '';

    if (receivedHash.isEmpty) return false;

    // Remove hash and hash type from params
    final params = Map<String, String>.from(queryParams);
    params.remove('vnp_SecureHash');
    params.remove('vnp_SecureHashType');

    // Sort and build hash data
    final sortedKeys = params.keys.toList()..sort();
    final hashParts = <String>[];

    for (final key in sortedKeys) {
      final value = params[key] ?? '';
      if (value.isNotEmpty) {
        hashParts.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    }

    final hashData = hashParts.join('&');
    final calculatedHash = _generateSecureHash(hashData);

    return calculatedHash.toLowerCase() == receivedHash.toLowerCase();
  }

  /// Parse VNPay response and extract payment result
  ///
  /// [queryParams] - Map of query parameters from return URL
  ///
  /// Returns VNPayResult with payment details
  VNPayResult parseReturnUrl(Map<String, String> queryParams) {
    final isValid = verifyReturnUrl(queryParams);

    return VNPayResult(
      isValid: isValid,
      responseCode: queryParams['vnp_ResponseCode'] ?? '',
      transactionNo: queryParams['vnp_TransactionNo'] ?? '',
      txnRef: queryParams['vnp_TxnRef'] ?? '',
      amount: double.tryParse(queryParams['vnp_Amount'] ?? '0') ?? 0 / 100,
      bankCode: queryParams['vnp_BankCode'] ?? '',
      payDate: queryParams['vnp_PayDate'] ?? '',
      orderInfo: queryParams['vnp_OrderInfo'] ?? '',
      transactionStatus: queryParams['vnp_TransactionStatus'] ?? '',
    );
  }

  /// Generate HMAC-SHA512 hash
  String _generateSecureHash(String data) {
    final key = utf8.encode(VNPayConfig.vnpHashSecret);
    final bytes = utf8.encode(data);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(bytes);
    return digest.toString();
  }

  /// Sanitize order info for VNPay (Vietnamese without accents, no special chars)
  String _sanitizeOrderInfo(String input) {
    // Replace Vietnamese accents
    const vietnamese =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const nonVietnamese =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    String result = input;
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], nonVietnamese[i]);
    }

    // Remove special characters, keep alphanumeric and spaces
    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

/// VNPay Payment Result
class VNPayResult {
  final bool isValid;
  final String responseCode;
  final String transactionNo;
  final String txnRef;
  final double amount;
  final String bankCode;
  final String payDate;
  final String orderInfo;
  final String transactionStatus;

  VNPayResult({
    required this.isValid,
    required this.responseCode,
    required this.transactionNo,
    required this.txnRef,
    required this.amount,
    required this.bankCode,
    required this.payDate,
    required this.orderInfo,
    required this.transactionStatus,
  });

  /// Check if payment was successful
  bool get isSuccess =>
      isValid && responseCode == '00' && transactionStatus == '00';

  /// Get human-readable status message
  String get statusMessage {
    if (!isValid) return 'Chữ ký không hợp lệ';

    switch (responseCode) {
      case '00':
        return 'Giao dịch thành công';
      case '07':
        return 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường)';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking';
      case '10':
        return 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần';
      case '11':
        return 'Đã hết hạn chờ thanh toán';
      case '12':
        return 'Thẻ/Tài khoản bị khóa';
      case '13':
        return 'Nhập sai mật khẩu xác thực giao dịch (OTP)';
      case '24':
        return 'Khách hàng hủy giao dịch';
      case '51':
        return 'Tài khoản không đủ số dư';
      case '65':
        return 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì';
      case '79':
        return 'Nhập sai mật khẩu thanh toán quá số lần quy định';
      case '99':
        return 'Lỗi không xác định';
      default:
        return 'Giao dịch thất bại (Mã lỗi: $responseCode)';
    }
  }
}
