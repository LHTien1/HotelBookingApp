import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/cloudinary_config.dart';

class CloudinaryBytesFile {
  final Uint8List bytes;
  final String fileName; // ví dụ: "img_001.jpg"
  final String? mimeType; // ví dụ: "image/jpeg"

  const CloudinaryBytesFile({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });
}

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;

  CloudinaryService({
    String? cloudName,
    String? uploadPreset,
  })  : cloudName = cloudName ?? CloudinaryConfig.cloudName,
        uploadPreset = uploadPreset ?? CloudinaryConfig.uploadPreset;

  Uri _uploadUri({String resourceType = 'image'}) =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

  /// Upload 1 file (bytes) lên Cloudinary và trả về secure_url
  Future<String> uploadBytes(
      Uint8List bytes, {
        required String fileName,
        String? mimeType, // "image/jpeg", "image/png", ...
        String? folder,
        String resourceType = 'image',
      }) async {
    final req = http.MultipartRequest(
      'POST',
      _uploadUri(resourceType: resourceType),
    )
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder ?? CloudinaryConfig.defaultFolder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: (mimeType != null && mimeType.trim().isNotEmpty)
              ? MediaType.parse(mimeType)
              : null,
        ),
      );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        throw const FormatException();
      }
    } catch (_) {
      throw Exception('Cloudinary: response không hợp lệ (không parse được JSON)');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final url = data['secure_url'];
      if (url is String && url.isNotEmpty) return url;
      throw Exception('Cloudinary: thiếu secure_url');
    }

    final msg = (data['error'] is Map)
        ? ((data['error'] as Map)['message']?.toString() ?? 'Upload failed')
        : 'Upload failed';
    throw Exception('Cloudinary: $msg');
  }

  /// ✅ NEW: Upload 1 file theo kiểu CloudinaryBytesFile (để HotelService gọi)
  Future<String> uploadBytesFile(
      CloudinaryBytesFile file, {
        String? folder,
        String resourceType = 'image',
      }) {
    return uploadBytes(
      file.bytes,
      fileName: file.fileName,
      mimeType: file.mimeType,
      folder: folder,
      resourceType: resourceType,
    );
  }

  /// Upload nhiều file (bytes) và trả về list secure_url
  /// (typed rõ ràng để không ra List<dynamic>)
  Future<List<String>> uploadManyBytes(
      List<CloudinaryBytesFile> files, {
        String? folder,
        String resourceType = 'image',
      }) async {
    if (files.isEmpty) return <String>[];

    // Song song (nhanh hơn). Nếu bạn sợ rate-limit thì đổi về for-loop như cũ.
    final urls = await Future.wait<String>(
      files.map(
            (f) => uploadBytesFile(
          f,
          folder: folder,
          resourceType: resourceType,
        ),
      ),
    );

    return urls;
  }
}
