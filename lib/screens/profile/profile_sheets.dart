import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'profile_models.dart';

// Các lựa chọn cố định
const faceShapeOptions = ['Mặt trái xoan', 'Mặt tròn', 'Mặt vuông', 'Mặt dài', 'Mặt trái tim'];
const skinToneOptions = ['Da sáng', 'Da ngà', 'Da trung bình', 'Da ngăm', 'Da nâu'];
const styleTagOptions = [
  'Ngọt ngào', 'Cổ điển', 'Cá tính', 'Thanh lịch', 'Năng động', 'Hàn Quốc', 'Tự nhiên',
];

// =====================================================================
// 1. Hộp thoại SỬA TÊN (mở từ nút bánh răng)
// Trả về hồ sơ đã sửa, hoặc null nếu người dùng bấm Hủy.
// =====================================================================
Future<UserProfile?> showEditNameDialog(BuildContext context, UserProfile profile) {
  final controller = TextEditingController(text: profile.name);

  return showDialog<UserProfile>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sửa tên hiển thị'),
      content: TextField(
        controller: controller,
        autofocus: true,                       // mở hộp là bàn phím hiện luôn
        decoration: const InputDecoration(hintText: 'Tên của bạn'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),   // không trả gì = null
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();           // bỏ khoảng trắng thừa
            if (name.isEmpty) return;                      // tên trống thì không lưu
            Navigator.pop(dialogContext, profile.copyWith(name: name));
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}

// =====================================================================
// 2. Bảng chọn DÁNG MẶT + MÀU DA (trượt lên từ dưới)
// =====================================================================
Future<UserProfile?> showFaceSkinSheet(BuildContext context, UserProfile profile) {
  // Biến tạm: lựa chọn đang chọn trong bảng (chưa lưu)
  String face = profile.faceShape;
  String skin = profile.skinTone;

  return showModalBottomSheet<UserProfile>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    builder: (sheetContext) => StatefulBuilder(
      // setSheetState = setState riêng cho bảng này
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dáng mặt và tông da', style: AppTheme.titleFont(size: 22)),
              const SizedBox(height: 4),
              const Text(
                'Giúp AI gợi ý kiểu tóc và màu tóc hợp với bạn hơn.',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 20),

              const Text('Dáng mặt', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in faceShapeOptions)
                    ChoiceChip(
                      label: Text(option),
                      selected: option == face,
                      selectedColor: AppColors.tealLight,
                      onSelected: (_) => setSheetState(() => face = option),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Màu da', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in skinToneOptions)
                    ChoiceChip(
                      label: Text(option),
                      selected: option == skin,
                      selectedColor: AppColors.tealLight,
                      onSelected: (_) => setSheetState(() => skin = option),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.pop(
                  sheetContext,
                  profile.copyWith(faceShape: face, skinTone: skin),
                ),
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// =====================================================================
// 3. Bảng chọn PHONG CÁCH YÊU THÍCH (chọn được nhiều) + kiểu tóc yêu thích
// =====================================================================
Future<UserProfile?> showStyleSheet(BuildContext context, UserProfile profile) {
  final tags = {...profile.styleTags};   // Set = tập hợp, không bị trùng
  final hairController = TextEditingController(text: profile.favoriteHair);

  return showModalBottomSheet<UserProfile>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        // Đẩy bảng lên trên bàn phím khi gõ chữ
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Phong cách yêu thích', style: AppTheme.titleFont(size: 22)),
                const SizedBox(height: 20),

                const Text('Bạn thích phong cách nào? (chọn nhiều)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in styleTagOptions)
                      FilterChip(
                        label: Text(tag),
                        selected: tags.contains(tag),
                        selectedColor: AppColors.tealLight,
                        onSelected: (on) => setSheetState(() {
                          if (on) {
                            tags.add(tag);
                          } else {
                            tags.remove(tag);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Kiểu tóc yêu thích', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: hairController,
                  decoration: const InputDecoration(hintText: 'Ví dụ: Tóc layer bồng bềnh'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    profile.copyWith(
                      // giữ đúng thứ tự như danh sách gốc
                      styleTags: styleTagOptions.where(tags.contains).toList(),
                      favoriteHair: hairController.text.trim(),
                    ),
                  ),
                  child: const Text('Lưu'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}