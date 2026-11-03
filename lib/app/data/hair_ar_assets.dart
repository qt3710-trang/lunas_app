import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Một ảnh tóc dùng cho AR: 1 kiểu tóc + 1 màu, ảnh PNG nền trong suốt
/// (cột imageAR trong sheet "AR" của file Excel, host trên Cloudinary).
class ArHair {
  const ArHair({
    required this.styleId,
    required this.styleName,
    required this.color,
    required this.colorHex,
    required this.url,
  });

  final String styleId;
  final String styleName;
  final String color;
  final int colorHex;
  final String url;
}

/// Kiểu + màu đang được chọn để thử. Hai màn AR (camera, ảnh) cùng nghe cái này,
/// nên màn Mẫu muốn "Thử AR" chỉ cần gán selectedArHair.value = ... rồi mở /ar.
final ValueNotifier<ArHair?> selectedArHair = ValueNotifier<ArHair?>(
  arHairs.isEmpty ? null : arHairs.first,
);

const _lastHairKey = 'ar_last_hair'; // lưu dạng "styleId|màu"

/// Gọi 1 lần lúc mở app: lấy lại kiểu + màu thử gần nhất,
/// và từ đó mỗi lần đổi kiểu / màu thì tự lưu lại.
Future<void> restoreSelectedArHair() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_lastHairKey)?.split('|');
  if (saved != null) {
    final hair = findArHair(saved.first, saved.length > 1 ? saved[1] : null);
    if (hair != null) selectedArHair.value = hair;
  }
  selectedArHair.addListener(() {
    final h = selectedArHair.value;
    if (h != null) prefs.setString(_lastHairKey, '${h.styleId}|${h.color}');
  });
}

/// Tìm ảnh AR theo styleId (+ màu nếu có). Không có thì trả null.
ArHair? findArHair(String styleId, [String? color]) {
  final list = arHairs.where((h) => h.styleId == styleId);
  if (color != null) {
    for (final h in list) {
      if (h.color == color) return h;
    }
  }
  return list.isEmpty ? null : list.first;
}

/// Kiểu tóc nào đã có ảnh AR (để màn Mẫu ẩn/hiện nút "Thử AR").
bool hasArHair(String styleId) => arHairs.any((h) => h.styleId == styleId);

/// Vẽ ảnh tóc từ link. gaplessPlayback giữ ảnh cũ trong lúc tải ảnh mới nên đổi màu không bị nháy.
class ArHairImage extends StatelessWidget {
  const ArHairImage({super.key, required this.hair, required this.fallback});

  final ArHair hair;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => Image.network(
    hair.url,
    fit: BoxFit.contain,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => fallback,
  );
}

/// Dải chọn kiểu tóc + màu, đặt dưới màn AR.
class ArHairPicker extends StatelessWidget {
  const ArHairPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArHair?>(
      valueListenable: selectedArHair,
      builder: (context, current, _) {
        if (current == null) return const SizedBox.shrink();
        final colors = arHairs.where((h) => h.styleId == current.styleId);
        // Mỗi kiểu chỉ hiện 1 ô (màu đang chọn nếu là kiểu hiện tại, không thì màu đầu tiên).
        final seen = <String>{};
        final styles = [
          for (final h in arHairs)
            if (seen.add(h.styleId)) h.styleId == current.styleId ? current : h,
        ];
        return Container(
          color: Colors.black38,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final h in colors)
                      GestureDetector(
                        onTap: () => selectedArHair.value = h,
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Color(h.colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: h == current
                                  ? Colors.white
                                  : Colors.white54,
                              width: h == current ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: styles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final h = styles[i];
                    final on = h.styleId == current.styleId;
                    return Tooltip(
                      message: h.styleName,
                      child: GestureDetector(
                        onTap: () => selectedArHair.value = findArHair(
                          h.styleId,
                          current.color,
                        ),
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: on ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            h.url,
                            fit: BoxFit.cover,
                            cacheWidth: 160, // thumbnail nhỏ cho nhẹ máy
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Danh sách ảnh tóc AR, sinh từ sheet "AR" (chỉ gồm các dòng đã có imageAR).
/// Khi có thêm link, chạy lại script sinh file này hoặc bổ sung dòng vào đây.
const List<ArHair> arHairs = [
  ArHair(
    styleId: 'toc-dai-tia-layer',
    styleName: 'Tóc dài tỉa Layer',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607086/hair_01.png',
  ),
  ArHair(
    styleId: 'toc-dai-tia-layer',
    styleName: 'Tóc dài tỉa Layer',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607112/hair_02.png',
  ),
  ArHair(
    styleId: 'toc-dai-tia-layer',
    styleName: 'Tóc dài tỉa Layer',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607135/hair_03.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-tia-layer',
    styleName: 'Tóc dài tỉa Layer',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607155/hair_04.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-song-loi',
    styleName: 'Tóc dài uốn sóng lơi',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607317/hi.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-song-loi',
    styleName: 'Tóc dài uốn sóng lơi',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607338/hii.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-uon-song-loi',
    styleName: 'Tóc dài uốn sóng lơi',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url:
        'https://res.cloudinary.com/khzgspek/image/upload/v1793607354/hiii.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-song-loi',
    styleName: 'Tóc dài uốn sóng lơi',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607372/hu.png',
  ),
  ArHair(
    styleId: 'toc-dai-thang-tu-nhien',
    styleName: 'Tóc dài thẳng tự nhiên',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607396/huu.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-thang-tu-nhien',
    styleName: 'Tóc dài thẳng tự nhiên',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607422/ha.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-thang-tu-nhien',
    styleName: 'Tóc dài thẳng tự nhiên',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607422/ha.png',
  ),
  ArHair(
    styleId: 'toc-dai-thang-tu-nhien',
    styleName: 'Tóc dài thẳng tự nhiên',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607531/haa.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-xoan-song-nuoc',
    styleName: 'Tóc dài uốn xoăn sóng nước',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607551/a.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-xoan-song-nuoc',
    styleName: 'Tóc dài uốn xoăn sóng nước',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607570/b.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-xoan-song-nuoc',
    styleName: 'Tóc dài uốn xoăn sóng nước',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607637/c.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-xoan-song-nuoc',
    styleName: 'Tóc dài uốn xoăn sóng nước',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607667/d.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-uon-xu-dua-hippie',
    styleName: 'Tóc dài uốn xù đũa (Hippie)',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607689/%C4%91.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-uon-xu-dua-hippie',
    styleName: 'Tóc dài uốn xù đũa (Hippie)',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607689/%C4%91.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-xu-dua-hippie',
    styleName: 'Tóc dài uốn xù đũa (Hippie)',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607722/e.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-uon-xu-dua-hippie',
    styleName: 'Tóc dài uốn xù đũa (Hippie)',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607727/f.png',
  ),
  ArHair(
    styleId: 'toc-dai-cup-duoi-chu-c',
    styleName: 'Tóc dài cúp đuôi chữ C',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607756/g.png',
  ),
  ArHair(
    styleId: 'toc-dai-cup-duoi-chu-c',
    styleName: 'Tóc dài cúp đuôi chữ C',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607759/h.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-cup-duoi-chu-c',
    styleName: 'Tóc dài cúp đuôi chữ C',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url:
        'https://res.cloudinary.com/khzgspek/image/upload/v1793607354/hiii.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-cup-duoi-chu-c',
    styleName: 'Tóc dài cúp đuôi chữ C',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607727/f.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-chu-j',
    styleName: 'Tóc dài uốn chữ J',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607993/i.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-chu-j',
    styleName: 'Tóc dài uốn chữ J',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607999/k.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-chu-j',
    styleName: 'Tóc dài uốn chữ J',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607996/j.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-uon-chu-j',
    styleName: 'Tóc dài uốn chữ J',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793607155/hair_04.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-lon-to-lang-man',
    styleName: 'Tóc dài uốn lọn to lãng mạn',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608003/l.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-lon-to-lang-man',
    styleName: 'Tóc dài uốn lọn to lãng mạn',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608006/m.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-lon-to-lang-man',
    styleName: 'Tóc dài uốn lọn to lãng mạn',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608009/n.png',
  ),
  ArHair(
    styleId: 'toc-dai-uon-lon-to-lang-man',
    styleName: 'Tóc dài uốn lọn to lãng mạn',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608012/o.png',
  ),
  ArHair(
    styleId: 'toc-dai-tia-wolf-cut',
    styleName: 'Tóc dài tỉa Wolf Cut',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608271/u.png',
  ),
  ArHair(
    styleId: 'toc-dai-tia-wolf-cut',
    styleName: 'Tóc dài tỉa Wolf Cut',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608409/11.png',
  ),
  ArHair(
    styleId: 'toc-dai-tia-wolf-cut',
    styleName: 'Tóc dài tỉa Wolf Cut',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608298/3.png',
  ),
  ArHair(
    styleId: 'toc-dai-tia-wolf-cut',
    styleName: 'Tóc dài tỉa Wolf Cut',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608301/4.png',
  ),
  ArHair(
    styleId: 'toc-dai-duoi-thang-mai-bang',
    styleName: 'Tóc dài duỗi thẳng mái bằng',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608305/5.png',
  ),
  ArHair(
    styleId: 'toc-dai-duoi-thang-mai-bang',
    styleName: 'Tóc dài duỗi thẳng mái bằng',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608308/6.png',
  ),
  ArHair(
    styleId: 'toc-dai-duoi-thang-mai-bang',
    styleName: 'Tóc dài duỗi thẳng mái bằng',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608314/8.png',
  ),
  ArHair(
    styleId: 'toc-dai-duoi-thang-mai-bang',
    styleName: 'Tóc dài duỗi thẳng mái bằng',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608311/7.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-mai-bay-han-quoc',
    styleName: 'Tóc dài mái bay Hàn Quốc',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608321/10.png',
  ),
  // TODO: link bị trùng với dòng khác, kiểm tra lại
  ArHair(
    styleId: 'toc-dai-mai-bay-han-quoc',
    styleName: 'Tóc dài mái bay Hàn Quốc',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793608321/10.png',
  ),
  ArHair(
    styleId: 'toc-dai-mai-bay-han-quoc',
    styleName: 'Tóc dài mái bay Hàn Quốc',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609120/12.png',
  ),
  ArHair(
    styleId: 'toc-dai-mai-bay-han-quoc',
    styleName: 'Tóc dài mái bay Hàn Quốc',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609123/13.png',
  ),
  ArHair(
    styleId: 'toc-dai-hime-nhat-ban',
    styleName: 'Tóc dài Hime Nhật Bản',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609126/14.png',
  ),
  ArHair(
    styleId: 'toc-dai-hime-nhat-ban',
    styleName: 'Tóc dài Hime Nhật Bản',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609129/15.png',
  ),
  ArHair(
    styleId: 'toc-dai-hime-nhat-ban',
    styleName: 'Tóc dài Hime Nhật Bản',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609132/16.png',
  ),
  ArHair(
    styleId: 'toc-dai-hime-nhat-ban',
    styleName: 'Tóc dài Hime Nhật Bản',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609136/17.png',
  ),
  ArHair(
    styleId: 'toc-dai-hush-cut',
    styleName: 'Tóc dài Hush Cut',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609139/18.png',
  ),
  ArHair(
    styleId: 'toc-dai-hush-cut',
    styleName: 'Tóc dài Hush Cut',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609142/19.png',
  ),
  ArHair(
    styleId: 'toc-dai-hush-cut',
    styleName: 'Tóc dài Hush Cut',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609146/20.png',
  ),
  ArHair(
    styleId: 'toc-dai-hush-cut',
    styleName: 'Tóc dài Hush Cut',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609149/21.png',
  ),
  ArHair(
    styleId: 'toc-ngan-tia-layer',
    styleName: 'Tóc ngắn tỉa Layer',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609152/22.png',
  ),
  ArHair(
    styleId: 'toc-ngan-tia-layer',
    styleName: 'Tóc ngắn tỉa Layer',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609156/23.png',
  ),
  ArHair(
    styleId: 'toc-ngan-tia-layer',
    styleName: 'Tóc ngắn tỉa Layer',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609159/24.png',
  ),
  ArHair(
    styleId: 'toc-ngan-tia-layer',
    styleName: 'Tóc ngắn tỉa Layer',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609162/25.png',
  ),
  ArHair(
    styleId: 'toc-bob',
    styleName: 'Tóc Bob',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609165/26.png',
  ),
  ArHair(
    styleId: 'toc-bob',
    styleName: 'Tóc Bob',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609169/27.png',
  ),
  ArHair(
    styleId: 'toc-bob',
    styleName: 'Tóc Bob',
    color: 'Đỏ',
    colorHex: 0xFF8E1B3A,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609172/28.png',
  ),
  ArHair(
    styleId: 'toc-bob',
    styleName: 'Tóc Bob',
    color: 'Vàng',
    colorHex: 0xFFD4A24C,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609175/29.png',
  ),
  ArHair(
    styleId: 'bob-ngan',
    styleName: 'Bob ngắn',
    color: 'Đen',
    colorHex: 0xFF26262B,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609179/30.png',
  ),
  ArHair(
    styleId: 'bob-ngan',
    styleName: 'Bob ngắn',
    color: 'Nâu',
    colorHex: 0xFF7B4B34,
    url: 'https://res.cloudinary.com/khzgspek/image/upload/v1793609182/31.png',
  ),
];
