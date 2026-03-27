import 'package:booking_app/providers/booking_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RevenueStatsScreen extends StatefulWidget {
  const RevenueStatsScreen({super.key});

  @override
  State<RevenueStatsScreen> createState() => _RevenueStatsScreenState();
}

class _RevenueStatsScreenState extends State<RevenueStatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final bookingProvider = context.read<BookingProvider>();

    // TODO: thay 'h1' bằng hotelId thật của chủ khách sạn
    const hotelId = 'h1';

    final revenue = await bookingProvider.calculateRevenue(hotelId: hotelId);
    final statistics = await bookingProvider.getStatistics(hotelId: hotelId);

    return <String, dynamic>{
      'revenue': revenue,
      'stats': statistics,
    };
  }

  void _reload() {
    setState(() {
      _statsFuture = _fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Không thể tải thống kê.'));
          }

          final data = snapshot.data!;
          final double totalRevenue = (data['revenue'] as num?)?.toDouble() ?? 0;
          final Map<String, int> stats =
              (data['stats'] as Map<String, int>?) ?? <String, int>{};

          final int totalBookings = stats['total'] ?? 0;
          final int confirmed = stats['confirmed'] ?? 0;
          final int cancelled = stats['cancelled'] ?? 0;

          final double averageRevenue =
          totalBookings > 0 ? totalRevenue / totalBookings : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tháng này',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // UI-only dropdown giống ảnh
                  PopupMenuButton<String>(
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'this', child: Text('Tháng này')),
                      PopupMenuItem(value: 'last', child: Text('Tháng trước')),
                    ],
                    icon: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _SummaryRevenueCard(
                value: '${currencyFormatter.format(totalRevenue)} đ',
              ),
              const SizedBox(height: 14),

              _SectionTitle(title: 'Chi tiết chỉ số'),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _StatTile(
                    title: 'Tổng lượt đặt',
                    value: totalBookings.toString(),
                    icon: Icons.bookmark_border_rounded,
                  ),
                  _StatTile(
                    title: 'Đã xác nhận',
                    value: confirmed.toString(),
                    icon: Icons.verified_rounded,
                  ),
                  _StatTile(
                    title: 'Đã huỷ',
                    value: cancelled.toString(),
                    icon: Icons.cancel_rounded,
                  ),
                  _StatTile(
                    title: 'Doanh thu TB',
                    value: '${currencyFormatter.format(averageRevenue)} đ',
                    icon: Icons.monetization_on_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _SectionTitle(title: 'Xu hướng doanh thu'),
              const SizedBox(height: 10),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chưa có dữ liệu theo ngày/tuần để vẽ biểu đồ.\n(Chức năng vẫn giữ nguyên)',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text(
      title,
      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _SummaryRevenueCard extends StatelessWidget {
  final String value;

  const _SummaryRevenueCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.attach_money_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng doanh thu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
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

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            Icon(icon, color: cs.primary, size: 28),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
