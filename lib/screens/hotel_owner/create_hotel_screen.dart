import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_providers.dart';
import '../../services/cloudinary_service.dart';

class CreateHotelScreen extends StatefulWidget {
  const CreateHotelScreen({super.key});

  @override
  State<CreateHotelScreen> createState() => _CreateHotelScreenState();
}

class _CreateHotelScreenState extends State<CreateHotelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amenityCtrl = TextEditingController();

  final List<CloudinaryBytesFile> _images = <CloudinaryBytesFile>[];
  final Set<String> _amenities = <String>{};

  static const List<String> _presetAmenities = <String>[
    'Wifi',
    'Bãi đỗ xe',
    'Bể bơi',
    'Bữa sáng',
    'Gym',
    'Lễ tân 24/7',
    'Điều hoà',
    'Thang máy',
    'Giặt ủi',
    'Dịch vụ phòng',
    'Cho phép thú cưng',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _amenityCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon,
      {String? hint, Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final converted = await Future.wait<CloudinaryBytesFile>(
      picked.map((x) async {
        final bytes = await x.readAsBytes();
        return CloudinaryBytesFile(
          bytes: bytes,
          fileName: x.name,
          mimeType: null,
        );
      }),
    );

    if (!mounted) return;
    setState(() => _images.addAll(converted));
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  void _toggleAmenity(String a) {
    setState(() {
      if (_amenities.contains(a)) {
        _amenities.remove(a);
      } else {
        _amenities.add(a);
      }
    });
  }

  void _addCustomAmenity() {
    final v = _amenityCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _amenities.add(v);
      _amenityCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập.')),
      );
      return;
    }

    final location = const GeoPoint(0, 0);

    final ok = await context.read<HotelProvider>().createHotel(
      ownerId: uid,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      location: location,
      amenities: _amenities.toList(),
      images: _images,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã tạo khách sạn (chờ duyệt).')),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<HotelProvider>().errorMessage ?? 'Tạo thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotelProvider>();
    final loading = provider.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Tạo khách sạn mới'),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(loading ? 'Đang lưu...' : 'Lưu khách sạn'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _SectionCard(
                title: 'Thông tin cơ bản',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _dec(
                        'Tên khách sạn',
                        Icons.apartment_rounded,
                        hint: 'Nhập tên khách sạn của bạn',
                      ),
                      validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nhập tên khách sạn' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: _dec(
                        'Địa chỉ',
                        Icons.location_on_rounded,
                        hint: 'Chọn hoặc nhập địa chỉ',
                        suffix: IconButton(
                          onPressed: null, // UI-only (giữ nguyên chức năng)
                          icon: const Icon(Icons.map_rounded),
                        ),
                      ),
                      validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nhập địa chỉ' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: _dec(
                        'Mô tả',
                        Icons.description_rounded,
                        hint: 'Mô tả chi tiết về không gian, vị trí, điểm nổi bật…',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _SectionCard(
                title: 'Hình ảnh khách sạn',
                trailing: Text(
                  'Tối đa 10 ảnh',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 92,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _AddImageTile(
                            onTap: loading ? null : _pickImages,
                          ),
                          const SizedBox(width: 10),
                          ...List.generate(_images.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _ThumbTileBytes(
                                bytes: _images[i].bytes,
                                onRemove: loading ? null : () => _removeImage(i),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _images.isEmpty
                          ? 'Hãy thêm ảnh để khách sạn trông hấp dẫn hơn.'
                          : 'Đã chọn ${_images.length} ảnh.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _SectionCard(
                title: 'Tiện nghi có sẵn',
                trailing: TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() {
                    if (_amenities.length == _presetAmenities.length) {
                      _amenities.clear();
                    } else {
                      _amenities.addAll(_presetAmenities);
                    }
                  }),
                  child: Text(
                    _amenities.length == _presetAmenities.length
                        ? 'Bỏ chọn'
                        : 'Chọn tất cả',
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetAmenities.map((a) {
                        final selected = _amenities.contains(a);
                        return FilterChip(
                          label: Text(a),
                          selected: selected,
                          onSelected: loading ? null : (_) => _toggleAmenity(a),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amenityCtrl,
                            decoration: _dec(
                              'Thêm tiện nghi khác (tuỳ chọn)',
                              Icons.add_circle_outline_rounded,
                              hint: 'Ví dụ: Xe đưa đón sân bay',
                            ),
                            onSubmitted: (_) => _addCustomAmenity(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: loading ? null : _addCustomAmenity,
                            child: const Text('Thêm'),
                          ),
                        )
                      ],
                    ),
                    if (_amenities.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _amenities.map((a) {
                          return Chip(
                            label: Text(a),
                            onDeleted: loading ? null : () => _toggleAmenity(a),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddImageTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: _DashedRRect(
        radius: 16,
        color: cs.outlineVariant.withValues(alpha: 0.7),
        child: SizedBox(
          width: 110,
          height: 80,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_a_photo_rounded, color: cs.primary),
                const SizedBox(height: 6),
                Text(
                  'Thêm ảnh',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbTileBytes extends StatelessWidget {
  final dynamic bytes;
  final VoidCallback? onRemove;

  const _ThumbTileBytes({required this.bytes, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            bytes,
            width: 110,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRRect extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;

  const _DashedRRect({
    required this.child,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(radius: radius, color: color),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final double radius;
  final Color color;

  _DashedRRectPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    const dash = 6.0;
    const gap = 4.0;

    for (final m in path.computeMetrics()) {
      double dist = 0;
      while (dist < m.length) {
        final len = (dist + dash < m.length) ? dash : (m.length - dist);
        final seg = m.extractPath(dist, dist + len);
        canvas.drawPath(seg, paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}
