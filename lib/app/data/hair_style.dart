import 'package:flutter/material.dart';

/// Độ dài tóc.
enum HairLength {
  short('Tóc ngắn'),
  medium('Tóc ngang vai'),
  long('Tóc dài');

  const HairLength(this.label);
  final String label;
}

/// Kiểu tóc.
enum HairType {
  layer('Layer'),
  bob('Bob'),
  pixie('Tóc tém'),
  wolfCut('Wolf Cut'),
  hushCut('Hush Cut'),
  curly('Tóc uốn'),
  straight('Tóc thẳng');

  const HairType(this.label);
  final String label;
}

/// Màu tóc, kèm mã màu để vẽ chấm tròn / ảnh mẫu.
enum HairColor {
  milkTea('Nâu trà sữa', Color(0xFFA67B5B)),
  wine('Đỏ rượu', Color(0xFF8E2C3E)),
  ashBrown('Nâu lạnh', Color(0xFF8B7D6B)),
  naturalBlack('Đen tự nhiên', Color(0xFF2B2522)),
  caramel('Nâu caramel', Color(0xFFB5733A)),
  chocolate('Nâu socola', Color(0xFF5A3A2A)),
  pastelPink('Hồng pastel', Color(0xFFE3A9B4));

  const HairColor(this.label, this.color);
  final String label;
  final Color color;
}

/// Dịp sử dụng.
enum HairOccasion {
  daily('Hằng ngày'),
  work('Đi làm'),
  school('Đi học'),
  party('Tiệc / Sự kiện'),
  travel('Du lịch');

  const HairOccasion(this.label);
  final String label;
}

/// Độ phổ biến (cách sắp xếp kết quả).
enum HairSort {
  all('Tất cả'),
  popular('Phổ biến nhất'),
  newest('Mới nhất');

  const HairSort(this.label);
  final String label;
}

/// Một mẫu tóc trong bộ sưu tập.
class HairStyle {
  const HairStyle({
    required this.id,
    required this.name,
    required this.color,
    required this.length,
    required this.types,
    this.occasions = const {HairOccasion.daily},
    this.likes = 0,
  });

  final String id;
  final String name;
  final HairColor color;
  final HairLength length;
  final Set<HairType> types;
  final Set<HairOccasion> occasions;
  final int likes; // lượt yêu thích, dùng cho "Phổ biến nhất"

  /// Kiểu tóc chính, dùng để lấy mô tả / giá tạm.
  HairType get mainType => types.first;

  bool get isTrending => likes >= 700;

  String get tagline => switch (mainType) {
        HairType.layer => 'Tóc layer bồng bềnh',
        HairType.bob => 'Bob gọn gàng, trẻ trung',
        HairType.pixie => 'Tóc tém cá tính',
        HairType.wolfCut => 'Wolf cut phá cách',
        HairType.hushCut => 'Hush cut mềm mại',
        HairType.curly => 'Tóc uốn bồng bềnh',
        HairType.straight => 'Tóc thẳng suôn mượt',
      };

  String get description => switch (mainType) {
        HairType.layer =>
          'Kiểu tóc layer nhiều tầng tạo độ bồng bềnh tự nhiên, giúp tổng thể mềm mại và hiện đại. Phù hợp với những ai yêu thích phong cách thanh lịch nhưng vẫn trẻ trung.',
        HairType.bob =>
          'Tóc bob ôm gọn khuôn mặt, giúp gương mặt thon gọn và trẻ trung hơn. Dễ chăm sóc, hợp đi học và đi làm.',
        HairType.pixie =>
          'Tóc tém ngắn cá tính, tôn đường nét gương mặt và chiếc cổ thon. Gọn gàng, mát mẻ, rất ít tốn thời gian tạo kiểu.',
        HairType.wolfCut =>
          'Wolf cut cắt tầng phá cách với phần đỉnh bồng và đuôi tỉa mỏng, mang lại vẻ năng động, cá tính.',
        HairType.hushCut =>
          'Hush cut tỉa tầng nhẹ quanh mặt, tạo cảm giác bồng bềnh mềm mại mà vẫn tự nhiên, dễ để kiểu hằng ngày.',
        HairType.curly =>
          'Tóc uốn sóng mềm giúp mái tóc trông dày và bồng bềnh hơn, mang lại vẻ nữ tính, quyến rũ.',
        HairType.straight =>
          'Tóc thẳng suôn mượt, đơn giản mà thanh lịch, giữ nếp lâu và phù hợp nhiều hoàn cảnh.',
      };

  List<String> get tags => switch (mainType) {
        HairType.layer || HairType.hushCut => ['Thanh lịch', 'Tự nhiên', 'Dễ tạo kiểu'],
        HairType.bob || HairType.straight => ['Gọn gàng', 'Trẻ trung', 'Dễ chăm sóc'],
        HairType.pixie || HairType.wolfCut => ['Cá tính', 'Năng động', 'Mát mẻ'],
        HairType.curly => ['Nữ tính', 'Bồng bềnh', 'Quyến rũ'],
      };

  String get duration => types.contains(HairType.curly)
      ? '90–120 phút'
      : switch (length) {
          HairLength.short => '30–45 phút',
          HairLength.medium => '45–60 phút',
          HairLength.long => '60–90 phút',
        };

  String get price => switch (mainType) {
        HairType.pixie || HairType.bob || HairType.straight => 'Từ 180.000đ',
        HairType.layer => 'Từ 250.000đ',
        HairType.wolfCut || HairType.hushCut => 'Từ 300.000đ',
        HairType.curly => 'Từ 450.000đ',
      };
}

/// Bộ lọc mẫu tóc. Set rỗng nghĩa là "Tất cả".
class GalleryFilter {
  const GalleryFilter({
    this.lengths = const {},
    this.types = const {},
    this.colors = const {},
    this.occasions = const {},
    this.sort = HairSort.all,
  });

  final Set<HairLength> lengths;
  final Set<HairType> types;
  final Set<HairColor> colors;
  final Set<HairOccasion> occasions;
  final HairSort sort;

  bool get isEmpty =>
      lengths.isEmpty &&
      types.isEmpty &&
      colors.isEmpty &&
      occasions.isEmpty &&
      sort == HairSort.all;

  bool matches(HairStyle s) =>
      (lengths.isEmpty || lengths.contains(s.length)) &&
      (types.isEmpty || types.any(s.types.contains)) &&
      (colors.isEmpty || colors.contains(s.color)) &&
      (occasions.isEmpty || occasions.any(s.occasions.contains));

  /// Sắp xếp theo độ phổ biến. Mẫu nằm cuối danh sách được coi là mới nhất.
  List<HairStyle> sorted(List<HairStyle> items) => switch (sort) {
        HairSort.all => items,
        HairSort.popular => [...items]..sort((a, b) => b.likes.compareTo(a.likes)),
        HairSort.newest => items.reversed.toList(),
      };

  GalleryFilter copyWith({
    Set<HairLength>? lengths,
    Set<HairType>? types,
    Set<HairColor>? colors,
    Set<HairOccasion>? occasions,
    HairSort? sort,
  }) =>
      GalleryFilter(
        lengths: lengths ?? this.lengths,
        types: types ?? this.types,
        colors: colors ?? this.colors,
        occasions: occasions ?? this.occasions,
        sort: sort ?? this.sort,
      );
}

/// Dữ liệu mẫu tạm, sau này thay bằng dữ liệu từ server.
const hairStyles = <HairStyle>[
  HairStyle(id: 'butterfly-layer', name: 'Butterfly Layer', color: HairColor.milkTea, length: HairLength.long, types: {HairType.layer}, occasions: {HairOccasion.daily, HairOccasion.party}, likes: 980),
  HairStyle(id: 'bob-han-quoc', name: 'Bob Hàn Quốc', color: HairColor.wine, length: HairLength.short, types: {HairType.bob, HairType.straight}, occasions: {HairOccasion.work, HairOccasion.school}, likes: 760),
  HairStyle(id: 'pixie-cut', name: 'Pixie Cut', color: HairColor.ashBrown, length: HairLength.short, types: {HairType.pixie}, occasions: {HairOccasion.daily, HairOccasion.travel}, likes: 540),
  HairStyle(id: 'long-layer', name: 'Long Layer', color: HairColor.naturalBlack, length: HairLength.long, types: {HairType.layer, HairType.straight}, occasions: {HairOccasion.work}, likes: 820),
  HairStyle(id: 'hush-cut', name: 'Hush Cut', color: HairColor.caramel, length: HairLength.medium, types: {HairType.hushCut}, occasions: {HairOccasion.daily, HairOccasion.school}, likes: 910),
  HairStyle(id: 'soft-wolf-cut', name: 'Soft Wolf Cut', color: HairColor.chocolate, length: HairLength.medium, types: {HairType.wolfCut}, occasions: {HairOccasion.travel}, likes: 470),
  HairStyle(id: 'layer-dai', name: 'Layer dài', color: HairColor.milkTea, length: HairLength.long, types: {HairType.layer}, occasions: {HairOccasion.daily}, likes: 650),
  HairStyle(id: 'layer-uon-nhe', name: 'Layer uốn nhẹ', color: HairColor.milkTea, length: HairLength.long, types: {HairType.layer, HairType.curly}, occasions: {HairOccasion.party}, likes: 720),
  HairStyle(id: 'hush-cut-layer', name: 'Hush Cut layer', color: HairColor.milkTea, length: HairLength.long, types: {HairType.hushCut, HairType.layer}, occasions: {HairOccasion.school}, likes: 880),
  HairStyle(id: 'soft-layer', name: 'Soft Layer', color: HairColor.caramel, length: HairLength.long, types: {HairType.layer}, occasions: {HairOccasion.work, HairOccasion.daily}, likes: 590),
  HairStyle(id: 'layer-mai-bay', name: 'Layer mái bay', color: HairColor.milkTea, length: HairLength.long, types: {HairType.layer}, occasions: {HairOccasion.travel}, likes: 430),
  HairStyle(id: 'bob-xoan', name: 'Bob uốn cụp', color: HairColor.chocolate, length: HairLength.short, types: {HairType.bob, HairType.curly}, occasions: {HairOccasion.work}, likes: 380),
  HairStyle(id: 'wolf-cut-ngan', name: 'Wolf Cut ngắn', color: HairColor.naturalBlack, length: HairLength.short, types: {HairType.wolfCut}, occasions: {HairOccasion.travel, HairOccasion.daily}, likes: 610),
  HairStyle(id: 'tem-ca-tinh', name: 'Tóc tém cá tính', color: HairColor.pastelPink, length: HairLength.short, types: {HairType.pixie}, occasions: {HairOccasion.party}, likes: 350),
  HairStyle(id: 'thang-ngang-vai', name: 'Thẳng ngang vai', color: HairColor.naturalBlack, length: HairLength.medium, types: {HairType.straight}, occasions: {HairOccasion.school, HairOccasion.work}, likes: 500),
  HairStyle(id: 'uon-song-nuoc', name: 'Uốn sóng nước', color: HairColor.wine, length: HairLength.long, types: {HairType.curly}, occasions: {HairOccasion.party}, likes: 690),
  HairStyle(id: 'layer-ngang-vai', name: 'Layer ngang vai', color: HairColor.ashBrown, length: HairLength.medium, types: {HairType.layer}, occasions: {HairOccasion.daily}, likes: 410),
  HairStyle(id: 'hush-cut-caramel', name: 'Hush Cut ngắn', color: HairColor.caramel, length: HairLength.short, types: {HairType.hushCut}, occasions: {HairOccasion.travel}, likes: 560),
  HairStyle(id: 'bob-pastel', name: 'Bob pastel', color: HairColor.pastelPink, length: HairLength.short, types: {HairType.bob}, occasions: {HairOccasion.party, HairOccasion.travel}, likes: 330),
  HairStyle(id: 'uon-de-dai', name: 'Uốn đuôi dài', color: HairColor.chocolate, length: HairLength.long, types: {HairType.curly, HairType.layer}, occasions: {HairOccasion.daily}, likes: 620),
];
