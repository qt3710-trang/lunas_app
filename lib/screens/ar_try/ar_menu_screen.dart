import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// Màn đầu tiên của tab "Thử với AR": cho người dùng chọn cách thử tóc.
/// - Camera trực tiếp -> /ar/live (ArTryOnScreen)
/// - Ảnh có sẵn / chụp mới -> /ar/photo (StaticTryScreen)
class ArMenuScreen extends StatelessWidget {
  const ArMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('Thử với AR', style: AppTheme.titleFont()),
          const SizedBox(height: 6),
          const Text(
            'Chọn cách bạn muốn thử kiểu tóc mới.',
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          _OptionCard(
            icon: Icons.videocam_outlined,
            color: AppColors.pink,
            title: 'Thử qua Camera trực tiếp',
            subtitle: 'Mở camera trước, tóc đi theo khuôn mặt của bạn.',
            onTap: () => context.go('/ar/live'),
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.photo_outlined,
            color: AppColors.teal,
            title: 'Thử qua Ảnh',
            subtitle: 'Chọn ảnh trong thư viện hoặc chụp một ảnh mới.',
            onTap: () => context.go('/ar/photo'),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
