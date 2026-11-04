import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/data/hair_style.dart';
import '../../app/data/hair_style_api.dart'
    show hairStylesVersion, loadHairStyles;
import '../../app/theme.dart';
import '../../widgets/lunas_decor.dart';

/// Màn đầu tiên của tab "Thử với AR": cho người dùng chọn cách thử tóc.
/// - Camera trực tiếp -> /ar/live (ArTryOnScreen)
/// - Ảnh có sẵn / chụp mới -> /ar/photo (StaticTryScreen)
/// Ảnh minh họa lấy ngẫu nhiên từ các mẫu tóc trong app.
class ArMenuScreen extends StatefulWidget {
  const ArMenuScreen({super.key});

  @override
  State<ArMenuScreen> createState() => _ArMenuScreenState();
}

class _ArMenuScreenState extends State<ArMenuScreen> {
  /// 4 ảnh: [0] ảnh tròn trên cùng, [1] trong điện thoại, [2], [3] xấp ảnh.
  List<String?> _images = const [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _pickImages();
    hairStylesVersion.addListener(_pickImages);
    // Danh sách mẫu chưa tải thì tải, xong sẽ tự chọn lại ảnh qua hairStylesVersion.
    if (_images.every((e) => e == null)) loadHairStyles();
  }

  @override
  void dispose() {
    hairStylesVersion.removeListener(_pickImages);
    super.dispose();
  }

  void _pickImages() {
    final urls = <String>{
      for (final style in hairStyles)
        if (style.imageUrl case final url? when url.startsWith('http')) url,
    }.toList()..shuffle(Random());
    if (!mounted) return;
    setState(() {
      _images = [
        for (var i = 0; i < 4; i++) urls.isEmpty ? null : urls[i % urls.length],
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PastelColors.bg,
      child: Stack(
        children: [
          const Positioned.fill(child: PastelBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _header(),
                const SizedBox(height: 24),
                _OptionCard(
                  colors: const [Color(0xFFF9E1DE), Color(0xFFFCEDEA)],
                  accent: const Color(0xFFE2A19B),
                  art: _PhoneArt(image: _images[1]),
                  title: 'Thử qua Camera\ntrực tiếp',
                  subtitle: 'Mở camera trước,\nthử kiểu tóc ngay tại đây.',
                  onTap: () => context.go('/ar/live'),
                ),
                const SizedBox(height: 18),
                _OptionCard(
                  colors: const [Color(0xFFDDEDEA), Color(0xFFEEF6F3)],
                  accent: AppColors.teal,
                  art: _PhotoStackArt(back: _images[2], front: _images[3]),
                  title: 'Thử qua Ảnh',
                  subtitle: 'Chọn ảnh trong thư viện\nđể thử kiểu tóc.',
                  onTap: () => context.go('/ar/photo'),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'Tự tin hơn\nvới kiểu tóc mới ♡',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.greatVibes(
                      fontSize: 26,
                      height: 1.1,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'Thử kiểu tóc\n',
                children: [
                  TextSpan(
                    text: 'cùng AR!',
                    style: GoogleFonts.playfairDisplay(
                      fontStyle: FontStyle.italic,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
              style: AppTheme.titleFont(size: 30).copyWith(height: 1.15),
            ),
            const SizedBox(height: 10),
            const Text(
              'Khám phá diện mạo mới\nvới công nghệ thực tế ảo',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      // Ảnh chân dung tròn, có vòng màu bạc hà phía sau.
      SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PastelColors.mint.withValues(alpha: .6),
                ),
              ),
            ),
            Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A263B3B),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(child: _Photo(url: _images[0])),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Thẻ lựa chọn: hình minh họa bên trái, chữ + nút mũi tên tròn bên phải.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.colors,
    required this.accent,
    required this.art,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final List<Color> colors;
  final Color accent;
  final Widget art;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                SizedBox(width: 120, height: 150, child: art),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.titleFont(size: 19)),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .85),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hình điện thoại đang mở camera, kèm cây kéo nhỏ.
class _PhoneArt extends StatelessWidget {
  const _PhoneArt({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Container(
            width: 86,
            height: 150,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3E46),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Photo(url: image),
                  // Khung nhận diện khuôn mặt.
                  const Center(child: _FaceFrame()),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 22,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.content_cut,
              size: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// 4 góc vuông trắng mô phỏng khung lấy nét khuôn mặt.
class _FaceFrame extends StatelessWidget {
  const _FaceFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(48, 56), painter: _FaceFramePainter());
  }
}

class _FaceFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 10.0;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(x, y), Offset(x + l * dx, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + l * dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hai tấm ảnh chồng lệch nhau, kèm biểu tượng thư viện ảnh.
class _PhotoStackArt extends StatelessWidget {
  const _PhotoStackArt({required this.back, required this.front});

  final String? back;
  final String? front;

  @override
  Widget build(BuildContext context) {
    Widget photo(String? url, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 84,
        height: 104,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _Photo(url: url),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(left: 0, top: 8, child: photo(back, -0.14)),
        Positioned(left: 22, top: 26, child: photo(front, 0.06)),
        Positioned(
          right: 0,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.photo_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ảnh mạng; chưa có hoặc lỗi thì hiện nền pastel + icon.
class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFFF3E6E2),
      child: Center(
        child: Icon(Icons.face_3_outlined, color: AppColors.teal, size: 32),
      ),
    );
    final url = this.url;
    if (url == null) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (c, e, s) => placeholder,
    );
  }
}
