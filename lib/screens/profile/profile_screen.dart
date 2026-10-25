import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// GD7: Hồ sơ – mẫu đã lưu, lịch hẹn, dáng mặt & tông da, phong cách, AI gợi ý.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Hồ sơ',
      icon: Icons.person_outline,
      note: 'GD7: tab Mẫu đã lưu / Lịch hẹn, dáng mặt & tông da,\nphong cách yêu thích, nút AI gợi ý kiểu tóc.',
    );
  }
}
