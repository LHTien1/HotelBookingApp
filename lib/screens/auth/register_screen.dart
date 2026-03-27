import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final hoTenCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final sdtCtrl = TextEditingController();
  final matKhauCtrl = TextEditingController();
  final nhapLaiMatKhauCtrl = TextEditingController();

  bool anMatKhau1 = true;
  bool anMatKhau2 = true;

  // UI chỉ để chọn "muốn đăng ký dạng nào" (KHÔNG set role trực tiếp)
  UserRole vaiTroChon = UserRole.user;

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  void dispose() {
    hoTenCtrl.dispose();
    emailCtrl.dispose();
    sdtCtrl.dispose();
    matKhauCtrl.dispose();
    nhapLaiMatKhauCtrl.dispose();
    super.dispose();
  }

  void thongBao(String noiDung, {bool laLoi = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  Future<void> _guiYeuCauChuKhachSan({
    required String uid,
    required String email,
    required String name,
    String? phone,
  }) async {
    // Ghi đè doc theo uid để tránh spam nhiều requests
    await FirebaseFirestore.instance.collection('role_requests').doc(uid).set({
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'name': name.trim(),
      'phone': (phone ?? '').trim(),
      'type': 'hotelOwner',
      'status': 'pending', // pending | approved | rejected
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> dangKy() async {
    if (!formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final muonLamChuKS = (vaiTroChon == UserRole.hotelOwner);

    try {
      // ✅ LUÔN tạo tài khoản dưới dạng "Khách"
      await authProvider.signUp(
        email: emailCtrl.text.trim(),
        password: matKhauCtrl.text,
        name: hoTenCtrl.text.trim(),
        role: UserRole.user,
        phone: sdtCtrl.text.trim().isEmpty ? null : sdtCtrl.text.trim(),
      );

      // Sau signUp xong -> lấy uid để tạo request
      final createdUser = authProvider.currentUser;
      if (createdUser == null) {
        throw 'Không lấy được thông tin người dùng sau đăng ký.';
      }

      if (muonLamChuKS) {
        await _guiYeuCauChuKhachSan(
          uid: createdUser.uid,
          email: createdUser.email,
          name: createdUser.name,
          phone: createdUser.phone,
        );
      }

      if (!mounted) return;

      if (muonLamChuKS) {
        thongBao('✅ Đăng ký thành công! Đã gửi yêu cầu làm Chủ khách sạn (chờ admin duyệt).');
      } else {
        thongBao('✅ Đăng ký thành công!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      thongBao(authProvider.errorMessage ?? '❌ Đăng ký thất bại: $e', laLoi: true);
    }
  }

  InputDecoration _decoField({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade400),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blueGrey.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blueGrey.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dangTai = auth.isLoading;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bg-dp.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.30),
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.00),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'ĐĂNG KÝ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 22, 22, 18 + bottomInset),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Bắt đầu hành trình',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tạo tài khoản để trải nghiệm tốt nhất.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Bạn muốn đăng ký dạng nào?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lưu ý: “Chủ khách sạn” sẽ gửi yêu cầu để admin duyệt.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.blueGrey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                title: 'Khách',
                                icon: Icons.luggage_rounded,
                                selected: vaiTroChon == UserRole.user,
                                onTap: () => setState(() => vaiTroChon = UserRole.user),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _RoleCard(
                                title: 'Chủ khách sạn',
                                icon: Icons.apartment_rounded,
                                selected: vaiTroChon == UserRole.hotelOwner,
                                onTap: () => setState(() => vaiTroChon = UserRole.hotelOwner),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Họ và tên đầy đủ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: hoTenCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: _decoField(
                            hint: 'Nguyễn Văn A',
                            icon: Icons.person_rounded,
                          ),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return 'Vui lòng nhập họ và tên';
                            if (v.length < 2) return 'Họ và tên quá ngắn';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _decoField(
                            hint: 'email@example.com',
                            icon: Icons.mail_rounded,
                          ),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return 'Vui lòng nhập email';
                            if (!v.contains('@')) return 'Email không hợp lệ';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số điện thoại',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tùy chọn',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade400,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: sdtCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _decoField(
                            hint: '0909 123 456',
                            icon: Icons.phone_rounded,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Mật khẩu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: matKhauCtrl,
                          obscureText: anMatKhau1,
                          textInputAction: TextInputAction.next,
                          decoration: _decoField(
                            hint: '••••••••',
                            icon: Icons.lock_rounded,
                            suffix: IconButton(
                              onPressed: () => setState(() => anMatKhau1 = !anMatKhau1),
                              icon: Icon(
                                anMatKhau1
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
                            if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Xác nhận mật khẩu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nhapLaiMatKhauCtrl,
                          obscureText: anMatKhau2,
                          textInputAction: TextInputAction.done,
                          decoration: _decoField(
                            hint: '••••••••',
                            icon: Icons.lock_reset_rounded,
                            suffix: IconButton(
                              onPressed: () => setState(() => anMatKhau2 = !anMatKhau2),
                              icon: Icon(
                                anMatKhau2
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '') != matKhauCtrl.text) {
                              return 'Mật khẩu nhập lại không khớp';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: dangTai ? null : dangKy,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: _primaryBlue.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: dangTai
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.6),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Tạo tài khoản',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _RegisterScreenState._primaryBlue : const Color(0xFFE5EAF2);
    final bgColor = selected ? _RegisterScreenState._primaryBlue.withValues(alpha: 0.08) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 1.2),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: selected
                  ? Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: _RegisterScreenState._primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              )
                  : const SizedBox(width: 22, height: 22),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 34,
                    color: selected ? _RegisterScreenState._primaryBlue : Colors.blueGrey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: selected ? const Color(0xFF0F172A) : Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
