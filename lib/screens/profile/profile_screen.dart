import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'profile_models.dart';
import 'profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService.instance;  // viết tắt cho gọn

  UserProfile? _profile;
  List<SavedStyle> _saved = [];   // MỚI: danh sách mẫu đã lưu
  bool _loading = true;
  int _tab = 0;                   // 0 = Mẫu đã lưu, 1 = Lịch hẹn

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _service.getProfile();
    final saved = await _service.getSavedStyles();   // MỚI
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _saved = saved;
      _loading = false;
    });
  }

  /// Hiện một thông báo nhỏ ở cuối màn hình
  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= HÀNH ĐỘNG (MỚI) =================

  /// Bấm tim -> bỏ lưu mẫu
  Future<void> _unsave(SavedStyle style) async {
    setState(() {
      _saved.removeWhere((s) => s.id == style.id); // xóa trên màn hình ngay
    });
    await _service.removeSavedStyle(style.id);    // rồi báo service
    _toast('Đã bỏ lưu "${style.name}"');
  }

  /// Bật / tắt công tắc "Báo mẫu mới mỗi tuần"
  Future<void> _toggleWeekly(bool on) async {
    final updated = _profile!.copyWith(weeklyNotify: on);
    setState(() => _profile = updated);
    await _service.updateProfile(updated);
    _toast(on ? 'Sẽ báo mẫu mới vào sáng thứ hai' : 'Đã tắt báo mẫu mới');
  }

  /// Đăng xuất: hỏi lại cho chắc rồi về màn Đăng nhập
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để xem hồ sơ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (ok != true) return;          // bấm Hủy thì thôi
    await _service.logout();
    if (!mounted) return;
    context.go('/login');            // về màn Đăng nhập
  }

  // ================= GIAO DIỆN =================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile!;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(profile),
            const SizedBox(height: 16),
            _buildTabSwitcher(),
            const SizedBox(height: 20),
            if (_tab == 0) _buildSavedTab(profile) else _buildAppointmentsTab(),
          ],
        ),
      ),
    );
  }

  /// Thẻ đầu trang: ảnh đại diện + tên + kiểu tóc yêu thích
  Widget _buildHeader(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFD9A5B3),
            child: Text(
              profile.initial,
              style: AppTheme.titleFont(size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AppTheme.titleFont(size: 24)),
                const SizedBox(height: 4),
                Text(
                  '${profile.favoriteHair} · thích ${profile.styleTags.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},  // bài sau: mở hộp sửa tên
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  /// Thanh 2 nút chuyển tab
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6E3E8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Mẫu đã lưu'),
          _buildTabButton(1, 'Lịch hẹn'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.textDark : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  // ================= TAB "MẪU ĐÃ LƯU" (MỚI) =================

  Widget _buildSavedTab(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề mục
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.pink),
            const SizedBox(width: 8),
            Text('Mẫu tóc đã lưu', style: AppTheme.titleFont(size: 18)),
          ],
        ),
        const SizedBox(height: 12),

        // 3 ô mẫu tóc (hoặc thông báo nếu chưa lưu mẫu nào)
        if (_saved.isEmpty)
          const Text(
            'Bạn chưa lưu mẫu nào. Bấm hình trái tim ở trang Mẫu để lưu nhé.',
            style: TextStyle(color: AppColors.textGrey),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final style in _saved.take(3)) ...[
                Expanded(child: _buildStyleTile(style)),
                const SizedBox(width: 10),
              ],
            ],
          ),

        const SizedBox(height: 20),
        _buildMenu(profile),
      ],
    );
  }

  /// Một ô mẫu tóc: ảnh + tim + tên
  Widget _buildStyleTile(SavedStyle style) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack = xếp chồng: ảnh ở dưới, nút tim đè lên góc phải
          Stack(
            children: [
              _buildPhoto(style.image),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _unsave(style),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, size: 16, color: AppColors.pink),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              style.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // dài quá thì hiện "..."
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Ảnh kiểu tóc. Chưa có file ảnh -> hiện khung hồng có biểu tượng.
  Widget _buildPhoto(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        path,
        height: 130,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 130,
          color: const Color(0xFFF6E3E8),
          child: const Center(
            child: Icon(Icons.face_retouching_natural, color: AppColors.teal, size: 32),
          ),
        ),
      ),
    );
  }

  /// Khung menu: Dáng mặt, Phong cách, Báo mẫu mới, Đăng xuất
  Widget _buildMenu(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.face_outlined,
            title: 'Dáng mặt và tông da',
            subtitle: '${profile.faceShape} · ${profile.skinTone}',
            onTap: () => _toast('Bài sau sẽ làm phần sửa dáng mặt'),
          ),
          const Divider(height: 1),
          _buildMenuRow(
            icon: Icons.star_border,
            title: 'Phong cách yêu thích',
            subtitle: profile.styleTags.join(', '),
            onTap: () => _toast('Bài sau sẽ làm phần sửa phong cách'),
          ),
          const Divider(height: 1),
          _buildMenuRow(
            icon: Icons.notifications_none,
            title: 'Báo mẫu mới mỗi tuần',
            subtitle: 'Sáng thứ hai',
            trailing: Switch(
              value: profile.weeklyNotify,
              activeTrackColor: AppColors.pink,
              onChanged: _toggleWeekly,
            ),
            onTap: () => _toggleWeekly(!profile.weeklyNotify),
          ),
          const Divider(height: 1),
          _buildMenuRow(
            icon: Icons.logout,
            title: 'Đăng xuất',
            danger: true,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  /// Một dòng trong menu
  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    bool danger = false,
  }) {
    final color = danger ? AppColors.pink : AppColors.textDark;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF6E3E8),
        child: Icon(icon, color: AppColors.pink, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      trailing: trailing ?? Icon(Icons.arrow_forward, size: 18, color: color),
    );
  }

  // ================= TAB "LỊCH HẸN" =================

  /// Bài 6 sẽ làm thật
  Widget _buildAppointmentsTab() {
    return const Text('Đây là tab Lịch hẹn');
  }
}