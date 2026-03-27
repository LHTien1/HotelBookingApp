// ✅ cần khi dùng ImageFilter/BackdropFilter

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../providers/auth_providers.dart';
import '../../providers/theme_provider.dart'; // giữ để set role null
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final matKhauCtrl = TextEditingController();

  bool anMatKhau = true;
  bool dangXuLy = false;

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();

    // ✅ trước đăng nhập = guest (role null)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeProvider>().setCurrentRole(null);
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    matKhauCtrl.dispose();
    super.dispose();
  }

  // ✅ NEW: nút quay lại
  void _quayLai() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      // nếu Login là màn đầu (không pop được) thì về intro
      nav.pushReplacementNamed('/intro');
    }
  }

  Future<void> luuNguoiDungFirestore(fb_auth.User user) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();

    final duLieuCoBan = <String, dynamic>{
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'avatarUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      await doc.set({
        ...duLieuCoBan,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } else {
      await doc.set(duLieuCoBan, SetOptions(merge: true));
    }
  }

  void hienThongBao(String noiDung, {bool laLoi = true}) {
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

  Future<void> diSauDangNhap() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> dangNhapBangEmail() async {
    if (dangXuLy) return;
    if (!formKey.currentState!.validate()) return;

    setState(() => dangXuLy = true);
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.signIn(
        email: emailCtrl.text.trim(),
        password: matKhauCtrl.text,
      );

      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) await luuNguoiDungFirestore(user);

      await diSauDangNhap();
    } catch (e) {
      hienThongBao(authProvider.errorMessage ?? 'Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => dangXuLy = false);
    }
  }

  Future<void> dangNhapBangGoogle() async {
    if (dangXuLy) return;
    setState(() => dangXuLy = true);

    try {
      fb_auth.UserCredential userCredential;

      if (kIsWeb) {
        final provider = fb_auth.GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});

        userCredential =
        await fb_auth.FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final credential = fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await fb_auth.FirebaseAuth.instance
            .signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) await luuNguoiDungFirestore(user);

      await diSauDangNhap();
    } catch (e) {
      hienThongBao('Lỗi đăng nhập Google: $e');
    } finally {
      if (mounted) setState(() => dangXuLy = false);
    }
  }

  Future<void> quenMatKhau() async {
    final emailHienTai = emailCtrl.text.trim();

    String? emailCanGui = emailHienTai;
    if (emailCanGui.isEmpty || !emailCanGui.contains('@')) {
      final nhapCtrl = TextEditingController(text: emailHienTai);

      emailCanGui = await showDialog<String>(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('Quên mật khẩu'),
            content: TextField(
              controller: nhapCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Nhập email của bạn'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, nhapCtrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                ),
                child: const Text('Gửi'),
              ),
            ],
          );
        },
      );
    }

    if (emailCanGui == null ||
        emailCanGui.isEmpty ||
        !emailCanGui.contains('@')) {
      return;
    }

    try {
      await fb_auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailCanGui);
      hienThongBao('✅ Đã gửi email đặt lại mật khẩu.', laLoi: false);
    } catch (e) {
      hienThongBao('Không thể gửi email: $e');
    }
  }

  // ================= UI helpers =================

  Widget _pillContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.22),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _pillDeco(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }

  Widget _blueButton({
    required String text,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _googleWhiteButton({
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.g_mobiledata, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Tiếp tục với Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final voHieuHoa = dangXuLy || authProvider.isLoading;

    final isDark = context.select<ThemeProvider, bool>((p) => p.isDark(context));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // overlay giống hình: trên nhẹ, dưới đậm
    final overlayTop = Colors.black.withValues(alpha: isDark ? 0.10 : 0.08);
    final overlayMid = Colors.black.withValues(alpha: isDark ? 0.45 : 0.40);
    final overlayBot = Colors.black.withValues(alpha: isDark ? 0.85 : 0.80);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // ✅ NỀN: dùng ảnh asset của bạn
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bg_hotel.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // ✅ overlay gradient
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [overlayTop, overlayMid, overlayBot],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(22, 14, 22, 14 + bottomInset),
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 18),

                                  // ===== Header logo + title =====
                                  Column(
                                    children: [
                                      Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.16),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.22),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 18,
                                              color: Colors.black.withValues(alpha: 0.22),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.flight_takeoff_rounded,
                                          size: 34,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Booking-P2TK',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 16,
                                              color: Colors.black38,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Đặt phòng mọi lúc, mọi nơi',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.70),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // ===== Welcome =====
                                  const Text(
                                    'Chào mừng bạn trở lại',
                                    style: TextStyle(
                                      fontSize: 30,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(blurRadius: 16, color: Colors.black38),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vui lòng đăng nhập để tiếp tục',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ===== Email =====
                                  _pillContainer(
                                    child: TextFormField(
                                      controller: emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _pillDeco('Email hoặc tên đăng nhập'),
                                      validator: (value) {
                                        final v = (value ?? '').trim();
                                        if (v.isEmpty) return 'Vui lòng nhập email';
                                        // NOTE: nếu bạn thật sự cho login bằng username,
                                        // hãy bỏ check '@' hoặc viết logic map username -> email.
                                        if (!v.contains('@')) return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // ===== Password =====
                                  _pillContainer(
                                    child: TextFormField(
                                      controller: matKhauCtrl,
                                      obscureText: anMatKhau,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        if (!voHieuHoa) dangNhapBangEmail();
                                      },
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _pillDeco(
                                        'Mật khẩu',
                                        suffixIcon: IconButton(
                                          onPressed: () =>
                                              setState(() => anMatKhau = !anMatKhau),
                                          icon: Icon(
                                            anMatKhau
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.black.withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        final v = value ?? '';
                                        if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
                                        if (v.length < 6) {
                                          return 'Mật khẩu tối thiểu 6 ký tự';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // ===== Forgot =====
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: voHieuHoa ? null : quenMatKhau,
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.78),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ===== Login =====
                                  _blueButton(
                                    text: 'Đăng nhập',
                                    onPressed: voHieuHoa ? null : dangNhapBangEmail,
                                    loading: voHieuHoa,
                                  ),

                                  const SizedBox(height: 10),

                                  // ===== Or =====
                                  Center(
                                    child: Text(
                                      'Hoặc',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ===== Google =====
                                  _googleWhiteButton(
                                    onPressed: voHieuHoa ? null : dangNhapBangGoogle,
                                    loading: false, // loading chung là voHieuHoa
                                  ),

                                  const SizedBox(height: 14),

                                  // ===== Register row =====
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Chưa có tài khoản? ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.72),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Đăng ký',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: _primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ✅ NÚT QUAY LẠI (góc trái)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _quayLai,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
