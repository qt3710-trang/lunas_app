import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/data/favorite_styles.dart';
import '../../app/data/collection_styles.dart';
import '../../app/data/hair_style.dart';
import '../../app/data/hair_style_api.dart';
import '../../app/theme.dart';
import 'gallery_filter_sheet.dart';
import 'gallery_widgets.dart';

/// Danh mục kéo ngang ở đầu trang.
class _Category {
  const _Category(this.label, this.test);

  final String label;
  final bool Function(HairStyle) test;
}

final _categories = <_Category>[
  _Category('Tất cả', (_) => true),
  _Category('Tóc ngắn', (s) => s.length == HairLength.short),
  _Category('Tóc dài', (s) => s.length == HairLength.long),
  _Category('Layer', (s) => s.types.contains(HairType.layer)),
  _Category('Tóc tém', (s) => s.types.contains(HairType.pixie)),
];

/// GD4: Mẫu – bộ sưu tập tóc xinh.
/// Search, danh mục, lưới mẫu nổi bật, màu tóc nổi bật, cuộn để xem thêm.
/// Thanh menu dưới do MainShell quản lý, màn này chỉ vẽ phần nội dung.
class StylesScreen extends StatefulWidget {
  const StylesScreen({super.key});

  @override
  State<StylesScreen> createState() => _StylesScreenState();
}

class _StylesScreenState extends State<StylesScreen> {
  static const _featuredCount = 6;
  static const _pageSize = 4;

  final _scroll = ScrollController();
  final _searchController = TextEditingController();

  String _query = '';
  int _category = 0;
  GalleryFilter _filter = const GalleryFilter();
  bool _favoritesOnly = false;
  bool _collectionOnly = false;

  // Số mẫu đang hiện ở phần "Khám phá thêm", tăng dần khi cuộn xuống cuối.
  int _moreCount = _pageSize;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    favoriteStyles.addListener(_onFavoritesChanged);
    collectionStyles.addListener(_onFavoritesChanged);
    loadHairStyles().then((ok) {
      if (ok && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    favoriteStyles.removeListener(_onFavoritesChanged);
    collectionStyles.removeListener(_onFavoritesChanged);
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Đang tìm kiếm / lọc thì hiện một lưới kết quả duy nhất.
  bool get _isRefined =>
      _query.isNotEmpty ||
      _category != 0 ||
      !_filter.isEmpty ||
      _favoritesOnly ||
      _collectionOnly;

  List<HairStyle> get _results {
    final q = _query.toLowerCase();
    return _filter.sorted(
      hairStyles.where((s) {
        return _categories[_category].test(s) &&
            _filter.matches(s) &&
            (!_favoritesOnly || favoriteStyles.contains(s.id)) &&
            (!_collectionOnly || collectionStyles.contains(s.id)) &&
            (q.isEmpty ||
                s.name.toLowerCase().contains(q) ||
                s.color.label.toLowerCase().contains(q));
      }).toList(),
    );
  }

  /// Mỗi điều kiện lọc đang bật thành một chip có nút × để bỏ riêng.
  List<(String, VoidCallback)> get _activeFilterChips {
    final f = _filter;
    void update(GalleryFilter next) => setState(() => _filter = next);
    return [
      for (final e in f.lengths)
        (e.label, () => update(f.copyWith(lengths: {...f.lengths}..remove(e)))),
      for (final e in f.types)
        (e.label, () => update(f.copyWith(types: {...f.types}..remove(e)))),
      for (final e in f.colors)
        (e.label, () => update(f.copyWith(colors: {...f.colors}..remove(e)))),
      for (final e in f.occasions)
        (
          e.label,
          () => update(f.copyWith(occasions: {...f.occasions}..remove(e))),
        ),
      if (f.sort != HairSort.all)
        (f.sort.label, () => update(f.copyWith(sort: HairSort.all))),
    ];
  }

  int get _moreTotal => hairStyles.length - _featuredCount;

  Future<void> _onScroll() async {
    if (_isRefined || _loadingMore || _moreCount >= _moreTotal) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 300)
      return;

    setState(() => _loadingMore = true);
    // Giả lập tải thêm từ server.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _moreCount = (_moreCount + _pageSize).clamp(0, _moreTotal);
      _loadingMore = false;
    });
  }

  // Danh sách đã lưu đổi (kể cả từ trang chi tiết) thì vẽ lại.
  void _onFavoritesChanged() => setState(() {});

  void _toggleFavorite(HairStyle s) => favoriteStyles.toggle(s.id);

  Future<void> _openFilter() async {
    final result = await showGalleryFilterSheet(context, _filter);
    if (result != null) setState(() => _filter = result);
  }

  void _openStyle(HairStyle s) => context.push('/styles/${s.id}');

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _buildCategories()),
            if (_isRefined) ..._buildResults(results) else ..._buildBrowse(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Bộ sưu tập ',
                        style: AppTheme.titleFont(
                          size: 24,
                          color: AppColors.teal,
                        ),
                      ),
                      TextSpan(
                        text: 'tóc xinh',
                        style: AppTheme.titleFont(size: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Khám phá phong cách dành riêng cho bạn.',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yêu thích',
            onPressed: () => setState(() {
              _favoritesOnly = !_favoritesOnly;
              if (_favoritesOnly) _collectionOnly = false;
            }),
            icon: Icon(
              _favoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _favoritesOnly ? AppColors.pink : AppColors.textDark,
            ),
          ),
          IconButton(
            tooltip: 'Bộ sưu tập của tôi',
            onPressed: () => setState(() {
              _collectionOnly = !_collectionOnly;
              if (_collectionOnly) _favoritesOnly = false;
            }),
            icon: Badge(
              isLabelVisible: collectionStyles.count > 0,
              backgroundColor: AppColors.teal,
              label: Text('${collectionStyles.count}'),
              child: Icon(
                Icons.collections_bookmark_outlined,
                color: _collectionOnly ? AppColors.teal : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v.trim()),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiểu tóc, màu tóc bạn yêu thích...',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GalleryChip(
          label: _categories[i].label,
          selected: _category == i,
          onTap: () => setState(() => _category = i),
        ),
      ),
    );
  }

  /// Chế độ duyệt mặc định: mẫu nổi bật, màu tóc nổi bật, khám phá thêm.
  List<Widget> _buildBrowse() {
    final featured = hairStyles.take(_featuredCount).toList();
    final more = hairStyles.skip(_featuredCount).take(_moreCount).toList();

    return [
      SliverToBoxAdapter(
        child: _SectionTitle(
          title: 'Mẫu tóc nổi bật',
          trailing: _FilterButton(onTap: _openFilter),
        ),
      ),
      _grid(featured),
      const SliverToBoxAdapter(child: _SectionTitle(title: 'Màu tóc nổi bật')),
      SliverToBoxAdapter(
        child: _HairColorStrip(
          onTap: (c) => setState(() => _filter = GalleryFilter(colors: {c})),
        ),
      ),
      const SliverToBoxAdapter(child: _SectionTitle(title: 'Khám phá thêm')),
      _grid(more),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: _loadingMore
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.teal,
                    ),
                  )
                : _moreCount >= _moreTotal
                ? const Text(
                    'Bạn đã xem hết mẫu tóc',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }

  /// Chế độ đã lọc / tìm kiếm: thanh "Đang lọc" + lưới kết quả.
  List<Widget> _buildResults(List<HairStyle> results) {
    return [
      if (!_filter.isEmpty)
        SliverToBoxAdapter(
          child: _ActiveFilterChips(
            chips: _activeFilterChips,
            onFilter: _openFilter,
          ),
        ),
      SliverToBoxAdapter(
        child: _SectionTitle(
          title: _collectionOnly
              ? 'Bộ sưu tập của tôi'
              : (_favoritesOnly ? 'Yêu thích' : 'Kết quả phù hợp'),
          subtitle: '(${results.length} mẫu)',
          // Đang lọc thì nút Lọc đã nằm cuối hàng chip.
          trailing: _filter.isEmpty ? _FilterButton(onTap: _openFilter) : null,
        ),
      ),
      if (results.isEmpty)
        const SliverToBoxAdapter(child: _EmptyResults())
      else
        _grid(results),
    ];
  }

  Widget _grid(List<HairStyle> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, i) {
          final s = items[i];
          return HairStyleCard(
            style: s,
            isFavorite: favoriteStyles.contains(s.id),
            onFavorite: () => _toggleFavorite(s),
            onTap: () => _openStyle(s),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.tune, size: 18),
      label: const Text('Lọc'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textDark,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Hàng chip điều kiện lọc đang bật (bấm × để bỏ), cuối hàng là nút Lọc.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.chips, required this.onFilter});

  final List<(String, VoidCallback)> chips;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        itemCount: chips.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == chips.length) return _FilterButton(onTap: onFilter);
          final (label, onRemove) = chips[i];
          return Material(
            color: AppColors.tealLight,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textDark,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dải màu tóc nổi bật kéo ngang, bấm để lọc theo màu.
class _HairColorStrip extends StatelessWidget {
  const _HairColorStrip({required this.onTap});

  final ValueChanged<HairColor> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HairColor.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = HairColor.values[i];
          return GestureDetector(
            onTap: () => onTap(c),
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 80,
                      width: 84,
                      child: HairThumb(color: c, iconSize: 0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textGrey),
          SizedBox(height: 12),
          Text(
            'Chưa có mẫu tóc phù hợp.\nThử đổi từ khóa hoặc bộ lọc nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
