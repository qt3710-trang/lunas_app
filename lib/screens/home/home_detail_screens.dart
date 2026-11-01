import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'home_articles.dart';
import 'home_data.dart';

class HomeStyleDetailScreen extends StatelessWidget {
  const HomeStyleDetailScreen({
    super.key,
    required this.style,
    required this.styles,
    required this.onBack,
    required this.onSelectStyle,
  });
  final HomeHairStyle style;
  final List<HomeHairStyle> styles;
  final VoidCallback onBack;
  final ValueChanged<HomeHairStyle> onSelectStyle;

  @override
  Widget build(BuildContext context) {
    final similar = styles
        .where((item) => item.id != style.id && item.length == style.length)
        .take(4)
        .toList();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          style.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Image.network(
                style.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _ImageFallback(color: style.color),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(style.name, style: AppTheme.titleFont(size: 25)),
          const SizedBox(height: 8),
          Text(
            style.description,
            style: const TextStyle(color: AppColors.textGrey, height: 1.55),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoTag(switch (style.length) {
                HomeHairLength.short => 'Tóc ngắn',
                HomeHairLength.shoulder => 'Tóc ngang vai',
                HomeHairLength.long => 'Tóc dài',
              }),
              if (style.trending) const _InfoTag('Đang thịnh hành'),
              if (style.colorTrending) const _InfoTag('Màu được yêu thích'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Phong cách', style: AppTheme.titleFont(size: 19)),
          const SizedBox(height: 6),
          Text(
            style.length == HomeHairLength.short
                ? 'Gọn gàng, trẻ trung và dễ làm mới diện mạo. Hãy trao đổi với stylist về độ dài phù hợp với chất tóc và thói quen tạo kiểu của bạn.'
                : 'Mềm mại, linh hoạt và dễ biến tấu theo nhiều dịp. Stylist có thể điều chỉnh tầng tóc và độ uốn theo gương mặt, độ dày tóc của bạn.',
            style: const TextStyle(color: AppColors.textGrey, height: 1.5),
          ),
          const SizedBox(height: 20),
          Text('Gợi ý màu tóc', style: AppTheme.titleFont(size: 19)),
          const SizedBox(height: 8),
          Text(
            style.source.colors.map((color) => color.label).join(' · '),
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          Text('Có thể bạn cũng thích', style: AppTheme.titleFont(size: 19)),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: similar.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 145,
                child: _RelatedStyleCard(
                  style: similar[index],
                  onTap: () => onSelectStyle(similar[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/booking'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Đặt lịch tư vấn'),
          ),
        ],
      ),
    );
  }
}

class HomeArticleDetailScreen extends StatelessWidget {
  const HomeArticleDetailScreen({
    super.key,
    required this.article,
    required this.onBack,
    required this.onSelectArticle,
  });
  final HomeArticle article;
  final VoidCallback onBack;
  final ValueChanged<HomeArticle> onSelectArticle;

  @override
  Widget build(BuildContext context) {
    final related = homeArticles
        .where((item) => article.relatedIds.contains(item.id))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Góc làm đẹp',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1.55,
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const _ImageFallback(color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            article.topic,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              color: AppColors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(article.title, style: AppTheme.titleFont(size: 25)),
          const SizedBox(height: 10),
          Text(
            article.summary,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          for (final paragraph in article.body.split('\n\n')) ...[
            Text(paragraph, style: const TextStyle(height: 1.7, fontSize: 14)),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          Text('Bài viết liên quan', style: AppTheme.titleFont(size: 19)),
          const SizedBox(height: 10),
          for (final item in related)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RelatedArticleCard(
                article: item,
                onTap: () => onSelectArticle(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelatedStyleCard extends StatelessWidget {
  const _RelatedStyleCard({required this.style, required this.onTap});
  final HomeHairStyle style;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            width: 145,
            child: Image.network(
              style.image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _ImageFallback(color: style.color),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          style.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({required this.article, required this.onTap});
  final HomeArticle article;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 78,
                height: 70,
                child: Image.network(
                  article.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const _ImageFallback(color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.topic,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: .7,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 10,
                    ),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    color: color.withValues(alpha: .16),
    alignment: Alignment.center,
    child: Icon(Icons.spa_outlined, color: color, size: 42),
  );
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.tealLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.teal,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
