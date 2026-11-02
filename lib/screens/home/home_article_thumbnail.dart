import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'home_articles.dart';

/// Thumbnail overrides belong only to Home, not to the article detail data.
class HomeArticleThumbnail extends StatelessWidget {
  const HomeArticleThumbnail({super.key, required this.article});

  final HomeArticle article;

  // Pexels License: https://www.pexels.com/license/
  // cottonbro studio: https://www.pexels.com/photo/person-washing-woman-s-hair-3993449/
  // Replaces the original thumbnail larger than 10 MB.
  // Nataliya Vaitkevich: https://www.pexels.com/photo/a-person-styling-a-woman-s-hair-8467969/
  // Replaces the original trends thumbnail, which returns HTTP 404.
  static const _overrides = {
    'healthy-hair-routine': 'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg?auto=compress&cs=tinysrgb&w=800',
    'hair-trends': 'https://images.pexels.com/photos/8467969/pexels-photo-8467969.jpeg?auto=compress&cs=tinysrgb&w=800',
  };

  static String imageUrlFor(HomeArticle article) =>
      (_overrides[article.id] ?? article.image).trim();

  @override
  Widget build(BuildContext context) {
    final url = imageUrlFor(article);
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        {'localhost', '127.0.0.1', '10.0.2.2', '[::1]'}.contains(uri.host)) {
      return _placeholder();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 1000,
      semanticLabel: 'Ảnh minh họa: ${article.title}',
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || frame != null ? child : _placeholder(loading: true),
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder({bool loading = false}) => Semantics(
    label: loading ? 'Đang tải ảnh bài viết' : 'Không tải được ảnh bài viết',
    child: Container(
      color: AppColors.tealLight,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.teal,
              ),
            )
          : const Icon(Icons.spa_outlined, color: AppColors.teal, size: 38),
    ),
  );
}
