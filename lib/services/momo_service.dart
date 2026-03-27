import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/momo_config.dart';

class MomoService {
  /// Create Momo Payment Request
  /// Returns the deepLink (or payUrl) to open in browser/app
  Future<String?> createPayment({
    required String bookingId,
    required double amount,
    required String orderInfo,
  }) async {
    try {
      final requestId = const Uuid().v4();
      final orderId = bookingId; // Use bookingId as orderId for simplicity
      // requestType: captureWallet (QR/App), payWithATM (Local Card), payWithCC (Credit Card)
      // requestType: captureWallet (QR/App), payWithATM (Local Card), payWithCC (Credit Card)
      final requestType = 'payWithCC';
      final notifyUrl = MomoConfig.notifyUrl;
      final returnUrl = MomoConfig.returnUrl;
      final amountStr = amount.toInt().toString();

      // Raw signature string format:
      // accessKey=$accessKey&amount=$amount&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType
      final rawSignature =
          'accessKey=${MomoConfig.accessKey}'
          '&amount=$amountStr'
          '&extraData='
          '&ipnUrl=$notifyUrl'
          '&orderId=$orderId'
          '&orderInfo=$orderInfo'
          '&partnerCode=${MomoConfig.partnerCode}'
          '&redirectUrl=$returnUrl'
          '&requestId=$requestId'
          '&requestType=$requestType';

      // HMAC SHA256 Signature
      final signature = _generateHmacSha256(rawSignature, MomoConfig.secretKey);

      final body = {
        'partnerCode': MomoConfig.partnerCode,
        'partnerName': 'Test Hotel App',
        'storeId': 'MomoTestStore',
        'requestId': requestId,
        'amount': amountStr,
        'orderId': orderId,
        'orderInfo': orderInfo,
        'redirectUrl': returnUrl,
        'ipnUrl': notifyUrl,
        'lang': 'vi',
        'extraData': '',
        'requestType': requestType,
        'signature': signature,
      };

      final response = await http.post(
        Uri.parse(MomoConfig.paymentUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['resultCode'] == 0) {
        // 'payUrl' is the web payment link
        // 'deeplink' is for opening Momo app directly (if installed)
        // We will prefer payUrl for this implementation to ensure it works on emulator/web
        return data['payUrl'];
      } else {
        throw Exception(
          'Momo Error: ${data['message']} (Code: ${data['resultCode']})',
        );
      }
    } catch (e) {
      throw Exception('Failed to create Momo payment: $e');
    }
  }

  String _generateHmacSha256(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }
}
