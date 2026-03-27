import 'package:booking_app/models/report_model.dart';
import 'package:booking_app/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  Future<void> _capNhatTrangThai(String maBaoCao, ReportStatus trangThaiMoi) async {
    final reportProvider = context.read<ReportProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await reportProvider.updateReportStatus(maBaoCao, trangThaiMoi);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật trạng thái báo cáo.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Cập nhật trạng thái thất bại: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _trangThaiVi(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Chờ xử lý';
      case ReportStatus.resolved:
        return 'Đã xử lý';
      case ReportStatus.dismissed:
        return 'Đã bỏ qua';
    }
  }

  Color _mauTrangThai(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  String _fmtDateTime(DateTime dt) {
    return '${DateFormat('dd/MM/yyyy').format(dt)} • ${DateFormat('HH:mm').format(dt)}';
  }

  String _roomText(ReportModel r) {
    final id = r.reportedRoomId?.toString().trim();
    if (id == null || id.isEmpty) return 'Unknown';

    if (id.toLowerCase().contains('phòng')) return id;
    if (id.toLowerCase().startsWith('p')) return 'Phòng $id';
    if (RegExp(r'^\d+$').hasMatch(id)) return 'Phòng P$id';
    return 'Phòng $id';
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lọc báo cáo',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Mới nhất'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Cũ nhất'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    await context.read<ReportProvider>().loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo từ người dùng'),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading && reportProvider.reports.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = reportProvider.reports;

          if (all.isEmpty) {
            return Center(
              child: Text(
                'Không có báo cáo nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          final pending = all.where((r) => r.status == ReportStatus.pending).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final history = all.where((r) => r.status != ReportStatus.pending).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 22),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'DANH SÁCH CHỜ (${pending.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _openFilterSheet,
                        icon: Icon(Icons.filter_list, color: cs.primary),
                        label: Text('Lọc', style: TextStyle(color: cs.primary)),
                      ),
                    ],
                  ),
                ),

                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Text(
                      'Không có báo cáo nào đang chờ xử lý.',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),

                ...pending.map((report) {
                  final statusColor = _mauTrangThai(report.status);
                  final timeText = _fmtDateTime(report.createdAt);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: isDark ? 0 : 2,
                    color: cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.55),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _PillStatus(
                                label: _trangThaiVi(report.status),
                                color: statusColor,
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Tùy chọn',
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    showDragHandle: true,
                                    builder: (ctx) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.check_circle),
                                              title: const Text('Đánh dấu đã xử lý'),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _capNhatTrangThai(report.reportId, ReportStatus.resolved);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.block),
                                              title: const Text('Bỏ qua'),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _capNhatTrangThai(report.reportId, ReportStatus.dismissed);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: Icon(Icons.more_horiz, color: cs.onSurface.withValues(alpha: 0.55)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            report.reason,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.apartment, size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(
                                report.reportedHotelId,
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('•', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55))),
                              const SizedBox(width: 10),
                              Text(
                                _roomText(report),
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            report.description,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.80),
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 12),
                          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: cs.primary.withValues(alpha: 0.12),
                                child: Text(
                                  _initials(report.reporterUserId),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${report.reporterUserId}\n$timeText',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _capNhatTrangThai(report.reportId, ReportStatus.dismissed),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Bỏ qua'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _capNhatTrangThai(report.reportId, ReportStatus.resolved),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Đã xử lý'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.55))),
                      const SizedBox(width: 12),
                      Text(
                        'LỊCH SỬ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.55))),
                    ],
                  ),
                ),

                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Text(
                      'Chưa có lịch sử.',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),

                ...history.map((report) {
                  final statusColor = _mauTrangThai(report.status);
                  final timeText = DateFormat('dd/MM/yyyy').format(report.createdAt);

                  return Opacity(
                    opacity: report.status == ReportStatus.dismissed ? 0.55 : 0.85,
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PillStatus(label: _trangThaiVi(report.status), color: statusColor, compact: true),
                            const SizedBox(height: 10),
                            Text(
                              report.reason,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.apartment, size: 18, color: cs.onSurface.withValues(alpha: 0.55)),
                                const SizedBox(width: 8),
                                Text(
                                  report.reportedHotelId,
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('•', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45))),
                                const SizedBox(width: 10),
                                Text(
                                  _roomText(report),
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(timeText, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              report.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PillStatus extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const _PillStatus({
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final s = name.trim();
  if (s.isEmpty) return '?';
  final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
  final first = parts.first.characters.first.toUpperCase();
  final last = parts.last.characters.first.toUpperCase();
  return '$first$last';
}
