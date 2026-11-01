import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/auth_service.dart';
import 'profile_models.dart';

// Các lựa chọn cố định
const faceShapeOptions = ['Mặt trái xoan', 'Mặt tròn', 'Mặt vuông', 'Mặt dài', 'Mặt trái tim'];
const skinToneOptions = ['Da sáng', 'Da ngà', 'Da trung bình', 'Da ngăm', 'Da nâu'];
const styleTagOptions = [
  'Ngọt ngào', 'Cổ điển', 'Cá tính', 'Thanh lịch', 'Năng động', 'Hàn Quốc', 'Tự nhiên',
];

// =====================================================================
// 1. Hộp thoại SỬA TÊN (mở từ bảng Cài đặt)
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

// =====================================================================
// 4. Bảng CÀI ĐẶT TÀI KHOẢN (mở từ nút bánh răng)
// Trả về lựa chọn người dùng bấm, hoặc null nếu đóng bảng.
// =====================================================================
enum SettingsChoice { editName, changePassword }

Future<SettingsChoice?> showSettingsSheet(BuildContext context, UserProfile profile) {
  return showModalBottomSheet<SettingsChoice>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.cream,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cài đặt tài khoản', style: AppTheme.titleFont(size: 22)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: AppColors.pink),
              title: const Text('Tên hiển thị'),
              subtitle: Text(profile.name),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => Navigator.pop(sheetContext, SettingsChoice.editName),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined, color: AppColors.pink),
              title: const Text('Số điện thoại'),
              subtitle: Text(profile.phone),
              // SĐT là tài khoản đăng nhập nên không cho đổi (không có onTap).
              trailing: const Text(
                'Không đổi được',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: AppColors.pink),
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.arrow_forward, size: 18),
              onTap: () => Navigator.pop(sheetContext, SettingsChoice.changePassword),
            ),
          ],
        ),
      ),
    ),
  );
}

// =====================================================================
// 5. Hộp ĐỔI MẬT KHẨU
// Tự gọi AuthService. Trả về true nếu đổi thành công.
// =====================================================================
Future<bool?> showChangePasswordDialog(BuildContext context) {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  String? error;          // câu báo lỗi hiện trong hộp (null = không có lỗi)
  bool loading = false;   // đang gửi lên Firebase

  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // không cho bấm ra ngoài để đóng khi đang đổi
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> submit() async {
          final current = currentController.text;
          final next = newController.text;

          // Kiểm tra trước khi gửi lên Firebase
          String? problem;
          if (current.isEmpty) {
            problem = 'Vui lòng nhập mật khẩu hiện tại';
          } else if (next.length < 6) {
            problem = 'Mật khẩu mới phải có ít nhất 6 ký tự';
          } else if (next != confirmController.text) {
            problem = 'Mật khẩu nhập lại không khớp';
          } else if (next == current) {
            problem = 'Mật khẩu mới phải khác mật khẩu hiện tại';
          }
          if (problem != null) {
            setDialogState(() => error = problem);
            return;
          }

          setDialogState(() {
            loading = true;
            error = null;
          });
          try {
            await AuthService.instance.changePassword(
              currentPassword: current,
              newPassword: next,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
          } on AuthException catch (e) {
            setDialogState(() {
              loading = false;
              error = e.message;
            });
          }
        }

        return AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới (ít nhất 6 ký tự)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: AppColors.pink, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ],
        );
      },
    ),
  );
}