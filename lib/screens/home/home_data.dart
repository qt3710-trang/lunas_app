import 'package:flutter/material.dart';

import '../../app/data/hair_style.dart';

enum HomeHairLength { short, shoulder, long }

enum HomeHairType { layer, bob, pixie, wolfCut, hushCut, curly, straight }

enum HomeHairColor {
  milkTea('Nâu trà sữa', Color(0xFFB98668)),
  wine('Đỏ rượu', Color(0xFF873D4B)),
  ashBrown('Nâu lạnh', Color(0xFF81756C)),
  naturalBlack('Đen tự nhiên', Color(0xFF352C29)),
  caramel('Nâu caramel', Color(0xFFB7784C)),
  chocolate('Nâu socola', Color(0xFF634638)),
  pastelPink('Hồng pastel', Color(0xFFD99DAA));

  const HomeHairColor(this.label, this.color);
  final String label;
  final Color color;
}

/// Keeps Home's presentation backed by the same model used by Styles.
class HomeHairStyle {
  const HomeHairStyle(this.source, {this.selectedColor, this.variantColor});

  final HairStyle source;
  final HomeHairColor? selectedColor;
  final HairColor? variantColor;

  String get id => source.id;
  String get name => variantColor?.label ?? source.name;
  String get description => source.description;
  HomeHairLength get length => switch (source.length) {
    HairLength.short => HomeHairLength.short,
    HairLength.medium => HomeHairLength.shoulder,
    HairLength.long => HomeHairLength.long,
  };
  Set<HomeHairType> get hairStyles => {
    for (final type in source.types) HomeHairType.values.byName(type.name),
  };

  HairColor get displayColor =>
      source.colorFor([?(variantColor ?? selectedColor?.sourceColor)]);

  String get image {
    final value = source.imageFor(displayColor)?.trim() ?? '';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme) ||
        {'localhost', '127.0.0.1', '10.0.2.2', '[::1]'}.contains(uri.host)) {
      return '';
    }
    return value;
  }

  Color get color => displayColor.color;
  bool get trending => source.isTrending;
  bool get colorTrending => source.isTrending && source.colors.length > 1;

  bool hasColor(HomeHairColor color) {
    final mapped = color.sourceColor;
    return mapped != null &&
        (variantColor == null || variantColor == mapped) &&
        source.colors.contains(mapped);
  }

  HomeHairStyle withColor(HomeHairColor? color) =>
      HomeHairStyle(source, selectedColor: color, variantColor: variantColor);
}

/// Approved grouping for Home's existing shade labels; no pink exists in Firestore.
extension HomeHairColorMapping on HomeHairColor {
  HairColor? get sourceColor => switch (this) {
    HomeHairColor.milkTea ||
    HomeHairColor.ashBrown ||
    HomeHairColor.caramel ||
    HomeHairColor.chocolate => HairColor.brown,
    HomeHairColor.wine => HairColor.red,
    HomeHairColor.naturalBlack => HairColor.black,
    HomeHairColor.pastelPink => null,
  };
}

// Editorial banner artwork is independent of the product catalogue.
const homeBannerImageUrl =
    'https://media.comem.vn/uploads/2024/01/toc-xoan-dai-nu-32.webp';
