import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'home_articles.dart';
import 'home_data.dart';
import 'home_detail_screens.dart';
import 'home_filter_sheet.dart';

enum _HomeCategory { all, trending, color, short, long }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _carousel = ScrollController();
  final _articleCarousel = ScrollController();
  _HomeCategory _category = _HomeCategory.all;
  HomeHairFilter _hairFilter = const HomeHairFilter();
  bool _showAll = false;
  bool _canLeft = false, _canRight = false;
  bool _articlesCanLeft = false,
      _articlesCanRight = false,
      _showAllArticles = false;
  HomeHairStyle? _selectedStyle;
  HomeArticle? _selectedArticle;
  String _query = '';

  static const _categories = [
    ('Tất cả', _HomeCategory.all),
    ('Kiểu tóc hot', _HomeCategory.trending),
    ('Màu tóc hot', _HomeCategory.color),
    ('Tóc ngắn', _HomeCategory.short),
    ('Tóc dài', _HomeCategory.long),
  ];

  @override
  void initState() {
    super.initState();
    _carousel.addListener(_updateScrollButtons);
    _articleCarousel.addListener(_updateArticleScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtons();
      _updateArticleScrollButtons();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _carousel.dispose();
    _articleCarousel.dispose();
    super.dispose();
  }

  List<HomeHairStyle> get _filtered => homeHairStyles.where((style) {
    final categoryMatch = switch (_category) {
      _HomeCategory.all => true,
      _HomeCategory.trending => style.trending,
      _HomeCategory.color => style.colorTrending,
      _HomeCategory.short => style.length != HomeHairLength.long,
      _HomeCategory.long => style.length == HomeHairLength.long,
    };
    final matchesHairFilter = _hairFilter.matches(style);
    final q = _query.trim().toLowerCase();
    return categoryMatch &&
        matchesHairFilter &&
        (q.isEmpty ||
            style.name.toLowerCase().contains(q) ||
            style.description.toLowerCase().contains(q));
  }).toList();

  Future<void> _openHairFilter() async {
    final selected = await showHomeHairFilterSheet(
      context,
      initialFilter: _hairFilter,
      styles: homeHairStyles,
    );
    if (!mounted || selected == null) return;
    setState(() => _hairFilter = selected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carousel.hasClients) {
        _carousel.jumpTo(0);
      }
      _updateScrollButtons();
    });
  }

  void _updateScrollButtons() {
    if (!mounted || !_carousel.hasClients || _showAll) return;
    final p = _carousel.position;
    final left = p.pixels > 1,
        right = p.maxScrollExtent > 1 && p.pixels < p.maxScrollExtent - 1;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _changeCategory(_HomeCategory value) {
    setState(() {
      _category = value;
      _showAll = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carousel.hasClients) {
        _carousel.jumpTo(0);
      }
      _updateScrollButtons();
    });
  }

  void _searchChanged(String value) {
    setState(() {
      _query = value;
      _showAll = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carousel.hasClients) {
        _carousel.jumpTo(0);
      }
      _updateScrollButtons();
    });
  }

  void _showStyle(HomeHairStyle style) => setState(() {
    _selectedArticle = null;
    _selectedStyle = style;
  });

  void _showArticle(HomeArticle article) => setState(() {
    _selectedStyle = null;
    _selectedArticle = article;
  });

  void _goBackToHome() => setState(() {
    _selectedStyle = null;
    _selectedArticle = null;
  });

  void _updateArticleScrollButtons() {
    if (!mounted || !_articleCarousel.hasClients || _showAllArticles) return;
    final p = _articleCarousel.position;
    final left = p.pixels > 1;
    final right = p.maxScrollExtent > 1 && p.pixels < p.maxScrollExtent - 1;
    if (left != _articlesCanLeft || right != _articlesCanRight) {
      setState(() {
        _articlesCanLeft = left;
        _articlesCanRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStyle case final style?) {
      return HomeStyleDetailScreen(
        style: style,
        onBack: _goBackToHome,
        onSelectStyle: _showStyle,
      );
    }
    if (_selectedArticle case final article?) {
      return HomeArticleDetailScreen(
        article: article,
        onBack: _goBackToHome,
        onSelectArticle: _showArticle,
      );
    }
    final items = _filtered;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 700;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        18,
                        wide ? 32 : 20,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _header(context)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        20,
                        wide ? 32 : 20,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _hero(context)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        30,
                        wide ? 32 : 20,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _collection(context, items, wide),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        32,
                        wide ? 32 : 20,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _careSection(context, wide),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        24,
                        wide ? 32 : 20,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _inspiration()),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        30,
                        wide ? 32 : 20,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _news(wide)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 20,
                        24,
                        wide ? 32 : 20,
                        36,
                      ),
                      sliver: SliverToBoxAdapter(child: _bookingCta(context)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1D9D9),
            ),
            child: const Icon(Icons.face_3_outlined, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào bạn,',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                Text(
                  'Hôm nay bạn muốn đổi kiểu tóc?',
                  style: AppTheme.titleFont(size: 19),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn đã cập nhật những xu hướng mới nhất.'),
              ),
            ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _search,
        onChanged: _searchChanged,
        decoration: InputDecoration(
          hintText: 'Tìm kiểu tóc bạn yêu thích',
          prefixIcon: const Icon(Icons.search, color: AppColors.teal),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    _searchChanged('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );

  Widget _hero(BuildContext context) => InkWell(
    onTap: () {
      _changeCategory(_HomeCategory.trending);
    },
    borderRadius: BorderRadius.circular(24),
    child: Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF376F70), Color(0xFF83AFA5)],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: 0,
            bottom: 0,
            width: 150,
            child: Image.network(
              homeHairStyles[0].image,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF376F70),
                    const Color(0xFF376F70).withValues(alpha: .82),
                    Colors.transparent,
                  ],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LUNAS EDIT · TUẦN NÀY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hot nhất\ntuần này',
                  style: AppTheme.titleFont(size: 27, color: Colors.white),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Những kiểu tóc đang được yêu thích',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Text(
                      'Khám phá xu hướng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 15),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _collection(
    BuildContext context,
    List<HomeHairStyle> items,
    bool wide,
  ) {
    final cardWidth = wide ? 220.0 : 166.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ sưu tập tháng này',
                    style: AppTheme.titleFont(size: 23),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _query.isEmpty
                        ? 'Tìm cảm hứng mới cho mái tóc của bạn'
                        : '${items.length} kết quả phù hợp',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${items.length} mẫu',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Bộ lọc mẫu tóc',
                  visualDensity: VisualDensity.compact,
                  onPressed: _openHairFilter,
                  icon: Icon(
                    _hairFilter.isDefault
                        ? Icons.tune_rounded
                        : Icons.filter_alt_rounded,
                    color: AppColors.teal,
                    size: 21,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (label, category) in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _category == category,
                    onSelected: (_) => _changeCategory(category),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: _category == category
                          ? Colors.white
                          : AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    selectedColor: AppColors.teal,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _category == category
                          ? AppColors.teal
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, color: AppColors.textGrey, size: 32),
                SizedBox(height: 8),
                Text(
                  'Chưa tìm thấy kiểu tóc phù hợp',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          )
        else if (_showAll)
          LayoutBuilder(
            builder: (context, c) {
              final count = c.maxWidth >= 850
                  ? 4
                  : c.maxWidth >= 580
                  ? 3
                  : 2;
              final width = (c.maxWidth - (count - 1) * 12) / count;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _HairCard(
                        style: item,
                        onTap: () => _showStyle(item),
                        compact: true,
                      ),
                    ),
                ],
              );
            },
          )
        else
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                ListView.separated(
                  controller: _carousel,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: cardWidth,
                    child: _HairCard(
                      style: items[index],
                      onTap: () => _showStyle(items[index]),
                    ),
                  ),
                ),
                if (_canLeft)
                  Positioned(
                    left: 4,
                    top: 78,
                    child: _arrow(
                      Icons.chevron_left,
                      () => _carousel.animateTo(
                        (_carousel.offset - cardWidth - 12)
                            .clamp(0, _carousel.position.maxScrollExtent)
                            .toDouble(),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                if (_canRight)
                  Positioned(
                    right: 4,
                    top: 78,
                    child: _arrow(
                      Icons.chevron_right,
                      () => _carousel.animateTo(
                        (_carousel.offset + cardWidth + 12)
                            .clamp(0, _carousel.position.maxScrollExtent)
                            .toDouble(),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (items.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showAll = !_showAll);
                if (!_showAll) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_carousel.hasClients) {
                      _carousel.jumpTo(0);
                    }
                    _updateScrollButtons();
                  });
                }
              },
              icon: Icon(
                _showAll ? Icons.expand_less : Icons.expand_more,
                size: 19,
              ),
              label: Text(
                _showAll ? 'Thu gọn' : 'Xem thêm ${items.length} mẫu',
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
            ),
          ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    elevation: 3,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: AppColors.teal),
      ),
    ),
  );

  Widget _careSection(BuildContext context, bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Chăm sóc tóc tại LUNAS', style: AppTheme.titleFont(size: 22)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _careCard(
            Icons.spa_outlined,
            'Phục hồi chuyên sâu',
            'Nuôi dưỡng tóc khô xơ, lấy lại độ bóng khỏe.',
            const Color(0xFFE5F0EB),
            wide,
          ),
          _careCard(
            Icons.water_drop_outlined,
            'Dưỡng tóc mềm mượt',
            'Liệu trình chăm sóc nhẹ nhàng theo chất tóc.',
            const Color(0xFFF7E8E8),
            wide,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => context.go('/booking'),
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('Tư vấn & đặt lịch'),
        ),
      ),
    ],
  );
  Widget _careCard(
    IconData icon,
    String title,
    String text,
    Color color,
    bool wide,
  ) => SizedBox(
    width: wide ? 330 : null,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.teal),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _inspiration() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFFF3DDD8), Color(0xFFF8EEE5)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHĂM MÌNH THEO CÁCH CỦA BẠN',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.teal,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Mái tóc đẹp bắt đầu\ntừ cảm giác là chính mình.',
          style: AppTheme.titleFont(size: 23),
        ),
        const SizedBox(height: 8),
        const Text(
          'Một chút thay đổi, thêm nhiều tự tin.',
          style: TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _news(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text('Góc làm đẹp', style: AppTheme.titleFont(size: 22)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _showAllArticles = !_showAllArticles);
              if (!_showAllArticles) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_articleCarousel.hasClients) _articleCarousel.jumpTo(0);
                  _updateArticleScrollButtons();
                });
              }
            },
            child: Text(_showAllArticles ? 'Thu gọn' : 'Xem tất cả'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_showAllArticles)
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 850
                ? 4
                : constraints.maxWidth >= 580
                ? 3
                : 2;
            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final article in homeArticles)
                  SizedBox(
                    width: cardWidth,
                    child: _articleCard(article, expanded: true),
                  ),
              ],
            );
          },
        )
      else
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              ListView.separated(
                controller: _articleCarousel,
                scrollDirection: Axis.horizontal,
                itemCount: homeArticles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: wide ? 280 : 250,
                  child: _articleCard(homeArticles[index]),
                ),
              ),
              if (_articlesCanLeft)
                Positioned(
                  left: 4,
                  top: 84,
                  child: _arrow(
                    Icons.chevron_left,
                    () => _articleCarousel.animateTo(
                      (_articleCarousel.offset - 262)
                          .clamp(0, _articleCarousel.position.maxScrollExtent)
                          .toDouble(),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
              if (_articlesCanRight)
                Positioned(
                  right: 4,
                  top: 84,
                  child: _arrow(
                    Icons.chevron_right,
                    () => _articleCarousel.animateTo(
                      (_articleCarousel.offset + 262)
                          .clamp(0, _articleCarousel.position.maxScrollExtent)
                          .toDouble(),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _articleCard(HomeArticle article, {bool expanded = false}) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: () => _showArticle(article),
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: expanded ? 1.35 : 1.85,
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.tealLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.spa_outlined,
                    color: AppColors.teal,
                    size: 38,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.topic,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: .8,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey,
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

  Widget _bookingCta(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF376F70),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Một ngày dành riêng cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Đặt lịch tại LUNAS Hair Studio',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: () => context.go('/booking'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.teal,
          ),
          child: const Text('Đặt lịch'),
        ),
      ],
    ),
  );
}

class _HairCard extends StatelessWidget {
  const _HairCard({
    required this.style,
    required this.onTap,
    this.compact = false,
  });
  final HomeHairStyle style;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C263B3B),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: compact ? 1.12 : .94,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: style.color.withValues(alpha: .2),
                    child: Image.network(
                      style.image,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.face_3_outlined,
                          size: 58,
                          color: style.color.withValues(alpha: .8),
                        ),
                      ),
                    ),
                  ),
                  if (style.trending)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.pink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    switch (style.length) {
                      HomeHairLength.short => 'TÓC NGẮN',
                      HomeHairLength.shoulder => 'TÓC NGANG VAI',
                      HomeHairLength.long => 'TÓC DÀI',
                    },
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: .7,
                      color: AppColors.textGrey,
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
}
