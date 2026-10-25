import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// GD6: Đặt lịch – chọn ngày, giờ, dịch vụ đi kèm, tóm tắt, xác nhận.
/// Sau khi xác nhận sẽ sang màn "Đặt lịch thành công" (thêm route sau).
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Đặt lịch',
      icon: Icons.calendar_month_outlined,
      note: 'GD6: chọn ngày (easy_date_timeline), chọn khung giờ,\ndịch vụ đi kèm, tóm tắt lịch hẹn, Xác nhận đặt lịch.',
    );
  }
}
