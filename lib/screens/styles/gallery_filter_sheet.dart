import 'package:flutter/material.dart';

import '../../app/data/hair_style.dart';
import '../../app/theme.dart';
import 'gallery_widgets.dart';

/// Mở bộ lọc mẫu tóc (gần như toàn màn hình, che cả thanh menu dưới).
/// Trả về bộ lọc mới khi bấm "Áp dụng", null nếu đóng.
Future<GalleryFilter?> showGalleryFilterSheet(
  BuildContext context,
  GalleryFilter current,
) {
  return showModalBottomSheet<GalleryFilter>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _GalleryFilterSheet(initial: current),
    ),
  );
}

class _GalleryFilterSheet extends StatefulWidget {
  const _GalleryFilterSheet({required this.initial});

  final GalleryFilter initial;

  @override
  State<_GalleryFilterSheet> createState() => _GalleryFilterSheetState();
}

class _GalleryFilterSheetState extends State<_GalleryFilterSheet> {
  late Set<HairLength> _lengths = {...widget.initial.lengths};
  late Set<HairType> _types = {...widget.initial.types};
  late Set<HairColor> _colors = {...widget.initial.colors};
  late Set<HairOccasion> _occasions = {...widget.initial.occasions};
  late HairSort _sort = widget.initial.sort;

  void _toggle<T>(Set<T> set, T value) {
    setState(() => set.contains(value) ? set.remove(value) : set.add(value));
  }

  void _reset() {
    setState(() {
      _lengths = {};
      _types = {};
      _colors = {};
      _occasions = {};
      _sort = HairSort.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bộ lọc mẫu tóc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                _section(
                  'Độ dài tóc',
                  _chips(HairLength.values, _lengths, (e) => e.label),
                ),
                _section(
                  'Kiểu tóc',
                  _chips(HairType.values, _types, (e) => e.label),
                ),
                _section('Màu tóc', _colorSwatches()),
                _section(
                  'Dịp sử dụng',
                  _chips(HairOccasion.values, _occasions, (e) => e.label),
                ),
                _section(
                  'Độ phổ biến',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in HairSort.values)
                        GalleryChip(
                          label: s.label,
                          selected: _sort == s,
                          onTap: () => setState(() => _sort = s),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Đặt lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      GalleryFilter(
                        lengths: _lengths,
                        types: _types,
                        colors: _colors,
                        occasions: _occasions,
                        sort: _sort,
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Hàng chip có "Tất cả" ở đầu; "Tất cả" được chọn khi set rỗng.
  Widget _chips<T>(List<T> values, Set<T> selected, String Function(T) label) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GalleryChip(
          label: 'Tất cả',
          selected: selected.isEmpty,
          onTap: () => setState(selected.clear),
        ),
        for (final v in values)
          GalleryChip(
            label: label(v),
            selected: selected.contains(v),
            onTap: () => _toggle(selected, v),
          ),
      ],
    );
  }

  Widget _colorSwatches() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _swatch(
          selected: _colors.isEmpty,
          onTap: () => setState(_colors.clear),
          child: const Icon(
            Icons.format_color_reset_outlined,
            size: 18,
            color: AppColors.teal,
          ),
          fill: Colors.white,
        ),
        for (final c in HairColor.values)
          Tooltip(
            message: c.label,
            child: _swatch(
              selected: _colors.contains(c),
              onTap: () => _toggle(_colors, c),
              fill: c.color,
            ),
          ),
      ],
    );
  }

  Widget _swatch({
    required bool selected,
    required VoidCallback onTap,
    required Color fill,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
