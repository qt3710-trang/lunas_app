import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// GD5: Thử với AR – xin quyền camera, chọn kiểu tóc / màu / mái, xem kết quả.
class ArTryScreen extends StatelessWidget {
  const ArTryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Thử tóc AR',
      icon: Icons.center_focus_strong,
      note: 'GD5: xin quyền camera, chọn kiểu tóc, màu tóc,\nkiểu mái, độ dài và nút Xem kết quả.\n(Làm ở giai đoạn 3)',
    );
  }
}
