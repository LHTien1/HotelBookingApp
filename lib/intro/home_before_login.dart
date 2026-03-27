import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:booking_app/providers/theme_provider.dart'; // ✅ NEW
import 'package:booking_app/screens/auth/login_screen.dart';
import 'package:booking_app/screens/auth/register_screen.dart';

class HomeBeforeLogin extends StatefulWidget {
  const HomeBeforeLogin({super.key});

  @override
  State<HomeBeforeLogin> createState() => _HomeBeforeLoginState();
}

class _HomeBeforeLoginState extends State<HomeBeforeLogin> {
  final PageController _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardData(
      image: "assets/images/bb_anh1.png",
      title: "Sang trọng & thoải mái,\nchỉ một chạm là tới",
      desc:
      "Tìm khách sạn phù hợp và đặt phòng nhanh chóng. Tận hưởng trải nghiệm nghỉ dưỡng trọn vẹn cho mọi chuyến đi.",
      button: "Tiếp tục",
      showRegister: false,
    ),
    _OnboardData(
      image: "assets/images/bb_anh2.png",
      title: "Đặt phòng dễ dàng,\nnghỉ dưỡng phong cách",
      desc:
      "So sánh giá, xem tiện ích và chọn phòng yêu thích chỉ trong vài bước. Nhanh gọn, rõ ràng, tiện lợi.",
      button: "Tiếp tục",
      showRegister: false,
    ),
    _OnboardData(
      image: "assets/images/bb_anh3.png",
      title: "Khám phá khách sạn mơ ước,\nthật dễ dàng",
      desc:
      "Hàng ngàn lựa chọn và ưu đãi hấp dẫn đang chờ bạn. Bắt đầu ngay để lên kế hoạch cho chuyến đi.",
      button: "Bắt đầu",
      showRegister: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: _pages.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final p = _pages[i];
          return _OnboardPage(
            data: p,
            pageIndex: i,
            currentIndex: _index,
            total: _pages.length,
            onNext: _next,
          );
        },
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  final int pageIndex;
  final int currentIndex;
  final int total;
  final VoidCallback onNext;

  const _OnboardPage({
    required this.data,
    required this.pageIndex,
    required this.currentIndex,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.read<ThemeProvider>();

    // Màu chủ đạo (bạn đang dùng xanh này)
    const primaryBlue = Color(0xFF2F64D6);

    // Text màu theo theme
    final titleColor = isDark ? Colors.white : Colors.black87;
    final descColor = isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black54;

    // Overlay theo theme (dark: đen, light: trắng)
    final overlayColors = isDark
        ? [
      Colors.black.withValues(alpha: 0.85),
      Colors.black.withValues(alpha: 0.40),
      Colors.transparent,
    ]
        : [
      Colors.white.withValues(alpha: 0.90),
      Colors.white.withValues(alpha: 0.55),
      Colors.transparent,
    ];

    final inactiveDot = isDark ? Colors.white54 : Colors.black26;

    return Stack(
      children: [
        // Ảnh nền
        Positioned.fill(
          child: Image.asset(
            data.image,
            fit: BoxFit.cover,
          ),
        ),

        // Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: overlayColors,
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // ✅ Nút đổi sáng/tối (góc phải trên)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,        // <-- bool chuẩn
                        color: titleColor,
                      ),
                      onPressed: () => themeProvider.toggle(context),       // <-- truyền context
                      tooltip: 'Đổi sáng/tối',
                    ),
                  ),
                ),

                const Spacer(),

                // Title
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    shadows: isDark
                        ? const [Shadow(color: Colors.black, blurRadius: 12)]
                        : const [Shadow(color: Colors.white, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 10),

                // Desc
                Text(
                  data.desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: descColor,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final active = i == currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: active ? 18 : 6,
                      decoration: BoxDecoration(
                        color: active ? primaryBlue : inactiveDot,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      data.button,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Register line (chỉ trang cuối)
                if (data.showRegister) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Chưa có tài khoản? ",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.black.withValues(alpha: 0.75),
                          fontSize: 12.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Đăng ký",
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardData {
  final String image;
  final String title;
  final String desc;
  final String button;
  final bool showRegister;

  const _OnboardData({
    required this.image,
    required this.title,
    required this.desc,
    required this.button,
    required this.showRegister,
  });
}
