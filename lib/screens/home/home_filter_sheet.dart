import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'home_data.dart';

class HomeHairFilter {
  const HomeHairFilter({this.length, this.style, this.color});

  final HomeHairLength? length;
  final HomeHairType? style;
  final HomeHairColor? color;

  bool get isDefault => length == null && style == null && color == null;

  bool matches(HomeHairStyle item) =>
      (length == null || item.length == length) &&
      (style == null || item.hairStyles.contains(style)) &&
      (color == null || item.hasColor(color!));
}

Future<HomeHairFilter?> showHomeHairFilterSheet(
  BuildContext context, {
  required HomeHairFilter initialFilter,
  required List<HomeHairStyle> styles,
}) => showModalBottomSheet<HomeHairFilter>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) =>
      _HomeHairFilterSheet(initialFilter: initialFilter, styles: styles),
);

class _HomeHairFilterSheet extends StatefulWidget {
  const _HomeHairFilterSheet({
    required this.initialFilter,
    required this.styles,
  });
  final HomeHairFilter initialFilter;
  final List<HomeHairStyle> styles;

  @override
  State<_HomeHairFilterSheet> createState() => _HomeHairFilterSheetState();
}

class _HomeHairFilterSheetState extends State<_HomeHairFilterSheet> {
  late HomeHairFilter _filter = widget.initialFilter;

  int get _resultCount => widget.styles.where(_filter.matches).length;

  void _reset() => setState(() => _filter = const HomeHairFilter());

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .88,
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bộ lọc mẫu tóc',
                      style: AppTheme.titleFont(size: 22),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng bộ lọc',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _groupTitle('Độ dài tóc'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          'Tất cả',
                          _filter.length == null,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              style: _filter.style,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Tóc ngắn',
                          _filter.length == HomeHairLength.short,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: HomeHairLength.short,
                              style: _filter.style,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Tóc ngang vai',
                          _filter.length == HomeHairLength.shoulder,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: HomeHairLength.shoulder,
                              style: _filter.style,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Tóc dài',
                          _filter.length == HomeHairLength.long,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: HomeHairLength.long,
                              style: _filter.style,
                              color: _filter.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _groupTitle('Kiểu tóc'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          'Tất cả',
                          _filter.style == null,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Layer',
                          _filter.style == HomeHairType.layer,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.layer,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Bob',
                          _filter.style == HomeHairType.bob,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.bob,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Tóc tém',
                          _filter.style == HomeHairType.pixie,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.pixie,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Wolf Cut',
                          _filter.style == HomeHairType.wolfCut,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.wolfCut,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Hush Cut',
                          _filter.style == HomeHairType.hushCut,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.hushCut,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Tóc uốn',
                          _filter.style == HomeHairType.curly,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.curly,
                              color: _filter.color,
                            ),
                          ),
                        ),
                        _chip(
                          'Tóc thẳng',
                          _filter.style == HomeHairType.straight,
                          () => setState(
                            () => _filter = HomeHairFilter(
                              length: _filter.length,
                              style: HomeHairType.straight,
                              color: _filter.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _groupTitle('Màu tóc'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        _colorChoice(null, 'Tất cả'),
                        for (final color in HomeHairColor.values)
                          _colorChoice(color, color.label),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _filter.isDefault ? null : _reset,
                    child: const Text('Đặt lại'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _filter),
                      child: Text('Xem $_resultCount mẫu tóc'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _groupTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );

  Widget _chip(String title, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(title),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.textDark,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    selectedColor: AppColors.teal,
    backgroundColor: Colors.white,
    side: BorderSide(color: selected ? AppColors.teal : AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  );

  Widget _colorChoice(HomeHairColor? color, String label) {
    final selected = _filter.color == color;
    return InkWell(
      onTap: () => setState(
        () => _filter = HomeHairFilter(
          length: _filter.length,
          style: _filter.style,
          color: color,
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color?.color ?? Colors.white,
                border: Border.all(
                  color: selected ? AppColors.teal : AppColors.border,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? Icon(
                      color == null ? Icons.close : Icons.check,
                      size: 18,
                      color: color == HomeHairColor.pastelPink || color == null
                          ? AppColors.textDark
                          : Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
