import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hoTenCtrl;
  late final TextEditingController _soDienThoaiCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _hoTenCtrl = TextEditingController(text: (user?.name ?? '').trim());
    _soDienThoaiCtrl = TextEditingController(text: (user?.phone ?? '').trim());
  }

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _soDienThoaiCtrl.dispose();
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

  Future<void> _luuThongTin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    try {
      await auth.updateProfile(
        name: _hoTenCtrl.text.trim(),
        phone: _soDienThoaiCtrl.text.trim(),
      );

      if (!mounted) return;
      _thongBao('Đã cập nhật hồ sơ thành công!');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _thongBao(
        auth.errorMessage ?? 'Không thể cập nhật hồ sơ. Vui lòng thử lại.',
        laLoi: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, p, _) => AppBottomPrimaryButton(
          text: 'Lưu thay đổi',
          isLoading: p.isLoading,
          onPressed: p.isLoading ? null : _luuThongTin,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Avatar (UI giống ảnh, chưa đổi chức năng upload avatar)
              Stack(
                children: [
                  CircleAvatar(
                    radius: 62,
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: cs.surface,
                      child: Icon(Icons.person, size: 62, color: cs.onSurfaceVariant),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: InkWell(
                      onTap: () => _thongBao('Chức năng đổi ảnh đại diện: bạn có thể thêm sau.'),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 3),
                        ),
                        child: Icon(Icons.photo_camera, color: cs.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Đổi ảnh đại diện',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _hoTenCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return 'Vui lòng nhập họ và tên';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _soDienThoaiCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _luuThongTin(),
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại (Tùy chọn)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text(
                'Thông tin liên hệ này sẽ được sử dụng để tự động điền vào các đơn đặt phòng của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
