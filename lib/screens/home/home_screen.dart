import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/data/hair_style.dart';
import '../../app/data/hair_style_api.dart' show loadHairStyles;
import '../../app/theme.dart';
import 'home_article_thumbnail.dart';
import 'home_articles.dart';
import 'home_care_detail_screen.dart';
import 'home_care_treatments.dart';
import 'home_data.dart';
import 'home_detail_screens.dart';
import 'home_hair_repository.dart';
import 'home_recommendations.dart';

enum _HomeCategory { all, trending, color, short, long }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.loadStyles = loadHomeHairStyles});

  final Future<List<HairStyle>> Function() loadStyles;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _carousel = ScrollController();
  final _articleCarousel = ScrollController();
  _HomeCategory _category = _HomeCategory.all;
  bool _showAll = false;
  bool _canLeft = false, _canRight = false;
  bool _articlesCanLeft = false,
      _articlesCanRight = false,
      _showAllArticles = false;
  bool _openingStyle = false;
  HomeArticle? _selectedArticle;
  String _query = '';
  List<HomeHairStyle> _styles = const [];
  HomeRecommendations _recommendations = const HomeRecommendations();
  bool _loadingStyles = true;
  String? _stylesError;

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
    _loadStyles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtons();
      _updateArticleScrollButtons();
    });
  }

  Future<void> _loadStyles() async {
    setState(() {
      _loadingStyles = true;
      _stylesError = null;
    });
    try {
      final styles = await widget.loadStyles();
      if (!mounted) return;
      final homeStyles = [for (final style in styles) HomeHairStyle(style)];
      final recommendations = HomeRecommendations.pick(homeStyles);
      setState(() {
        _styles = homeStyles;
        _recommendations = recommendations;
        _loadingStyles = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollButtons();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _styles = const [];
        _recommendations = const HomeRecommendations();
        _loadingStyles = false;
        _stylesError = 'Không thể tải mẫu tóc. Vui lòng thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _carousel.dispose();
    _articleCarousel.dispose();
    super.dispose();
  }

  List<HomeHairStyle> get _categoryStyles => switch (_category) {
    _HomeCategory.trending => _recommendations.styles,
    _HomeCategory.color => _recommendations.colors,
    _ => _styles,
  };

  List<HomeHairStyle> get _filtered => _categoryStyles.where((style) {
    final categoryMatch = switch (_category) {
      _HomeCategory.all => true,
      _HomeCategory.trending => true,
      _HomeCategory.color => true,
      _HomeCategory.short => style.length == HomeHairLength.short,
      _HomeCategory.long => style.length == HomeHairLength.long,
    };
    final q = _query.trim().toLowerCase();
    return categoryMatch &&
        (q.isEmpty ||
            style.name.toLowerCase().contains(q) ||
            style.source.name.toLowerCase().contains(q) ||
            style.description.toLowerCase().contains(q));
  }).toList();

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

  Future<void> _showStyle(HomeHairStyle style) async {
    if (_openingStyle) return;
    _openingStyle = true;
    try {
      // The existing Detail resolves IDs from the cache filled by this loader.
      final loaded = await loadHairStyles();
      if (!mounted) return;
      final product = loaded
          ? hairStyles.where((item) => item.id == style.id).firstOrNull
          : null;
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loaded
                  ? 'Không tìm thấy mẫu tóc này.'
                  : 'Không thể tải chi tiết mẫu tóc. Vui lòng thử lại.',
            ),
          ),
        );
        return;
      }
      if (style.variantColor != null &&
          !product.colors.contains(style.variantColor)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Màu tóc này hiện không còn khả dụng.')),
        );
        return;
      }
      final color = product.colorFor([style.displayColor]);
      await context.push<void>(
        '/styles/${Uri.encodeComponent(product.id)}?color=${color.name}',
      );
    } finally {
      _openingStyle = false;
    }
  }

  void _showArticle(HomeArticle article) => setState(() {
    _selectedArticle = article;
  });

  void _goBackToHome() => setState(() {
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
      constraints: const BoxConstraints(minHeight: 190),
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
              homeBannerImageUrl,
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
              mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: Text(
                        'Khám phá xu hướng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
            Text(
              '${items.length} mẫu',
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
        if (_loadingStyles)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_stylesError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: AppColors.textGrey,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _stylesError!,
                  style: const TextStyle(color: AppColors.textGrey),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _loadStyles,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off,
                  color: AppColors.textGrey,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _styles.isEmpty
                      ? 'Chưa có mẫu tóc'
                      : 'Chưa tìm thấy kiểu tóc phù hợp',
                  style: const TextStyle(color: AppColors.textGrey),
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

  void _showCareTreatment(HomeCareTreatment treatment) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (detailContext) => HomeCareDetailScreen(
          treatment: treatment,
          onBook: () {
            Navigator.of(detailContext).pop();
            context.go('/booking');
          },
        ),
      ),
    );
  }

  Widget _careSection(BuildContext context, bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Chăm sóc tóc tại LUNAS', style: AppTheme.titleFont(size: 22)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showCareTreatment(deepRepairTreatment),
              child: _careCard(
                Icons.spa_outlined,
                'Phục hồi chuyên sâu',
                'Nuôi dưỡng tóc khô xơ, lấy lại độ bóng khỏe.',
                const Color(0xFFE5F0EB),
                wide,
              ),
            ),
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showCareTreatment(softMoistureTreatment),
              child: _careCard(
                Icons.water_drop_outlined,
                'Dưỡng tóc mềm mượt',
                'Liệu trình chăm sóc nhẹ nhàng theo chất tóc.',
                const Color(0xFFF7E8E8),
                wide,
              ),
            ),
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
        Stack(
          children: [
            SingleChildScrollView(
              controller: _articleCarousel,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 230),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var index = 0;
                        index < homeArticles.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 12),
                        SizedBox(
                          width: wide ? 280 : 250,
                          child: _articleCard(homeArticles[index]),
                        ),
                      ],
                    ],
                  ),
                ),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: expanded ? 1.35 : 1.85,
              child: HomeArticleThumbnail(article: article),
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
