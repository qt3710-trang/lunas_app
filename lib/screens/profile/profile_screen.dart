import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'profile_models.dart';
import 'profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;   // dấu ? = có thể chưa có (đang tải)
  bool _loading = true;

  // Chạy MỘT lần khi màn hình vừa mở
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService.instance.getProfile();
    if (!mounted) return;    // người dùng đã rời màn hình thì thôi
    setState(() {            // báo Flutter vẽ lại màn hình
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Đang tải -> hiện vòng xoay
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
            // Bài 4 sẽ thêm tiếp các phần bên dưới vào đây
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
          // Ảnh đại diện tròn
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFD9A5B3),
            child: Text(
              profile.initial,
              style: AppTheme.titleFont(size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          // Tên + dòng mô tả
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
}