import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/data/favorite_styles.dart';
import '../../app/data/collection_styles.dart';
import '../../app/data/hair_style.dart';
import '../../app/theme.dart';
import 'gallery_widgets.dart';

/// Các góc chụp của một mẫu (ảnh tạm, khi có ảnh thật thì thay bằng list ảnh).
const _angles = [
  Icons.face_3,
  Icons.face_2,
  Icons.face_4,
  Icons.face_5,
  Icons.face_6,
  Icons.face,
];

/// Chi tiết mẫu tóc: ảnh, mô tả, giá, chọn màu, tùy biến nhanh, mẫu tương tự.
/// Mở từ trang Mẫu qua route /styles/:id, vẫn giữ thanh menu dưới.
class HairStyleDetailScreen extends StatefulWidget {
  const HairStyleDetailScreen({super.key, required this.styleId});

  final String styleId;

  @override
  State<HairStyleDetailScreen> createState() => _HairStyleDetailScreenState();
}

class _HairStyleDetailScreenState extends State<HairStyleDetailScreen> {
  late final HairStyle? _style =
      hairStyles.where((s) => s.id == widget.styleId).firstOrNull;

  int _angle = 0;
  late HairColor _color = _style!.color;
  late String _length = switch (_style!.length) {
    HairLength.short => 'Ngắn',
    HairLength.medium => 'Vừa',
    HairLength.long => 'Dài',
  };
  String _bangs = 'Mái thưa';
  late String _texture = _style!.types.contains(HairType.curly)
      ? 'Xoăn'
      : _style.types.contains(HairType.straight)
          ? 'Thẳng'
          : 'Gợn sóng';

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/styles');
    }
  }

  void _saveToCollection(HairStyle style) {
    final alreadySaved = collectionStyles.contains(style.id);
    collectionStyles.add(style.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(alreadySaved
            ? '${style.name} đã có trong Bộ sưu tập của tôi'
            : 'Đã thêm ${style.name} vào Bộ sưu tập của tôi'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    if (style == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _back)),
        body: const Center(child: Text('Không tìm thấy mẫu tóc này.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left, size: 30), onPressed: _back),
        centerTitle: true,
        title: const Text(
          'LUNAS HAIR STUDIO',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        actions: [
          ListenableBuilder(
            listenable: favoriteStyles,
            builder: (context, _) {
              final saved = favoriteStyles.contains(style.id);
              return IconButton(
                tooltip: saved ? 'Bỏ lưu' : 'Lưu mẫu',
                onPressed: () => favoriteStyles.toggle(style.id),
                icon: Icon(
                  saved ? Icons.favorite : Icons.favorite_border,
                  color: saved ? AppColors.pink : AppColors.textDark,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _buildMainImage(style),
          const SizedBox(height: 10),
          _buildAngles(),
          const SizedBox(height: 16),
          Text(style.name, style: AppTheme.titleFont(size: 26)),
          const SizedBox(height: 2),
          Text(style.tagline, style: const TextStyle(color: AppColors.pink, fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            style.description,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in style.tags) _Tag(t)],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _InfoBox(icon: Icons.schedule, text: style.duration)),
              const SizedBox(width: 12),
              Expanded(child: _InfoBox(icon: Icons.sell_outlined, text: style.price)),
            ],
          ),
          const _Heading(
            'Chọn màu tóc của bạn',
            subtitle: 'Khám phá sắc màu phù hợp với phong cách bạn yêu thích.',
          ),
          _buildColorPicker(),
          const _Heading('Tùy biến nhanh'),
          _OptionGroup(
            title: 'Độ dài tóc',
            options: const ['Ngắn', 'Vừa', 'Dài'],
            value: _length,
            onChanged: (v) => setState(() => _length = v),
          ),
          _OptionGroup(
            title: 'Kiểu mái',
            options: const ['Mái thưa', 'Mái bay', 'Không mái'],
            value: _bangs,
            onChanged: (v) => setState(() => _bangs = v),
          ),
          _OptionGroup(
            title: 'Kết cấu tóc',
            options: const ['Thẳng', 'Gợn sóng', 'Xoăn'],
            value: _texture,
            onChanged: (v) => setState(() => _texture = v),
          ),
          const _Heading('Có thể bạn cũng thích'),
          _buildSimilar(style),
        ],
      ),
      bottomNavigationBar: _buildActions(style),
    );
  }

  Widget _buildMainImage(HairStyle style) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 4 / 3.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            HairThumb(color: _color, icon: _angles[_angle], iconSize: 120),
            if (style.isTrending)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEFD2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đang thịnh hành',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB07A1E), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngles() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _angles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => setState(() => _angle = i),
          child: Container(
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _angle == i ? AppColors.teal : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HairThumb(color: _color, icon: _angles[i], iconSize: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HairColor.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = HairColor.values[i];
          final selected = c == _color;
          return GestureDetector(
            onTap: () => setState(() => _color = c),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.teal : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          HairThumb(color: c, iconSize: 30),
                          if (selected)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.teal,
                                child: Icon(Icons.check, size: 11, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mẫu cùng kiểu tóc, thiếu thì bù bằng mẫu phổ biến.
  Widget _buildSimilar(HairStyle style) {
    final others = hairStyles.where((s) => s.id != style.id).toList()
      ..sort((a, b) => b.likes.compareTo(a.likes));
    final similar = [
      ...others.where((s) => s.types.any(style.types.contains)),
      ...others.where((s) => !s.types.any(style.types.contains)),
    ].take(6).toList();

    return SizedBox(
      height: 200,
      child: ListenableBuilder(
        listenable: favoriteStyles,
        builder: (context, _) => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: similar.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final s = similar[i];
            return SizedBox(
              width: 140,
              child: HairStyleCard(
                style: s,
                isFavorite: favoriteStyles.contains(s.id),
                onFavorite: () => favoriteStyles.toggle(s.id),
                onTap: () => context.push('/styles/${s.id}'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActions(HairStyle style) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/ar'),
              icon: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Thử với AR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _saveToCollection(style),
              icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
              label: const Text('Thêm vào bộ sưu tập của tôi', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E6EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textDark),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Nhóm lựa chọn một trong nhiều (dạng radio) cho phần "Tùy biến nhanh".
class _OptionGroup extends StatelessWidget {
  const _OptionGroup({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final o in options)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onChanged(o),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            o == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 20,
                            color: o == value ? AppColors.teal : AppColors.textGrey,
                          ),
                          const SizedBox(width: 6),
                          Flexible(child: Text(o, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
