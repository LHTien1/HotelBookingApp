import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_providers.dart';
import '../../providers/theme_provider.dart';

class GeneralSettingsScreen extends StatefulWidget {
  static const routeName = '/settings-general';

  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  // prefs keys
  static const _kLang = 'settings_language_label';
  static const _kCurrency = 'settings_currency_label';
  static const _kNotiBooking = 'settings_noti_booking';
  static const _kNotiPromo = 'settings_noti_promo';

  String _languageLabel = 'Tiếng Việt';
  String _currencyLabel = 'VND (đ)';
  bool _bookingNoti = true;
  bool _promoNoti = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _languageLabel = prefs.getString(_kLang) ?? 'Tiếng Việt';
      _currencyLabel = prefs.getString(_kCurrency) ?? 'VND (đ)';
      _bookingNoti = prefs.getBool(_kNotiBooking) ?? true;
      _promoNoti = prefs.getBool(_kNotiPromo) ?? false;
    });
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Cài đặt chung', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          _sectionTitle('HIỂN THỊ'),
          _card(
            isDark: isDark,
            cs: cs,
            child: _themeSegment(context),
          ),

          const SizedBox(height: 14),
          _sectionTitle('TÙY CHỌN'),
          _card(
            isDark: isDark,
            cs: cs,
            child: Column(
              children: [
                _rowTile(
                  context,
                  icon: Icons.language_rounded,
                  title: 'Ngôn ngữ',
                  trailingText: _languageLabel,
                  onTap: () => _pickLanguage(context),
                ),
                _divider(cs),
                _rowTile(
                  context,
                  icon: Icons.currency_exchange_rounded,
                  title: 'Tiền tệ',
                  trailingText: _currencyLabel,
                  onTap: () => _pickCurrency(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          _sectionTitle('THÔNG BÁO'),
          _card(
            isDark: isDark,
            cs: cs,
            child: Column(
              children: [
                _switchTile(
                  context,
                  icon: Icons.notifications_active_rounded,
                  title: 'Thông báo đặt phòng',
                  value: _bookingNoti,
                  onChanged: (v) async {
                    setState(() => _bookingNoti = v);
                    await _saveBool(_kNotiBooking, v);
                  },
                ),
                _divider(cs),
                _switchTile(
                  context,
                  icon: Icons.campaign_rounded,
                  title: 'Tin tức & Khuyến mãi',
                  value: _promoNoti,
                  onChanged: (v) async {
                    setState(() => _promoNoti = v);
                    await _saveBool(_kNotiPromo, v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'Bật thông báo để không bỏ lỡ các ưu đãi độc quyền.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 14),
          _sectionTitle('KHÁC'),
          _card(
            isDark: isDark,
            cs: cs,
            child: Column(
              children: [
                _rowTile(
                  context,
                  icon: Icons.star_rate_rounded,
                  title: 'Đánh giá ứng dụng',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TODO: mở trang đánh giá app')),
                    );
                  },
                ),
                _divider(cs),
                _rowTile(
                  context,
                  icon: Icons.description_rounded,
                  title: 'Điều khoản sử dụng',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Điều khoản sử dụng'),
                      content: const Text('TODO: nội dung điều khoản...'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                      ],
                    ),
                  ),
                ),
                _divider(cs),
                _rowTile(
                  context,
                  icon: Icons.info_rounded,
                  title: 'Phiên bản',
                  trailingText: '1.0.2',
                  showChevron: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmLogout(context),
              child: Text(
                'Đăng xuất',
                style: TextStyle(color: cs.error, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Icon(Icons.hotel_rounded, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 8),
                Text(
                  '© 2024 Hotel Booking App',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Theme segmented (Sáng / Tối / Hệ thống) =====
  Widget _themeSegment(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    final activeRole = themeProvider.currentRole; // null = guest
    final selected = themeProvider.mode; // mode theo role hiện tại

    Widget item({
      required ThemeMode mode,
      required IconData icon,
      required String label,
    }) {
      final active = selected == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => themeProvider.setModeFor(activeRole, mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEAF2FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.35))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: active ? const Color(0xFF2F80ED) : cs.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: active ? const Color(0xFF2F80ED) : cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            item(mode: ThemeMode.light, icon: Icons.wb_sunny_rounded, label: 'Sáng'),
            const SizedBox(width: 8),
            item(mode: ThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'Tối'),
            const SizedBox(width: 8),
            item(mode: ThemeMode.system, icon: Icons.desktop_windows_rounded, label: 'Hệ thống'),
          ],
        ),
      ),
    );
  }

  // ===== Pickers (✅ FIX: không dùng context sau await) =====
  void _pickLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text('Chọn ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.w800)),
              onTap: () async {
                setState(() => _languageLabel = 'Tiếng Việt');

                // ✅ pop trước => không còn dùng context sau await
                Navigator.of(context).pop();

                await _saveString(_kLang, 'Tiếng Việt');
              },
            ),
            ListTile(
              title: const Text('English', style: TextStyle(fontWeight: FontWeight.w800)),
              onTap: () async {
                setState(() => _languageLabel = 'English');
                Navigator.of(context).pop();
                await _saveString(_kLang, 'English');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickCurrency(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text('Chọn tiền tệ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('VND (đ)', style: TextStyle(fontWeight: FontWeight.w800)),
              onTap: () async {
                setState(() => _currencyLabel = 'VND (đ)');
                Navigator.of(context).pop();
                await _saveString(_kCurrency, 'VND (đ)');
              },
            ),
            ListTile(
              title: const Text('USD (\$)', style: TextStyle(fontWeight: FontWeight.w800)),
              onTap: () async {
                setState(() => _currencyLabel = 'USD (\$)');
                Navigator.of(context).pop();
                await _saveString(_kCurrency, 'USD (\$)');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ===== Logout =====
  void _confirmLogout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut(context);
            },
            child: Text('Đăng xuất', style: TextStyle(color: cs.onError, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ===== UI helpers =====
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _card({
    required bool isDark,
    required ColorScheme cs,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: child,
    );
  }

  Widget _divider(ColorScheme cs) {
    return Divider(height: 1, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.35));
  }

  Widget _rowTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? trailingText,
        bool showChevron = true,
        VoidCallback? onTap,
      }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _leftIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.onSurface),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w800),
              ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.45)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _leftIcon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.onSurface),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _leftIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: const Color(0xFF2F80ED)),
    );
  }
}
