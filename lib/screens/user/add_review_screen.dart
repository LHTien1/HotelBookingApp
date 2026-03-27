import 'dart:typed_data';

import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({
    super.key,
    required this.roomId,
    required this.hotelId,
    this.hotelName,
    this.roomLabel,
    this.stayNights,
    this.thumbnailUrl,
  });

  static const routeName = '/add-review';

  final String roomId;
  final String hotelId;

  // UI-only
  final String? hotelName;
  final String? roomLabel;
  final int? stayNights;
  final String? thumbnailUrl;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _binhLuanCtrl = TextEditingController();

  double _soSao = 4.0;
  final Set<String> _highlights = <String>{};
  final List<Uint8List> _photos = [];

  static const _presetHighlights = <String>[
    'Sạch sẽ',
    'Dịch vụ',
    'Vị trí',
    'Tiện nghi',
  ];

  @override
  void dispose() {
    _binhLuanCtrl.dispose();
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

  String _labelFromStars(double v) {
    final s = v.round();
    if (s >= 5) return 'Tuyệt vời';
    if (s == 4) return 'Rất tốt';
    if (s == 3) return 'Tốt';
    if (s == 2) return 'Tạm ổn';
    return 'Chưa hài lòng';
  }

  Future<void> _pickPhotos() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;

      for (final f in files) {
        if (_photos.length >= 5) break;
        final bytes = await f.readAsBytes();
        _photos.add(bytes);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      _thongBao('Không thể chọn ảnh. Vui lòng thử lại.', laLoi: true);
    }
  }

  Future<void> _guiDanhGia() async {
    FocusScope.of(context).unfocus();

    if (_soSao < 1) {
      _thongBao('Vui lòng chọn số sao (tối thiểu 1 sao).', laLoi: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final hotelProvider = context.read<HotelProvider>();
    try {
      await hotelProvider.addReview(
        roomId: widget.roomId,
        hotelId: widget.hotelId,
        rating: _soSao,
        comment: _binhLuanCtrl.text.trim(),
      );

      if (!mounted) return;
      _thongBao('Cảm ơn bạn đã đánh giá!');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _thongBao(
        hotelProvider.errorMessage ?? 'Không thể gửi đánh giá. Vui lòng thử lại.',
        laLoi: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hotelText = (widget.hotelName ?? '').trim().isNotEmpty
        ? widget.hotelName!.trim()
        : 'Khách sạn';
    final roomText = (widget.roomLabel ?? '').trim().isNotEmpty
        ? widget.roomLabel!.trim()
        : 'Phòng';
    final nights = widget.stayNights;

    return Scaffold(
      appBar: AppBar(title: const Text('Viết đánh giá')),
      bottomNavigationBar: Consumer<HotelProvider>(
        builder: (context, p, _) => AppBottomPrimaryButton(
          text: 'Gửi đánh giá',
          isLoading: p.isLoading,
          onPressed: p.isLoading ? null : _guiDanhGia,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: (widget.thumbnailUrl ?? '').trim().isNotEmpty
                            ? Image.network(
                          widget.thumbnailUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _thumbFallback(cs),
                        )
                            : _thumbFallback(cs),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotelText,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16.5,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nights == null
                                ? roomText
                                : '$roomText - $nights đêm',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Bạn cảm thấy kỳ nghỉ thế nào?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final active = i < _soSao.round();
                    return IconButton(
                      onPressed: () => setState(() => _soSao = (i + 1).toDouble()),
                      icon: Icon(
                        active ? Icons.star : Icons.star_border,
                        color: active ? Colors.amber : cs.outlineVariant,
                        size: 44,
                      ),
                      tooltip: 'Chọn ${i + 1} sao',
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _labelFromStars(_soSao),
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Điều gì nổi bật nhất?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _presetHighlights.map((t) {
                  final selected = _highlights.contains(t);
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      t,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    selectedColor: cs.primary.withValues(alpha: 0.12),
                    backgroundColor: cs.surface,
                    side: BorderSide(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.6)
                          : cs.outlineVariant.withValues(alpha: 0.55),
                    ),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _highlights.add(t);
                        } else {
                          _highlights.remove(t);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              Text(
                'Chi tiết đánh giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _binhLuanCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                  'Hãy chia sẻ trải nghiệm của bạn... Bạn thích (hoặc không thích) điều gì về khách sạn này?',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Vui lòng nhập bình luận';
                  if (s.length < 5) return 'Bình luận quá ngắn (tối thiểu 5 ký tự).';
                  return null;
                },
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '(Tùy chọn)',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppAddPhotoTile(onTap: _pickPhotos),
                  ..._photos.asMap().entries.map((e) {
                    return AppImageThumb(
                      bytes: e.value,
                      onRemove: () => setState(() => _photos.removeAt(e.key)),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Icon(Icons.photo, color: cs.onSurfaceVariant, size: 28),
    );
  }
}
