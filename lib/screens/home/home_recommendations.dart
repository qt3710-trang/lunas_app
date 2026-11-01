import 'dart:math';

import '../../app/data/hair_style.dart';
import 'home_data.dart';

/// One selection per successful Home catalogue load, independent of rebuilds.
class HomeRecommendations {
  const HomeRecommendations({this.styles = const [], this.colors = const []});

  final List<HomeHairStyle> styles;
  final List<HomeHairStyle> colors;

  factory HomeRecommendations.pick(
    Iterable<HomeHairStyle> catalogue, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final products = <String, HomeHairStyle>{
      for (final item in catalogue)
        if (item.id.trim().isNotEmpty &&
            item.id != 'null' &&
            item.source.name.trim().isNotEmpty)
          item.id: item,
    }.values.toList();
    final styles = products.where((item) => item.image.isNotEmpty).toList()
      ..shuffle(rng);

    final byColor = <HairColor, List<HomeHairStyle>>{};
    for (final item in products) {
      // Only explicit color images belong to a known Firebase variant.
      for (final color in item.source.colorImages.keys) {
        if (!item.source.colors.contains(color)) continue;
        final variant = HomeHairStyle(item.source, variantColor: color);
        if (variant.image.isEmpty) continue;
        (byColor[color] ??= []).add(variant);
      }
    }
    final colors = byColor.keys.toList()..shuffle(rng);
    return HomeRecommendations(
      styles: List.unmodifiable(styles.take(5)),
      colors: List.unmodifiable([
        for (final color in colors.take(5))
          byColor[color]![rng.nextInt(byColor[color]!.length)],
      ]),
    );
  }
}
