import 'package:booking_app/models/booking_model.dart';
import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/widgets/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  static const routeName = '/my-bookings';

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<BookingProvider>().loadUserBookings(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn đặt phòng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Hoàn tất'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: Consumer<BookingProvider>(
          builder: (context, p, _) {
            if (p.isLoading && p.bookings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (p.bookings.isEmpty) {
              return Center(
                child: Text(
                  'Bạn chưa có đơn đặt phòng nào.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final upcoming = p.bookings.where((b) =>
            b.bookingStatus == BookingStatus.pending ||
                b.bookingStatus == BookingStatus.confirmed ||
                b.bookingStatus == BookingStatus.checkedIn).toList();

            final completed =
            p.bookings.where((b) => b.bookingStatus == BookingStatus.checkedOut).toList();

            final cancelled =
            p.bookings.where((b) => b.bookingStatus == BookingStatus.cancelled).toList();

            return TabBarView(
              children: [
                _BookingsList(items: upcoming),
                _BookingsList(items: completed),
                _BookingsList(items: cancelled),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({required this.items});

  final List<BookingModel> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) => BookingListItem(booking: items[i]),
    );
  }
}

class BookingListItem extends StatelessWidget {
  const BookingListItem({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,###', 'vi_VN');

    final (statusColor, statusText) = _statusUI(context, booking.bookingStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child: Container(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Icon(Icons.hotel_outlined, color: cs.onSurfaceVariant, size: 34),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.hotelId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          AppPill(text: statusText, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Phòng: ${booking.roomId}',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${dateFmt.format(booking.checkInDate)} - ${dateFmt.format(booking.checkOutDate)}',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${moneyFmt.format(booking.totalPrice)}đ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ],
            ),

            if (booking.bookingStatus == BookingStatus.checkedOut) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/add-review',
                      arguments: {
                        'roomId': booking.roomId,
                        'hotelId': booking.hotelId,
                      },
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Viết đánh giá'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, String) _statusUI(BuildContext context, BookingStatus status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case BookingStatus.pending:
        return (cs.tertiary, 'CHỜ');
      case BookingStatus.confirmed:
        return (cs.primary, 'ĐÃ XÁC NHẬN');
      case BookingStatus.checkedIn:
        return (cs.secondary, 'ĐÃ NHẬN PHÒNG');
      case BookingStatus.checkedOut:
        return (Colors.green, 'HOÀN TẤT');
      case BookingStatus.cancelled:
        return (cs.error, 'ĐÃ HỦY');
    }
  }
}
