import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Hàm phụ: tìm giá trị enum theo nhãn chữ (bỏ qua khoảng trắng và hoa/thường),
// dùng khi đọc dữ liệu JSON từ API.
// ---------------------------------------------------------------------------
String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

T? _byLabel<T>(Iterable<T> values, String Function(T) label, Object? raw) {
  if (raw == null) return null;
  final key = _norm(raw.toString());
  for (final v in values) {
    if (_norm(label(v)) == key) return v;
  }
  return null;
}

/// JSON có thể gửi mảng ["a","b"] hoặc chuỗi "a, b": gom về List<String>.
List<String> _asStrings(Object? v) {
  if (v is List) {
    return [for (final e in v) e.toString().trim()]
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (v is String) {
    return v
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return const [];
}

/// Độ dài tóc.
enum HairLength {
  short('Tóc ngắn'),
  medium('Tóc ngang vai'),
  long('Tóc dài');

  const HairLength(this.label);
  final String label;

  static HairLength? fromLabel(Object? raw) =>
      _byLabel<HairLength>(values, (e) => e.label, raw);
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

  static HairType? fromLabel(Object? raw) =>
      _byLabel<HairType>(values, (e) => e.label, raw);
}

/// Màu tóc, kèm mã màu để vẽ chấm tròn / ảnh mẫu.
enum HairColor {
  red('Đỏ', Color(0xFF8E1B3A)),
  black('Đen', Color(0xFF26262B)),
  brown('Nâu', Color(0xFF7B4B34)),
  gold('Vàng', Color(0xFFD4A24C));

  const HairColor(this.label, this.color);
  final String label;
  final Color color;

  static HairColor? fromLabel(Object? raw) =>
      _byLabel<HairColor>(values, (e) => e.label, raw);
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

  static HairOccasion? fromLabel(Object? raw) =>
      _byLabel<HairOccasion>(values, (e) => e.label, raw);
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
/// Một mẫu có thể có nhiều màu: [colors] (màu đầu tiên là màu mặc định).
class HairStyle {
  HairStyle({
    required this.id,
    required this.name,
    required this.colors,
    required this.length,
    required this.types,
    this.occasions = const {HairOccasion.daily},
    this.likes = 0,
    this.isNew = false,
    this.imageUrl,
    this.colorImages = const {},
    String? description,
  }) : assert(colors.isNotEmpty),
       _description = description;

  final String id;
  final String name;
  final List<HairColor> colors;
  final HairLength length;
  final Set<HairType> types;
  final Set<HairOccasion> occasions;
  final int likes; // lượt yêu thích, dùng cho "Phổ biến nhất"
  final bool isNew; // dùng cho "Mới nhất"
  final String? imageUrl; // ảnh mặc định của mẫu
  final Map<HairColor, String> colorImages; // ảnh riêng theo từng màu (nếu có)
  final String? _description;

  /// Màu mặc định (hiện ở danh sách). Giữ tên cũ để các màn khác không phải sửa.
  HairColor get color => colors.first;

  /// Ảnh của mẫu ở màu [c]: ưu tiên ảnh riêng của màu, không có thì dùng ảnh mặc định.
  String? imageFor(HairColor c) => colorImages[c] ?? imageUrl;

  /// Ảnh hiện trên thẻ ở danh sách.
  String? get thumbUrl => imageFor(color);

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

  /// Mô tả từ server; trống thì dùng mô tả có sẵn theo kiểu tóc.
  String get description {
    final custom = _description?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (mainType) {
      HairType.layer => 'Kiểu tóc layer nhiều tầng tạo độ bồng bềnh tự nhiên, giúp tổng thể mềm mại và hiện đại. Phù hợp với những ai yêu thích phong cách thanh lịch nhưng vẫn trẻ trung.',
      HairType.bob => 'Tóc bob ôm gọn khuôn mặt, giúp gương mặt thon gọn và trẻ trung hơn. Dễ chăm sóc, hợp đi học và đi làm.',
      HairType.pixie => 'Tóc tém ngắn cá tính, tôn đường nét gương mặt và chiếc cổ thon. Gọn gàng, mát mẻ, rất ít tốn thời gian tạo kiểu.',
      HairType.wolfCut => 'Wolf cut cắt tầng phá cách với phần đỉnh bồng và đuôi tỉa mỏng, mang lại vẻ năng động, cá tính.',
      HairType.hushCut => 'Hush cut tỉa tầng nhẹ quanh mặt, tạo cảm giác bồng bềnh mềm mại mà vẫn tự nhiên, dễ để kiểu hằng ngày.',
      HairType.curly => 'Tóc uốn sóng mềm giúp mái tóc trông dày và bồng bềnh hơn, mang lại vẻ nữ tính, quyến rũ.',
      HairType.straight => 'Tóc thẳng suôn mượt, đơn giản mà thanh lịch, giữ nếp lâu và phù hợp nhiều hoàn cảnh.',
    };
  }

  List<String> get tags => switch (mainType) {
    HairType.layer ||
    HairType.hushCut => ['Thanh lịch', 'Tự nhiên', 'Dễ tạo kiểu'],
    HairType.bob ||
    HairType.straight => ['Gọn gàng', 'Trẻ trung', 'Dễ chăm sóc'],
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

  /// Đọc một mẫu tóc từ JSON của API (document trong collection hair_styles).
  /// [baseUrl] dùng để nối vào link ảnh dạng "/images/abc.jpg" (link https:// giữ nguyên).
  factory HairStyle.fromJson(Map<String, dynamic> j, {String baseUrl = ''}) {
    String? url(Object? raw) {
      final s = raw?.toString().trim() ?? '';
      if (s.isEmpty) return null;
      return s.startsWith('/') ? '$baseUrl$s' : s;
    }

    final colors = <HairColor>[];
    final colorImages = <HairColor, String>{};
    final rawColors = j['colors'];
    if (rawColors is List) {
      for (final c in rawColors) {
        if (c is! Map) continue;
        final hc = HairColor.fromLabel(c['name']);
        if (hc == null || colors.contains(hc)) continue;
        colors.add(hc);
        final u = url(c['imageUrl']);
        if (u != null) colorImages[hc] = u;
      }
    }
    if (colors.isEmpty)
      colors.add(HairColor.fromLabel(j['colorName']) ?? HairColor.brown);

    final types = <HairType>{
      for (final t in _asStrings(j['styleType'] ?? j['types']))
        if (HairType.fromLabel(t) != null) HairType.fromLabel(t)!,
    };
    if (types.isEmpty) types.add(HairType.layer);

    final occasions = <HairOccasion>{
      for (final o in _asStrings(j['occasions']))
        if (HairOccasion.fromLabel(o) != null) HairOccasion.fromLabel(o)!,
    };
    if (occasions.isEmpty) occasions.add(HairOccasion.daily);

    final likesRaw = j['likes'] ?? j['popularity'];

    return HairStyle(
      id: j['id'].toString(),
      name: (j['name'] ?? '').toString(),
      colors: colors,
      length: HairLength.fromLabel(j['length']) ?? HairLength.medium,
      types: types,
      occasions: occasions,
      likes: likesRaw is num ? likesRaw.toInt() : 0,
      isNew: j['isNew'] == true,
      imageUrl: url(j['imageUrl']),
      colorImages: colorImages,
      description: j['description']?.toString(),
    );
  }
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
      (colors.isEmpty || colors.any(s.colors.contains)) &&
      (occasions.isEmpty || occasions.any(s.occasions.contains));

  /// Sắp xếp theo độ phổ biến / mới nhất.
  List<HairStyle> sorted(List<HairStyle> items) => switch (sort) {
    HairSort.all => items,
    HairSort.popular => [...items]..sort((a, b) => b.likes.compareTo(a.likes)),
    HairSort.newest => _newestFirst(items),
  };

  GalleryFilter copyWith({
    Set<HairLength>? lengths,
    Set<HairType>? types,
    Set<HairColor>? colors,
    Set<HairOccasion>? occasions,
    HairSort? sort,
  }) => GalleryFilter(
    lengths: lengths ?? this.lengths,
    types: types ?? this.types,
    colors: colors ?? this.colors,
    occasions: occasions ?? this.occasions,
    sort: sort ?? this.sort,
  );
}

/// Mẫu đánh dấu isNew lên đầu; nếu không có mẫu nào isNew thì coi mẫu cuối danh sách là mới nhất.
List<HairStyle> _newestFirst(List<HairStyle> items) {
  final fresh = items.where((s) => s.isNew).toList();
  if (fresh.isEmpty) return items.reversed.toList();
  return [...fresh, ...items.where((s) => !s.isNew)];
}

/// Danh sách kiểu tóc đang dùng trong app.
/// Mặc định là dữ liệu dự phòng bên dưới; khi gọi loadHairStyles() thành công
/// (xem hair_style_api.dart) thì được thay bằng dữ liệu từ server.
List<HairStyle> hairStyles = _fallbackHairStyles();

HairStyle _s(
  String id,
  String name,
  List<HairColor> colors,
  HairLength length,
  Set<HairType> types,
  Set<HairOccasion> occasions,
  int likes,
) => HairStyle(
  id: id,
  name: name,
  colors: colors,
  length: length,
  types: types,
  occasions: occasions,
  likes: likes,
);

/// Dữ liệu dự phòng, dùng khi chưa kết nối được server.
List<HairStyle> _fallbackHairStyles() => [
  _s(
    'butterfly-layer',
    'Butterfly Layer',
    [HairColor.brown, HairColor.gold],
    HairLength.long,
    {HairType.layer},
    {HairOccasion.daily, HairOccasion.party},
    980,
  ),
  _s(
    'bob-han-quoc',
    'Bob Hàn Quốc',
    [HairColor.red, HairColor.black],
    HairLength.short,
    {HairType.bob, HairType.straight},
    {HairOccasion.work, HairOccasion.school},
    760,
  ),
  _s(
    'pixie-cut',
    'Pixie Cut',
    [HairColor.brown, HairColor.black],
    HairLength.short,
    {HairType.pixie},
    {HairOccasion.daily, HairOccasion.travel},
    540,
  ),
  _s(
    'long-layer',
    'Long Layer',
    [HairColor.black, HairColor.brown],
    HairLength.long,
    {HairType.layer, HairType.straight},
    {HairOccasion.work},
    820,
  ),
  _s(
    'hush-cut',
    'Hush Cut',
    [HairColor.gold, HairColor.brown],
    HairLength.medium,
    {HairType.hushCut},
    {HairOccasion.daily, HairOccasion.school},
    910,
  ),
  _s(
    'soft-wolf-cut',
    'Soft Wolf Cut',
    [HairColor.brown, HairColor.black],
    HairLength.medium,
    {HairType.wolfCut},
    {HairOccasion.travel},
    470,
  ),
  _s(
    'layer-dai',
    'Layer dài',
    [HairColor.brown],
    HairLength.long,
    {HairType.layer},
    {HairOccasion.daily},
    650,
  ),
  _s(
    'layer-uon-nhe',
    'Layer uốn nhẹ',
    [HairColor.brown, HairColor.gold],
    HairLength.long,
    {HairType.layer, HairType.curly},
    {HairOccasion.party},
    720,
  ),
  _s(
    'hush-cut-layer',
    'Hush Cut layer',
    [HairColor.brown],
    HairLength.long,
    {HairType.hushCut, HairType.layer},
    {HairOccasion.school},
    880,
  ),
  _s(
    'soft-layer',
    'Soft Layer',
    [HairColor.gold, HairColor.brown],
    HairLength.long,
    {HairType.layer},
    {HairOccasion.work, HairOccasion.daily},
    590,
  ),
  _s(
    'layer-mai-bay',
    'Layer mái bay',
    [HairColor.brown],
    HairLength.long,
    {HairType.layer},
    {HairOccasion.travel},
    430,
  ),
  _s(
    'bob-xoan',
    'Bob uốn cụp',
    [HairColor.brown, HairColor.black],
    HairLength.short,
    {HairType.bob, HairType.curly},
    {HairOccasion.work},
    380,
  ),
  _s(
    'wolf-cut-ngan',
    'Wolf Cut ngắn',
    [HairColor.black, HairColor.red],
    HairLength.short,
    {HairType.wolfCut},
    {HairOccasion.travel, HairOccasion.daily},
    610,
  ),
  _s(
    'tem-ca-tinh',
    'Tóc tém cá tính',
    [HairColor.red, HairColor.black],
    HairLength.short,
    {HairType.pixie},
    {HairOccasion.party},
    350,
  ),
  _s(
    'thang-ngang-vai',
    'Thẳng ngang vai',
    [HairColor.black],
    HairLength.medium,
    {HairType.straight},
    {HairOccasion.school, HairOccasion.work},
    500,
  ),
  _s(
    'uon-song-nuoc',
    'Uốn sóng nước',
    [HairColor.red, HairColor.brown],
    HairLength.long,
    {HairType.curly},
    {HairOccasion.party},
    690,
  ),
  _s(
    'layer-ngang-vai',
    'Layer ngang vai',
    [HairColor.brown, HairColor.gold],
    HairLength.medium,
    {HairType.layer},
    {HairOccasion.daily},
    410,
  ),
  _s(
    'hush-cut-caramel',
    'Hush Cut ngắn',
    [HairColor.gold],
    HairLength.short,
    {HairType.hushCut},
    {HairOccasion.travel},
    560,
  ),
  _s(
    'bob-pastel',
    'Bob pastel',
    [HairColor.red, HairColor.gold],
    HairLength.short,
    {HairType.bob},
    {HairOccasion.party, HairOccasion.travel},
    330,
  ),
  _s(
    'uon-de-dai',
    'Uốn đuôi dài',
    [HairColor.brown, HairColor.black],
    HairLength.long,
    {HairType.curly, HairType.layer},
    {HairOccasion.daily},
    620,
  ),
];
