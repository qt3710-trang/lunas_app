import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/data/favorite_styles.dart';
import '../../app/theme.dart';
import '../../widgets/lunas_decor.dart';
import 'profile_models.dart';
import 'profile_service.dart';

/// AI HAIR STYLIST – "Tìm kiểu tóc dành riêng cho bạn"
class AiSuggestScreen extends StatefulWidget {
  const AiSuggestScreen({super.key, required this.profile});

  /// Hồ sơ hiện tại, dùng để điền sẵn màu da đã lưu.
  final UserProfile profile;

  @override
  State<AiSuggestScreen> createState() => _AiSuggestScreenState();
}

class _AiSuggestScreenState extends State<AiSuggestScreen> {
  // ---------- Các lựa chọn ----------
  static const _occasions = {
    'Đi học': Icons.school_outlined,
    'Đi làm': Icons.work_outline,
    'Hẹn hò': Icons.favorite_border,
    'Dự tiệc': Icons.celebration_outlined,
    'Sinh nhật': Icons.cake_outlined,
    'Đi chơi': Icons.local_cafe_outlined,
    'Du lịch': Icons.flight_outlined,
    'Cưới hỏi': Icons.diamond_outlined,
    'Tết': Icons.local_florist_outlined,
    'Dịp khác': Icons.more_horiz,
  };

  static const _skinColors = {
    'Da sáng': Color(0xFFF6DCCB),
    'Da ngà': Color(0xFFEFC9A8),
    'Da trung bình': Color(0xFFD9A47E),
    'Da ngăm': Color(0xFFB57A55),
    'Da nâu': Color(0xFF8A5638),
  };

  static const _undertones = [
    'Tông ấm',
    'Tông lạnh',
    'Tông trung tính',
    'Chưa chắc chắn',
  ];

  static const _vibes = {
    'Cá tính': 'Nổi bật, khác biệt',
    'Dễ thương': 'Ngọt ngào, trẻ trung',
    'Thanh lịch': 'Nhẹ nhàng, sang trọng',
  };

  /// Icon + màu nền riêng cho từng vibe.
  static const _vibeLooks = {
    'Cá tính': (Icons.bolt_rounded, Color(0xFFF6D3D6)),
    'Dễ thương': (Icons.favorite_rounded, Color(0xFFFBE2CF)),
    'Thanh lịch': (Icons.diamond_outlined, Color(0xFFD7EAE6)),
  };

  /// Màu pastel xoay vòng cho icon các dịp.
  static const _tints = [
    PastelColors.blush,
    PastelColors.mint,
    PastelColors.peach,
  ];

  // ---------- Lựa chọn của người dùng (null = chưa chọn) ----------
  String? _occasion;
  String? _skin;
  String? _undertone;
  String? _vibe;

  // ---------- Kết quả ----------
  bool _loading = false;
  List<AiSuggestion>? _results; // null = chưa bấm tạo gợi ý
  final Set<String> _savedIds = {}; // các mẫu vừa bấm tim lưu

  @override
  void initState() {
    super.initState();
    // Điền sẵn màu da nếu trong hồ sơ đã có
    if (_skinColors.containsKey(widget.profile.skinTone)) {
      _skin = widget.profile.skinTone;
    }
  }

  /// Đủ 4 lựa chọn mới cho bấm nút
  bool get _ready =>
      _occasion != null && _skin != null && _undertone != null && _vibe != null;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _results = null;
    });
    final results = await ProfileService.instance.getAiSuggestions(
      occasion: _occasion!,
      skinTone: _skin!,
      undertone: _undertone!,
      vibe: _vibe!,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _save(SavedStyle style) async {
    await ProfileService.instance.addSavedStyle(style);
    if (!mounted) return;
    setState(() => _savedIds.add(style.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu "${style.name}" vào Mẫu đã lưu')),
    );
  }

  // ================= GIAO DIỆN =================

  @override
  Widget build(BuildContext context) {
    final occasions = _occasions.entries.toList();
    return Stack(
      children: [
        const Positioned.fill(child: BubbleBackdrop()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.pink),
                SizedBox(width: 6),
                Text(
                  'AI HAIR STYLIST',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: AppColors.pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Tìm kiểu tóc\n',
                      children: [
                        TextSpan(
                          text: 'dành riêng cho bạn',
                          style: AppTheme.titleFont(
                            size: 28,
                            color: AppColors.teal,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    style: AppTheme.titleFont(size: 28).copyWith(height: 1.2),
                  ),
                  const Positioned(right: 24, top: 6, child: Sparkle(size: 18)),
                  const Positioned(right: 6, top: 34, child: Sparkle(size: 10)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Chia sẻ một chút về phong cách của bạn, LUNAS sẽ gợi ý những kiểu tóc phù hợp nhất.',
                style: TextStyle(color: AppColors.textGrey, height: 1.45),
              ),
              const SizedBox(height: 20),

              // ---------- Bước 1: Dịp ----------
              _stepCard(
                step: 1,
                color: PastelColors.blush,
                title: 'Bạn muốn làm tóc cho dịp nào?',
                child: GridView.count(
                  crossAxisCount: 5, // 5 ô mỗi hàng
                  shrinkWrap: true, // cao vừa đủ nội dung
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.78,
                  children: [
                    for (var i = 0; i < occasions.length; i++)
                      _selectBox(
                        selected: _occasion == occasions[i].key,
                        onTap: () =>
                            setState(() => _occasion = occasions[i].key),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: _tints[i % _tints.length]
                                  .withValues(alpha: .7),
                              child: Icon(
                                occasions[i].value,
                                size: 17,
                                color: i % _tints.length == 1
                                    ? AppColors.teal
                                    : AppColors.pink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              occasions[i].key,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Bước 2: Màu da + tông da ----------
              _stepCard(
                step: 2,
                color: PastelColors.peach,
                title: 'Tông da của bạn là gì?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A. Chọn màu da gần nhất',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final entry in _skinColors.entries)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _skin = entry.key),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: entry.value,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _skin == entry.key
                                            ? AppColors.teal
                                            : Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: entry.value.withValues(
                                            alpha: .5,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: _skin == entry.key
                                        ? const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    entry.key,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'B. Tông da của bạn',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _undertones)
                          _pill(
                            option,
                            selected: _undertone == option,
                            onTap: () => setState(() => _undertone = option),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Bước 3: Vibe ----------
              _stepCard(
                step: 3,
                color: PastelColors.mint,
                title: 'Bạn muốn mang vibe nào?',
                // IntrinsicHeight + stretch: 3 ô cao bằng nhau theo ô có chữ dài nhất,
                // không đặt chiều cao cố định để khỏi bị tràn chữ.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in _vibes.entries) ...[
                        Expanded(child: _vibeBox(entry.key, entry.value)),
                        if (entry.key != _vibes.keys.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---------- Nút tạo gợi ý ----------
              GradientButton(
                expand: true,
                onPressed: (_ready && !_loading) ? _generate : null,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tạo gợi ý kiểu tóc'),
                          SizedBox(width: 8),
                          Icon(Icons.auto_awesome),
                        ],
                      ),
              ),
              if (!_ready)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Chọn đủ 3 bước để tạo gợi ý',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),

              // ---------- Bước 4: Kết quả ----------
              if (_results != null) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    _stepBadge(4, PastelColors.blush),
                    const SizedBox(width: 10),
                    Text(
                      'Gợi ý dành riêng cho bạn',
                      style: AppTheme.titleFont(size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final r in _results!) ...[
                  _resultCard(r),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Vòng tròn số thứ tự bước, nền màu pastel.
  Widget _stepBadge(int step, Color color) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [color, Color.lerp(color, Colors.white, .5)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Text(
      '$step',
      style: AppTheme.titleFont(size: 15, color: AppColors.textDark),
    ),
  );

  /// Khung trắng của từng bước: số thứ tự + tiêu đề + nội dung.
  Widget _stepCard({
    required int step,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepBadge(step, color),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTheme.titleFont(size: 17))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Ô chọn: nền hồng nhạt + viền hồng khi được chọn
  Widget _selectBox({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBE7EA) : const Color(0xFFFFFCFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.pink : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }

  /// Chip bo tròn: đang chọn thì nền teal nhạt, chữ teal.
  Widget _pill(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.teal : AppColors.textDark,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Ô vibe: mỗi vibe một màu nền + icon riêng.
  Widget _vibeBox(String name, String description) {
    final (icon, color) = _vibeLooks[name]!;
    final selected = _vibe == name;
    return GestureDetector(
      onTap: () => setState(() => _vibe = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.white, .6)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color,
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: .8),
              child: Icon(
                selected ? Icons.check_rounded : icon,
                size: 18,
                color: selected ? AppColors.teal : AppColors.pink,
              ),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  /// Ảnh kết quả: link mạng hoặc ảnh trong app. Lỗi / trống -> khung hồng.
  Widget _resultPhoto(String path) {
    Widget placeholder() => Container(
      width: 76,
      height: 90,
      color: const Color(0xFFF6E3E8),
      child: const Icon(Icons.face_retouching_natural, color: AppColors.teal),
    );

    if (path.isEmpty) return placeholder();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 76,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    }
    return Image.asset(
      path,
      width: 76,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }

  /// Thẻ một kết quả gợi ý
  Widget _resultCard(AiSuggestion r) {
    // Đã lưu = vừa bấm tim ở đây HOẶC đã bấm tim từ trước (tab Mẫu).
    final saved =
        _savedIds.contains(r.style.id) || favoriteStyles.contains(r.style.id);
    return GestureDetector(
      onTap: () => context.push('/styles/${r.style.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFDF1EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14263B3B),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _resultPhoto(r.style.image),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.style.name, style: AppTheme.titleFont(size: 16)),
                  const SizedBox(height: 6),
                  Text(
                    r.reason,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: saved ? null : () => _save(r.style),
              tooltip: 'Lưu mẫu',
              icon: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                color: AppColors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
