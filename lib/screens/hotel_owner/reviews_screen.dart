import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  int _filterIndex = 0; // 0 all, 1 newest, 2 highest

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: thay 'h1' bằng mã khách sạn thật
      context.read<HotelProvider>().loadHotelReviews('h1');
    });
  }

  Future<void> _reload() async {
    await context.read<HotelProvider>().loadHotelReviews('h1');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Đánh giá của khách'),
        centerTitle: true,
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, _) {
          final reviews = hotelProvider.reviews;

          if (hotelProvider.isLoading && reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reviews.isEmpty) {
            return Center(
              child: Text(
                'Chưa có đánh giá nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          // ===== compute rating summary =====
          final total = reviews.length;
          final avg = reviews.fold<double>(0, (s, r) => s + r.rating) / total;

          final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (final r in reviews) {
            final star = r.rating.round().clamp(1, 5);
            dist[star] = (dist[star] ?? 0) + 1;
          }

          // ===== sort locally (UI-only) =====
          final sorted = [...reviews];
          if (_filterIndex == 1) {
            // newest: nếu model có createdAt thì bạn thay ở đây,
            // tạm giữ nguyên thứ tự provider trả về
          } else if (_filterIndex == 2) {
            sorted.sort((a, b) => b.rating.compareTo(a.rating));
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _RatingHeader(
                  avg: avg,
                  total: total,
                  distribution: dist,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _Pill(
                      text: 'Tất cả',
                      selected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      text: 'Mới nhất',
                      selected: _filterIndex == 1,
                      onTap: () => setState(() => _filterIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      text: 'Sao cao',
                      selected: _filterIndex == 2,
                      onTap: () => setState(() => _filterIndex = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ✅ FIX: bỏ .toList() trong spread
                ...sorted.map((dg) {
                  final ten = (dg.userName).toString().trim();
                  final anhDaiDien = (dg.userAvatarUrl).toString().trim();
                  final binhLuan = (dg.comment).toString().trim();
                  final soSao = dg.rating;
                  final kyTuDau = ten.isNotEmpty ? ten[0].toUpperCase() : '•';

                  return _ReviewCard(
                    name: ten.isNotEmpty ? ten : 'Khách ẩn danh',
                    avatarUrl: anhDaiDien,
                    fallbackChar: kyTuDau,
                    rating: soSao,
                    comment: binhLuan.isNotEmpty ? binhLuan : 'Không có nội dung.',
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

class _RatingHeader extends StatelessWidget {
  final double avg;
  final int total;
  final Map<int, int> distribution;

  const _RatingHeader({
    required this.avg,
    required this.total,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    int maxCount = 1;
    for (final v in distribution.values) {
      if (v > maxCount) maxCount = v;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = (i + 1) <= avg.round();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: cs.primary,
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$total đánh giá',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: List.generate(5, (i) {
                  final star = 5 - i;
                  final count = distribution[star] ?? 0;
                  final pct = count / maxCount;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '$star',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(count * 100 / total).round()}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String fallbackChar;
  final double rating;
  final String comment;

  const _ReviewCard({
    required this.name,
    required this.avatarUrl,
    required this.fallbackChar,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary.withValues(alpha: 0.18),
                  foregroundColor: cs.primary,
                  backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  onBackgroundImageError: (_, __) {},
                  child: avatarUrl.isNotEmpty
                      ? null
                      : Text(
                    fallbackChar,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.star_rounded, color: cs.primary, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.82),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
