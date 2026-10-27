import 'package:flutter/material.dart';

import '../../app/theme.dart';
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

  static const _undertones = ['Tông ấm', 'Tông lạnh', 'Tông trung tính', 'Chưa chắc chắn'];

  static const _vibes = {
    'Cá tính': 'Nổi bật, khác biệt',
    'Dễ thương': 'Ngọt ngào, trẻ trung',
    'Thanh lịch': 'Nhẹ nhàng, sang trọng',
  };

  // ---------- Lựa chọn của người dùng (null = chưa chọn) ----------
  String? _occasion;
  String? _skin;
  String? _undertone;
  String? _vibe;

  // ---------- Kết quả ----------
  bool _loading = false;
  List<AiSuggestion>? _results;          // null = chưa bấm tạo gợi ý
  final Set<String> _savedIds = {};      // các mẫu vừa bấm tim lưu

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI HAIR STYLIST',
          style: TextStyle(fontSize: 13, letterSpacing: 2, color: AppColors.pink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text('Tìm kiểu tóc dành riêng cho bạn', style: AppTheme.titleFont(size: 26)),
          const SizedBox(height: 4),
          const Text(
            'Chia sẻ một chút về phong cách của bạn, LUNAS sẽ gợi ý những kiểu tóc phù hợp nhất.',
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),

          // ---------- Bước 1: Dịp ----------
          _stepTitle('1. Bạn muốn làm tóc cho dịp nào?'),
          GridView.count(
            crossAxisCount: 5,                                // 5 ô mỗi hàng
            shrinkWrap: true,                                 // cao vừa đủ nội dung
            physics: const NeverScrollableScrollPhysics(),    // không tự cuộn riêng
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              for (final entry in _occasions.entries)
                _selectBox(
                  selected: _occasion == entry.key,
                  onTap: () => setState(() => _occasion = entry.key),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.value, size: 22, color: AppColors.pink),
                      const SizedBox(height: 4),
                      Text(entry.key,
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Bước 2: Màu da + tông da ----------
          _stepTitle('2. Tông da của bạn là gì?'),
          const Text('A. Chọn màu da gần nhất',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final entry in _skinColors.entries)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _skin = entry.key),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _skin == entry.key ? AppColors.teal : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: _skin == entry.key
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(entry.key,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('B. Tông da của bạn',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _undertones)
                ChoiceChip(
                  label: Text(option),
                  selected: _undertone == option,
                  selectedColor: AppColors.tealLight,
                  onSelected: (_) => setState(() => _undertone = option),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Bước 3: Vibe ----------
          _stepTitle('3. Bạn muốn mang vibe nào?'),
          Row(
            children: [
              for (final entry in _vibes.entries) ...[
                Expanded(
                  child: _selectBox(
                    selected: _vibe == entry.key,
                    onTap: () => setState(() => _vibe = entry.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                      child: Column(
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(entry.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (entry.key != _vibes.keys.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Nút tạo gợi ý ----------
          ElevatedButton(
            onPressed: (_ready && !_loading) ? _generate : null,   // null = nút bị mờ
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Tạo gợi ý kiểu tóc'),
                      SizedBox(width: 8),
                      Icon(Icons.auto_awesome, size: 18),
                    ],
                  ),
          ),
          if (!_ready)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Chọn đủ 3 bước để tạo gợi ý',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ),

          // ---------- Bước 4: Kết quả ----------
          if (_results != null) ...[
            const SizedBox(height: 28),
            _stepTitle('4. Gợi ý dành riêng cho bạn'),
            for (final r in _results!) ...[
              _resultCard(r),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  /// Tiêu đề từng bước
  Widget _stepTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }

  /// Ô chọn: viền hồng khi được chọn
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
          color: selected ? const Color(0xFFF6E3E8) : Colors.white,
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

  /// Thẻ một kết quả gợi ý
  Widget _resultCard(AiSuggestion r) {
    final saved = _savedIds.contains(r.style.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              r.style.image,
              width: 76,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 76,
                height: 90,
                color: const Color(0xFFF6E3E8),
                child: const Icon(Icons.face_retouching_natural, color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.style.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                Text(r.reason, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: saved ? null : () => _save(r.style),
            tooltip: 'Lưu mẫu',
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: AppColors.pink),
          ),
        ],
      ),
    );
  }
}