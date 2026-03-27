import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:booking_app/providers/report_providers.dart' as rpt;

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({
    super.key,
    required this.hotelId,
    this.roomId,
    this.hotelName,
    this.roomLabel,
    this.address,
    this.thumbnailUrl,
  });

  static const routeName = '/add-report';

  final String hotelId;
  final String? roomId;

  // UI-only
  final String? hotelName;
  final String? roomLabel;
  final String? address;
  final String? thumbnailUrl;

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lyDoCtrl = TextEditingController();
  final _moTaCtrl = TextEditingController();

  final List<String> _reasons = const [
    'Hình ảnh không đúng mô tả',
    'Giá/Phí không đúng',
    'Thông tin sai lệch',
    'Vấn đề vệ sinh',
    'Lừa đảo / Không an toàn',
    'Khác',
  ];

  String? _selectedReason;

  @override
  void dispose() {
    _lyDoCtrl.dispose();
    _moTaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guiBaoCao() async {
    FocusScope.of(context).unfocus();

    // Đồng bộ lý do
    if (_selectedReason != null && _selectedReason != 'Khác') {
      _lyDoCtrl.text = _selectedReason!;
    }

    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<rpt.ReportProvider>();

    try {
      await provider.addReport(
        hotelId: widget.hotelId,
        roomId: widget.roomId,
        reason: _lyDoCtrl.text.trim(),
        description: _moTaCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn! Báo cáo đã được gửi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Không thể gửi báo cáo. Vui lòng thử lại.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hotelText = (widget.hotelName ?? '').trim().isNotEmpty
        ? widget.hotelName!.trim()
        : 'Khách sạn';

    final roomText = (widget.roomLabel ?? '').trim().isNotEmpty
        ? widget.roomLabel!.trim()
        : (widget.roomId ?? '');

    final addrText = (widget.address ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo vi phạm')),
      body: Consumer<rpt.ReportProvider>(
        builder: (context, p, _) {
          return AbsorbPointer(
            absorbing: p.isLoading,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                      errorBuilder: (_, __, ___) => _thumbFallback(cs),
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16.5,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if (roomText.trim().isNotEmpty) roomText.trim(),
                                          if (addrText.isNotEmpty) addrText,
                                        ].join(' • '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Tại sao bạn báo cáo nơi này?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ✅ Flutter mới: dùng initialValue (không dùng value)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedReason,
                          items: _reasons
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedReason = v;
                              if (v != null && v != 'Khác') _lyDoCtrl.text = v;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Chọn lý do phù hợp nhất...',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          validator: (_) {
                            if ((_selectedReason ?? '').isEmpty) return 'Vui lòng chọn lý do';
                            if (_selectedReason == 'Khác' && _lyDoCtrl.text.trim().isEmpty) {
                              return 'Vui lòng nhập lý do';
                            }
                            return null;
                          },
                        ),

                        if (_selectedReason == 'Khác') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lyDoCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Lý do (khác)',
                              prefixIcon: Icon(Icons.edit_outlined),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (_selectedReason == 'Khác' && s.isEmpty) return 'Vui lòng nhập lý do';
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 18),

                        Text(
                          'Mô tả chi tiết',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: _moTaCtrl,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: 'Hãy chia sẻ thêm thông tin chi tiết về vấn đề bạn gặp phải...',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Vui lòng mô tả chi tiết';
                            if (s.length < 10) return 'Mô tả quá ngắn (tối thiểu 10 ký tự).';
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: p.isLoading ? null : _guiBaoCao,
                            icon: const Icon(Icons.send),
                            label: const Text('Gửi báo cáo'),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                if (p.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: cs.surface.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _thumbFallback(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Icon(Icons.hotel_outlined, color: cs.onSurfaceVariant, size: 30),
    );
  }
}
