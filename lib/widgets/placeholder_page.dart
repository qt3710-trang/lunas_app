import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Màn hình tạm cho các tab chưa làm.
/// Ai nhận làm màn nào thì xóa PlaceholderPage trong file màn đó
/// và viết giao diện thật vào.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.note,
  });

  final String title;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppColors.teal),
                const SizedBox(height: 16),
                Text(title, style: AppTheme.titleFont(size: 26)),
                const SizedBox(height: 8),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
