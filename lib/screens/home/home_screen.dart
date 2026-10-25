import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// GD3: Trang chủ – kiểu tóc hot tuần, tìm kiếm, category, thông báo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Trang chủ',
      icon: Icons.home_outlined,
      note: 'GD3: kiểu tóc hot trong tuần, thanh tìm kiếm,\ncategory kiểu tóc / màu tóc, nút thông báo.',
    );
  }
}
