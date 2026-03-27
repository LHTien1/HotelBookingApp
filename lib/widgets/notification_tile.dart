import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.n,
    required this.onTap,
    this.onDelete,
  });

  IconData _iconByType(String type) {
    switch (type) {
      case 'booking':
        return Icons.check_circle_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'approval':
        return Icons.fact_check_rounded;
      case 'message':
        return Icons.forum_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'system':
      default:
        return Icons.info_rounded;
    }
  }

  Color _toneByType(BuildContext context, String type) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case 'booking':
        return cs.primary;
      case 'promo':
        return Colors.deepOrange;
      case 'review':
        return Colors.amber.shade700;
      case 'message':
        return cs.secondary;
      case 'payment':
        return Colors.teal;
      case 'approval':
        return Colors.indigo;
      case 'system':
      default:
        return Colors.purple;
    }
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tone = _toneByType(context, n.type);

    final tileBg = n.isRead
        ? cs.surface
        : tone.withValues(alpha: isDark ? 0.08 : 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          color: tileBg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon block
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconByType(n.type),
                  color: tone,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: n.isRead ? FontWeight.w800 : FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.25,
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _relativeTime(n.createdAt),
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: unread dot + optional delete
              const SizedBox(width: 8),
              Column(
                children: [
                  // dot chưa đọc ở góc phải giống ảnh
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.transparent : cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Xoá',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
