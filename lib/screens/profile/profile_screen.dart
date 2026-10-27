import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'ai_suggest_screen.dart';   // BÀI 7B
import 'profile_models.dart';
import 'profile_service.dart';
import 'profile_sheets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService.instance;

  UserProfile? _profile;
  List<SavedStyle> _saved = [];
  List<Appointment> _appointments = [];
  bool _loading = true;
  int _tab = 0;                           // 0 = Mẫu đã lưu, 1 = Lịch hẹn

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _service.getProfile();
    final saved = await _service.getSavedStyles();
    final appointments = await _service.getAppointments();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _saved = saved;
      _appointments = appointments;
      _loading = false;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= HÀNH ĐỘNG =================

  /// Lưu hồ sơ sau khi sửa. [updated] = null nghĩa là người dùng đã hủy.
  Future<void> _saveProfile(UserProfile? updated, String message) async {
    if (updated == null) return;
    setState(() => _profile = updated);
    await _service.updateProfile(updated);
    _toast(message);
  }

  /// BÀI 7B: mở màn AI gợi ý. Quay về thì tải lại "Mẫu đã lưu".
  Future<void> _openAi() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AiSuggestScreen(profile: _profile!)),
    );
    final saved = await _service.getSavedStyles();
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  Future<void> _unsave(SavedStyle style) async {
    setState(() => _saved.removeWhere((s) => s.id == style.id));
    await _service.removeSavedStyle(style.id);
    _toast('Đã bỏ lưu "${style.name}"');
  }

  Future<void> _toggleWeekly(bool on) async {
    final updated = _profile!.copyWith(weeklyNotify: on);
    setState(() => _profile = updated);
    await _service.updateProfile(updated);
    _toast(on ? 'Sẽ báo mẫu mới vào sáng thứ hai' : 'Đã tắt báo mẫu mới');
  }

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
    if (ok != true) return;
    await _service.logout();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _cancelAppointment(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy lịch hẹn?'),
        content: Text('Bạn chắc chắn muốn hủy lịch ${a.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hủy lịch', style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.cancelAppointment(a.id);
    final list = await _service.getAppointments();
    if (!mounted) return;
    setState(() => _appointments = list);
    _toast('Đã hủy lịch hẹn ${a.code}');
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

  /// Thẻ trắng bo góc, dùng lại nhiều chỗ
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  /// Tiêu đề mục có biểu tượng phía trước
  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.pink),
        const SizedBox(width: 8),
        Text(text, style: AppTheme.titleFont(size: 18)),
      ],
    );
  }

  /// Ảnh kiểu tóc. Chưa có file ảnh -> hiện khung hồng có biểu tượng.
  Widget _buildPhoto(String path, {double? width, double height = 130}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        path,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width ?? double.infinity,
          height: height,
          color: const Color(0xFFF6E3E8),
          child: const Center(
            child: Icon(Icons.face_retouching_natural, color: AppColors.teal, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return _card(
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
            onPressed: () async => _saveProfile(
              await showEditNameDialog(context, profile),
              'Đã đổi tên',
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

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

  // ================= TAB "MẪU ĐÃ LƯU" =================

  Widget _buildSavedTab(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mẫu tóc đã lưu', Icons.auto_awesome),
        const SizedBox(height: 12),
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
        const SizedBox(height: 20),   // BÀI 7B
        _buildAiButton(),             // BÀI 7B
      ],
    );
  }

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
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// BÀI 7B: nút lớn màu xanh "AI GỢI Ý KIỂU TÓC"
  Widget _buildAiButton() {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: _openAi,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              Expanded(
                child: Text(
                  'AI GỢI Ý KIỂU TÓC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(UserProfile profile) {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.face_outlined,
            title: 'Dáng mặt và tông da',
            subtitle: '${profile.faceShape} · ${profile.skinTone}',
            onTap: () async => _saveProfile(
              await showFaceSkinSheet(context, profile),
              'Đã lưu dáng mặt và màu da',
            ),
          ),
          const Divider(height: 1),
          _buildMenuRow(
            icon: Icons.star_border,
            title: 'Phong cách yêu thích',
            subtitle: profile.styleTags.join(', '),
            onTap: () async => _saveProfile(
              await showStyleSheet(context, profile),
              'Đã lưu phong cách yêu thích',
            ),
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

  Widget _buildAppointmentsTab() {
    final upcoming = _appointments.where((a) => a.isUpcoming).toList();
    final history = _appointments.where((a) => !a.isUpcoming).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Lịch hẹn sắp tới', Icons.auto_awesome),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          _card(
            child: const Text('Chưa có lịch hẹn sắp tới.',
                style: TextStyle(color: AppColors.textGrey)),
          )
        else
          for (final a in upcoming) ...[
            _buildUpcomingCard(a),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 20),
        _sectionTitle('Lịch sử đặt lịch', Icons.history),
        const SizedBox(height: 12),
        if (history.isEmpty)
          _card(
            child: const Text('Chưa có lịch sử.', style: TextStyle(color: AppColors.textGrey)),
          )
        else
          _card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final a in history) _buildHistoryRow(a),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _buildBookBanner(),
      ],
    );
  }

  Widget _buildUpcomingCard(Appointment a) {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhoto(a.image, width: 90, height: 104),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusChip(a.status, upcoming: true),
                const SizedBox(height: 6),
                Text(a.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                _buildSmallLine(Icons.location_on_outlined, a.salonName),
                _buildSmallLine(Icons.calendar_today_outlined, formatAppointmentTime(a.startTime)),
                if (a.stylistName != null)
                  _buildSmallLine(Icons.person_outline, a.stylistName!),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => _showDetail(a),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pink,
                      side: const BorderSide(color: AppColors.pink),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(Appointment a) {
    return ListTile(
      onTap: () => _showDetail(a),
      leading: _buildPhoto(a.image, width: 52, height: 52),
      title: Row(
        children: [
          Expanded(
            child: Text(a.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _buildStatusChip(a.status, upcoming: false),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallLine(Icons.location_on_outlined, a.salonName),
          _buildSmallLine(Icons.calendar_today_outlined, formatAppointmentTime(a.startTime)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
    );
  }

  Widget _buildStatusChip(AppointmentStatus status, {required bool upcoming}) {
    Color bg;
    Color fg;
    if (status == AppointmentStatus.cancelled) {
      bg = const Color(0xFFEDEDED);
      fg = AppColors.textGrey;
    } else if (upcoming) {
      bg = const Color(0xFFF6E3E8);
      fg = AppColors.pink;
    } else {
      bg = AppColors.tealLight;
      fg = AppColors.teal;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSmallLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textGrey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookBanner() {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFF6E3E8),
            child: Icon(Icons.calendar_month_outlined, color: AppColors.pink, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Đặt lịch ngay để được tư vấn và chăm sóc tốt nhất!',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ),
          FilledButton(
            onPressed: () => context.go('/booking'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Đặt lịch ngay', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDetail(Appointment a) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.serviceName, style: AppTheme.titleFont(size: 22)),
              Text('Mã lịch hẹn: ${a.code}', style: const TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),
              _buildInfoLine(Icons.storefront_outlined, a.salonName),
              _buildInfoLine(Icons.location_on_outlined, a.salonAddress),
              _buildInfoLine(Icons.schedule, formatAppointmentTime(a.startTime)),
              if (a.stylistName != null) _buildInfoLine(Icons.person_outline, a.stylistName!),
              _buildInfoLine(Icons.payments_outlined, 'Tổng chi phí: ${formatVnd(a.totalPrice)}'),
              _buildInfoLine(Icons.info_outline, 'Trạng thái: ${a.status.label}'),
              if (a.isUpcoming) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _cancelAppointment(a);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pink,
                      side: const BorderSide(color: AppColors.pink),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Hủy lịch hẹn'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}