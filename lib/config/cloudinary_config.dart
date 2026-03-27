/// Cloudinary config (KHÔNG để api_secret ở client!)
/// Chỉ dùng cloudName + uploadPreset (Unsigned preset).
class CloudinaryConfig {
  static const String cloudName = 'dyfn1lam8'; // ✅ đúng (có chữ l)
  static const String uploadPreset = 'hotel_unsigned';

  // Folder mặc định (bạn có thể override khi gọi upload)
  static const String defaultFolder = 'hotel_rooms';
}
