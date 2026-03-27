import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/cloudinary_service.dart';

/// ✅ Formatter tiền VND có dấu chấm: 1200000 -> 1.200.000
class VndInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat.decimalPattern('vi');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final n = int.tryParse(digits) ?? 0;
    final formatted = _fmt.format(n);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PostRoomScreen extends StatefulWidget {
  final String hotelId;
  final String? hotelName;
  final RoomModel? room;

  const PostRoomScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
    this.room,
  });

  @override
  State<PostRoomScreen> createState() => _PostRoomScreenState();
}

class _PostRoomScreenState extends State<PostRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _roomNumberCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _areaCtrl; // ✅ NEW: diện tích
  late final TextEditingController _maxGuestsCtrl;
  late final TextEditingController _descCtrl;

  final TextEditingController _amenityCtrl = TextEditingController();

  final List<CloudinaryBytesFile> _newImages = <CloudinaryBytesFile>[];
  final List<String> _imageUrls = <String>[];
  final Set<String> _amenities = <String>{};

  bool _submitting = false;
  int _maxGuests = 1;

  static const List<String> _presetAmenities = <String>[
    'Wifi',
    'Điều hòa',
    'TV',
    'Tủ lạnh',
    'Nước nóng',
    'Ban công',
    'Bồn tắm',
    'Máy sấy tóc',
    'Bàn làm việc',
  ];

  bool get _isEdit => widget.room != null;

  // ===== helper đọc area an toàn (tránh lỗi nếu RoomModel chưa có field) =====
  double? _readArea(RoomModel r) {
    try {
      final v = (r as dynamic).area;
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    } catch (_) {}

    try {
      final v = (r as dynamic).squareMeters;
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    } catch (_) {}

    return null;
  }

  String _formatAreaText(double? v) {
    if (v == null) return '';
    final s = v.toString();
    return s.replaceAll(RegExp(r'\.0$'), '');
  }

  @override
  void initState() {
    super.initState();

    final r = widget.room;

    _roomNumberCtrl = TextEditingController(text: r?.roomNumber ?? '');
    _typeCtrl = TextEditingController(text: (r?.type ?? '').trim());

    // ✅ Giá hiển thị theo chuẩn vi (có dấu chấm)
    final priceText = (r == null || r.price == 0)
        ? ''
        : NumberFormat.decimalPattern('vi').format(r.price.round());
    _priceCtrl = TextEditingController(text: priceText);

    // ✅ NEW: diện tích (m²)
    final area = r == null ? null : _readArea(r);
    _areaCtrl = TextEditingController(text: _formatAreaText(area));

    _maxGuests = r == null ? 1 : r.maxGuests;
    _maxGuestsCtrl = TextEditingController(text: _maxGuests.toString());
    _descCtrl = TextEditingController(text: r?.description ?? '');

    if (r != null) {
      _amenities.addAll(r.amenities);
      _imageUrls.addAll(r.images);
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _typeCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose(); // ✅ NEW
    _maxGuestsCtrl.dispose();
    _descCtrl.dispose();
    _amenityCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
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

  String _basename(String path) {
    final p = path.replaceAll('\\', '/');
    final parts = p.split('/');
    return parts.isNotEmpty ? parts.last : 'image.jpg';
  }

  String? _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return null;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final files = <CloudinaryBytesFile>[];
    for (final x in picked) {
      final bytes = await x.readAsBytes();
      final name = _basename(x.path);
      files.add(
        CloudinaryBytesFile(
          bytes: bytes,
          fileName: name,
          mimeType: _guessMimeType(name),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _newImages.addAll(files));
  }

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));
  void _removeUrlImage(int index) => setState(() => _imageUrls.removeAt(index));

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

  double _parsePrice(String s) {
    // ✅ bỏ hết ký tự không phải số (dù là 1.200.000 hay 1,200,000 đều parse đúng)
    final digits = s.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }

  double? _parseArea(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    // cho phép người dùng nhập 25.5 hoặc 25,5
    final normalized = t.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  int _parseInt(String s, {int fallback = 1}) {
    return int.tryParse(s.trim()) ?? fallback;
  }

  Future<List<String>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];

    final cloudinary = CloudinaryService();
    final urls = await cloudinary.uploadManyBytes(
      _newImages,
      folder: 'hotel_rooms/rooms/${widget.hotelId}',
    );

    return urls;
  }

  void _stepGuests(int delta) {
    final next = (_maxGuests + delta).clamp(1, 20);
    setState(() {
      _maxGuests = next;
      _maxGuestsCtrl.text = _maxGuests.toString();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    try {
      final provider = context.read<HotelProvider>();

      final uploadedUrls = await _uploadNewImages();
      final finalImageUrls = <String>[
        ..._imageUrls,
        ...uploadedUrls,
      ];

      final roomNumber = _roomNumberCtrl.text.trim();
      final type = _typeCtrl.text.trim();
      final price = _parsePrice(_priceCtrl.text);
      final area = _parseArea(_areaCtrl.text); // ✅ NEW
      final maxGuests = _parseInt(_maxGuestsCtrl.text, fallback: 1);
      final desc = _descCtrl.text.trim();

      if (_isEdit) {
        final r = widget.room!;

        // ✅ UPDATE: chỉ update thông tin, không tự đổi trạng thái
        await provider.updateRoom(
          roomId: r.roomId,
          roomNumber: roomNumber,
          type: type,
          price: price,
          description: desc,
          maxGuests: maxGuests,
          amenities: _amenities.toList(),
          imageUrls: finalImageUrls,
          area: area, // ✅ NEW
        );
      } else {
        // ✅ CREATE: mặc định pending để Admin duyệt
        await provider.createRoom(
          hotelId: widget.hotelId,
          hotelName: widget.hotelName, // ✅ có thì lưu luôn để admin dễ nhìn
          roomNumber: roomNumber,
          type: type,
          price: price,
          description: desc,
          maxGuests: maxGuests,
          amenities: _amenities.toList(),
          imageUrls: finalImageUrls,
          area: area, // ✅ NEW
          status: RoomStatus.pending, // ✅ QUAN TRỌNG: chờ duyệt
          isActive: true,
        );
      }

      _newImages.clear();

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? '✅ Đã cập nhật phòng.'
                : '✅ Đã gửi phòng. Chờ Admin duyệt.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.tertiaryContainer,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_isEdit ? 'Chỉnh sửa phòng' : 'Đăng phòng mới'),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _submitting
                    ? 'Đang lưu...'
                    : (_isEdit ? 'Cập nhật phòng' : 'Lưu thông tin phòng'),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              Text(
                widget.hotelName?.trim().isNotEmpty == true
                    ? 'Khách sạn: ${widget.hotelName}'
                    : 'hotelId: ${widget.hotelId}',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),

              // ===== Ảnh phòng =====
              _SectionCard(
                title: 'Ảnh phòng',
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
                            onTap: _submitting ? null : _pickImages,
                          ),
                          const SizedBox(width: 10),

                          // ảnh url (khi sửa)
                          ...List.generate(_imageUrls.length, (i) {
                            final url = _imageUrls[i];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _ThumbTileUrl(
                                url: url,
                                onRemove:
                                _submitting ? null : () => _removeUrlImage(i),
                              ),
                            );
                          }),

                          // ảnh bytes mới
                          ...List.generate(_newImages.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _ThumbTileBytes(
                                bytes: _newImages[i].bytes,
                                onRemove:
                                _submitting ? null : () => _removeNewImage(i),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (_imageUrls.length + _newImages.length) == 0
                          ? 'Hãy thêm ảnh để phòng trông hấp dẫn hơn.'
                          : 'Đã chọn ${_imageUrls.length + _newImages.length} ảnh.',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ===== Thông tin cơ bản =====
              _SectionCard(
                title: 'Thông tin cơ bản',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomNumberCtrl,
                            decoration: _dec(
                              'Số phòng',
                              Icons.meeting_room_outlined,
                              hint: 'VD: 101',
                            ),
                            validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Nhập số phòng' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _typeCtrl,
                            decoration: _dec(
                              'Loại phòng',
                              Icons.category_outlined,
                              hint: 'Standard / Deluxe…',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ✅ Giá + Diện tích
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              VndInputFormatter(),
                            ],

                            decoration: _dec(
                              'Giá / đêm (VND)',
                              Icons.payments_outlined,
                              hint: '1.200.000',
                            ),
                            validator: (v) {
                              final p = _parsePrice(v ?? '');
                              if (p <= 0) return 'Giá phải > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _areaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                            ],
                            decoration: _dec(
                              'Diện tích (m²)',
                              Icons.square_foot_outlined,
                              hint: '25',
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return null; // cho phép bỏ trống
                              final a = _parseArea(t);
                              if (a == null || a <= 0) return 'Diện tích phải > 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ✅ Số khách tối đa (giữ như cũ)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số khách tối đa',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed:
                                _submitting ? null : () => _stepGuests(-1),
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _maxGuests.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed:
                                _submitting ? null : () => _stepGuests(1),
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ),
                        // giữ controller để submit/validate như cũ
                        SizedBox(
                          height: 0,
                          child: TextFormField(
                            controller: _maxGuestsCtrl,
                            validator: (v) {
                              final n = _parseInt(v ?? '', fallback: 0);
                              if (n <= 0) return 'Phải >= 1';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: _dec(
                        'Mô tả chi tiết',
                        Icons.description_outlined,
                        hint: 'Mô tả về không gian, view, và các điểm nổi bật…',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ===== Tiện nghi =====
              _SectionCard(
                title: 'Tiện nghi phòng',
                trailing: TextButton(
                  onPressed: _submitting
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
                          onSelected:
                          _submitting ? null : (_) => _toggleAmenity(a),
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
                              'Thêm tiện nghi khác',
                              Icons.add_circle_outline_rounded,
                              hint: 'Ví dụ: Dịch vụ giặt ủi',
                            ),
                            onSubmitted: (_) => _addCustomAmenity(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _submitting ? null : _addCustomAmenity,
                            child: const Text('Thêm'),
                          ),
                        ),
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
                            onDeleted:
                            _submitting ? null : () => _toggleAmenity(a),
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

class _ThumbTileUrl extends StatelessWidget {
  final String url;
  final VoidCallback? onRemove;

  const _ThumbTileUrl({required this.url, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: 110,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 110,
              height: 80,
              alignment: Alignment.center,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              child: const Icon(Icons.broken_image_outlined),
            ),
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

class _ThumbTileBytes extends StatelessWidget {
  final dynamic bytes;
  final VoidCallback? onRemove;

  const _ThumbTileBytes({required this.bytes, this.onRemove});

  @override
  Widget build(BuildContext context) {
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
