import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Thẻ mẫu tóc trong lưới: ảnh bo góc (tim + nhãn "Xu hướng"),
/// tên kiểu chữ có chân mềm mại, hàng chấm màu tóc có sẵn.
class HairStyleCard extends StatelessWidget {
  const HairStyleCard({
    super.key,
    required this.style,
    required this.isFavorite,
    required this.onFavorite,
    this.onTap,
    this.color,
    this.title,
    this.imageAspectRatio,
  });

  final HairStyle style;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback? onTap;

  /// Màu muốn hiện trên thẻ (ví dụ màu đang lọc). Bỏ trống thì dùng màu mặc định.
  final HairColor? color;

  /// Tên hiện trên thẻ. Bỏ trống thì dùng tên mẫu.
  final String? title;

  /// Tỉ lệ ảnh cố định (rộng / cao), dùng khi thẻ không bị giới hạn chiều cao
  /// (ví dụ xếp trong Wrap). Bỏ trống thì ảnh giãn hết phần còn lại của thẻ.
  final double? imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    final shown = color ?? style.color;
    final ratio = imageAspectRatio;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14263B3B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              mainAxisSize: ratio == null ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sized(
                  ratio,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        HairThumb(
                          color: shown,
                          imageUrl: style.imageFor(shown),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _FavoriteButton(
                            active: isFavorite,
                            onTap: onFavorite,
                          ),
                        ),
                        if (style.isTrending)
                          Positioned(
                            left: 7,
                            bottom: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: .9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Xu hướng',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? style.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final c in style.colors.take(5))
                            _ColorDot(color: c, selected: c == shown),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _sized(double? ratio, Widget child) => ratio == null
      ? Expanded(child: child)
      : AspectRatio(aspectRatio: ratio, child: child);
}

/// Chấm màu tóc trên thẻ; màu đang hiện có viền teal.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected});

  final HairColor color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: color.label,
      child: Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color.color, shape: BoxShape.circle),
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.9 : 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: active ? AppColors.pink : Colors.white,
          shadows: const [Shadow(color: Color(0x40000000), blurRadius: 4)],
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
      color: selected ? AppColors.tealLight : Colors.white,
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
              color: selected ? AppColors.teal : AppColors.textDark,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
