import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// GD4: Mẫu – bộ sưu tập tóc xinh, search, category, mẫu nổi bật.
/// Bấm vào một mẫu sẽ mở màn chi tiết mẫu (thêm route sau).
class StylesScreen extends StatelessWidget {
  const StylesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Mẫu tóc',
      icon: Icons.grid_view_outlined,
      note: 'GD4: thanh search, category (Tóc ngắn, Tóc dài, Layer...),\nlưới mẫu tóc nổi bật, bấm vào xem chi tiết.',
    );
  }
}
