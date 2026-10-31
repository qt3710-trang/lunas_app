import 'package:flutter/material.dart';

import '../../app/data/hair_style.dart';
import '../../app/theme.dart';

/// Ảnh của mẫu tóc. Có [imageUrl] thì tải ảnh thật từ mạng;
/// không có (hoặc đang tải / lỗi) thì hiện nền chuyển màu theo màu tóc.
class HairThumb extends StatelessWidget {
  const HairThumb({
    super.key,
    required this.color,
    this.iconSize = 56,
    this.icon = Icons.face_3,
    this.imageUrl,
  });

  final HairColor color;
  final double iconSize;
  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }

  Widget _placeholder() {
    final base = color.color;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(base, Colors.white, 0.55)!, base],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}

/// Chấm tròn màu tóc + tên màu.
class HairColorLabel extends StatelessWidget {
  const HairColorLabel({super.key, required this.color});

  final HairColor color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            color.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }
}

/// Thẻ mẫu tóc trong lưới: ảnh, tên, màu tóc, nút yêu thích.
class HairStyleCard extends StatelessWidget {
  const HairStyleCard({
    super.key,
    required this.style,
    required this.isFavorite,
    required this.onFavorite,
    this.onTap,
  });

  final HairStyle style;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HairThumb(color: style.color, imageUrl: style.thumbUrl),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteButton(
                      active: isFavorite,
                      onTap: onFavorite,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  HairColorLabel(color: style.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: active ? AppColors.pink : AppColors.textGrey,
        ),
      ),
    );
  }
}

/// Chip bo tròn: đang chọn thì nền teal nhạt, chữ teal.
class GalleryChip extends StatelessWidget {
  const GalleryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.teal : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.teal : AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textDark,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
