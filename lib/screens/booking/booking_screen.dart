import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Đặt lịch làm tóc. Toàn bộ lựa chọn hiện được giữ trong bộ nhớ của màn hình;
/// có thể thay nguồn dữ liệu bằng API ở giai đoạn sau.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _ink = Color(0xFF49364B);
  static const _muted = Color(0xFF907C8F);
  static const _teal = Color(0xFF70AAB0);
  static const _tealLight = Color(0xFFE6F1F0);
  static const _rose = Color(0xFFE8C9C4);
  static const _pink = Color(0xFFE34E81);
  static const _paper = Color(0xFFFFFCFA);

  static const _mainPrice = 250000;
  static const _mainDuration = '45–60 phút';
  static const _times = [
    '09:00',
    '10:30',
    '13:00',
    '14:30',
    '16:00',
    '17:30',
    '19:00',
    '20:30',
  ];

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String _selectedTime = '13:00';
  final Set<int> _selectedExtras = {0};
  bool _isConfirmed = false;

  static const _extras = [
    _ExtraService(
      name: 'Gội và sấy tạo kiểu',
      description: 'Làm sạch tóc và sấy tạo kiểu sau khi thực hiện dịch vụ.',
      price: 50000,
      icon: Icons.face_retouching_natural,
    ),
    _ExtraService(
      name: 'Hấp phục hồi tóc',
      description: 'Hỗ trợ dưỡng ẩm và chăm sóc tóc sau xử lý hóa chất.',
      price: 150000,
      icon: Icons.spa_outlined,
    ),
    _ExtraService(
      name: 'Nhuộm tóc',
      description: 'Thay đổi màu tóc theo bảng màu và tư vấn của salon.',
      price: 500000,
      pricePrefix: 'Từ ',
      icon: Icons.water_drop_outlined,
    ),
  ];

  int get _totalPrice =>
      _mainPrice +
      _selectedExtras.fold(0, (total, index) => total + _extras[index].price);

  void _toggleExtra(int index) {
    setState(() {
      if (!_selectedExtras.add(index)) _selectedExtras.remove(index);
    });
  }

  Future<void> _chooseDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
            surface: _paper,
            onSurface: _ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _confirmBooking() => setState(() => _isConfirmed = true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8F5), _paper, Color(0xFFF7FAF9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _isConfirmed
                ? _SuccessContent(
                    key: const ValueKey('booking-success'),
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    totalPrice: _totalPrice,
                    selectedExtras: _selectedExtras,
                  )
                : _BookingForm(
                    key: const ValueKey('booking-form'),
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    selectedExtras: _selectedExtras,
                    totalPrice: _totalPrice,
                    onDateChanged: (date) =>
                        setState(() => _selectedDate = date),
                    onChooseDate: _chooseDate,
                    onTimeChanged: (time) =>
                        setState(() => _selectedTime = time),
                    onExtraChanged: _toggleExtra,
                    onConfirm: _confirmBooking,
                  ),
          ),
        ),
      ),
    );
  }
}

class _BookingForm extends StatelessWidget {
  const _BookingForm({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedExtras,
    required this.totalPrice,
    required this.onDateChanged,
    required this.onChooseDate,
    required this.onTimeChanged,
    required this.onExtraChanged,
    required this.onConfirm,
  });

  static const _muted = _BookingScreenState._muted;
  static const _teal = _BookingScreenState._teal;

  final DateTime selectedDate;
  final String selectedTime;
  final Set<int> selectedExtras;
  final int totalPrice;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onChooseDate;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<int> onExtraChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (index) => DateUtils.dateOnly(DateTime.now()).add(Duration(days: index)),
    );

    return SingleChildScrollView(
      key: const PageStorageKey('booking-form-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeading(
            title: 'Đặt lịch làm tóc',
            subtitle:
                'Chọn thời gian phù hợp để LUNAS chăm sóc mái tóc của bạn.',
          ),
          const SizedBox(height: 18),
          const _MainServiceCard(),
          const SizedBox(height: 24),
          _SectionHeading(
            icon: Icons.calendar_month_outlined,
            title: 'Chọn ngày hẹn',
            action: TextButton.icon(
              onPressed: onChooseDate,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Xem lịch khác'),
              style: TextButton.styleFrom(
                foregroundColor: _muted,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = dates[index];
                return _DateTile(
                  date: date,
                  selected: DateUtils.isSameDay(selectedDate, date),
                  onTap: () => onDateChanged(date),
                );
              },
            ),
          ),
          const SizedBox(height: 23),
          const _SectionHeading(
            icon: Icons.access_time_rounded,
            title: 'Chọn khung giờ',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 9.0;
              final width = (constraints.maxWidth - spacing * 3) / 4;
              return Wrap(
                spacing: spacing,
                runSpacing: 9,
                children: [
                  for (final time in _BookingScreenState._times)
                    _TimeTile(
                      time: time,
                      width: width,
                      selected: selectedTime == time,
                      enabled: time != '19:00',
                      onTap: () => onTimeChanged(time),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeading(
            icon: Icons.add_circle_outline,
            title: 'Dịch vụ thêm',
          ),
          const SizedBox(height: 10),
          for (
            var index = 0;
            index < _BookingScreenState._extras.length;
            index++
          ) ...[
            _ExtraServiceTile(
              service: _BookingScreenState._extras[index],
              selected: selectedExtras.contains(index),
              onTap: () => onExtraChanged(index),
            ),
            if (index != _BookingScreenState._extras.length - 1)
              const SizedBox(height: 8),
          ],
          const SizedBox(height: 18),
          _BookingSummary(
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            selectedExtras: selectedExtras,
            totalPrice: totalPrice,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: _teal.withValues(alpha: 0.28),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Xác nhận đặt lịch'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Chi phí cuối cùng có thể thay đổi tùy tình trạng tóc và dịch vụ thực tế.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted.withValues(alpha: .8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.go('/home'),
          tooltip: 'Quay lại',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(right: 8, top: 2),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back, color: _BookingScreenState._ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 25,
                  color: _BookingScreenState._ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _BookingScreenState._muted,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MainServiceCard extends StatelessWidget {
  const _MainServiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .83),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _BookingScreenState._rose),
        boxShadow: [
          BoxShadow(
            color: _BookingScreenState._ink.withValues(alpha: .045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF3DCD5), Color(0xFFE9E7E1)],
              ),
            ),
            child: const Icon(
              Icons.face_3_outlined,
              size: 49,
              color: Color(0xFFAA827E),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cắt tóc Layer nữ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      size: 22,
                      color: _BookingScreenState._teal,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Tạo tầng tóc tự nhiên, giúp mái tóc bồng bềnh và mềm mại.',
                  style: TextStyle(
                    color: _BookingScreenState._muted,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 15,
                      color: _BookingScreenState._muted,
                    ),
                    SizedBox(width: 5),
                    Text(
                      _BookingScreenState._mainDuration,
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.paid_outlined,
                      size: 15,
                      color: _BookingScreenState._muted,
                    ),
                    SizedBox(width: 4),
                    Text('Từ 250.000đ', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _BookingScreenState._muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _BookingScreenState._ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdays[date.weekday - 1];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 61,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _BookingScreenState._pink
              : Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? _BookingScreenState._pink
                : _BookingScreenState._rose,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _BookingScreenState._pink.withValues(alpha: .2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white : _BookingScreenState._muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _BookingScreenState._ink,
              ),
            ),
            Text(
              'Tháng ${date.month}',
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? Colors.white.withValues(alpha: .9)
                    : _BookingScreenState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.time,
    required this.width,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String time;
  final double width;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = !enabled
        ? const Color(0xFFB6ADB5)
        : selected
        ? Colors.white
        : _BookingScreenState._ink;
    return SizedBox(
      width: width,
      height: 44,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: selected
              ? _BookingScreenState._teal
              : enabled
              ? Colors.white.withValues(alpha: .8)
              : const Color(0xFFF1EEEE),
          side: BorderSide(
            color: selected
                ? _BookingScreenState._teal
                : enabled
                ? _BookingScreenState._rose
                : const Color(0xFFE9E4E4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          textStyle: TextStyle(
            fontSize: 13,
            decoration: enabled ? null : TextDecoration.lineThrough,
          ),
        ),
        child: Text(time),
      ),
    );
  }
}

class _ExtraService {
  const _ExtraService({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    this.pricePrefix = '+',
  });

  final String name;
  final String description;
  final int price;
  final IconData icon;
  final String pricePrefix;

  String get formattedPrice => '$pricePrefix${_formatMoney(price)}đ';
}

class _ExtraServiceTile extends StatelessWidget {
  const _ExtraServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final _ExtraService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .76),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _BookingScreenState._rose.withValues(alpha: .8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(
                color: Color(0xFFFBEAE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                service.icon,
                color: const Color(0xFFC48483),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _BookingScreenState._muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.formattedPrice,
                  style: const TextStyle(
                    color: _BookingScreenState._teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: selected
                      ? _BookingScreenState._teal
                      : _BookingScreenState._muted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedExtras,
    required this.totalPrice,
  });

  final DateTime selectedDate;
  final String selectedTime;
  final Set<int> selectedExtras;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    final date = _formatVietnameseDate(selectedDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _BookingScreenState._rose.withValues(alpha: .72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 17,
                color: _BookingScreenState._muted,
              ),
              SizedBox(width: 7),
              Text(
                'Tóm tắt lịch hẹn',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SummaryLabel(
                      icon: Icons.content_cut,
                      label: 'Dịch vụ chính',
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cắt tóc Layer nữ',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const _SummaryLabel(icon: Icons.add, label: 'Dịch vụ thêm'),
                    const SizedBox(height: 4),
                    if (selectedExtras.isEmpty)
                      const Text(
                        'Không có',
                        style: TextStyle(
                          color: _BookingScreenState._muted,
                          fontSize: 12,
                        ),
                      )
                    else
                      for (final index in selectedExtras)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            _BookingScreenState._extras[index].name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SummaryLabel(
                      icon: Icons.event_outlined,
                      label: 'Ngày hẹn',
                    ),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    const _SummaryLabel(
                      icon: Icons.access_time,
                      label: 'Giờ hẹn',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$selectedTime (${_BookingScreenState._mainDuration})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: _BookingScreenState._rose),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng chi phí dự kiến',
                  style: TextStyle(
                    color: _BookingScreenState._teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_formatMoney(totalPrice)}đ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _BookingScreenState._ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: _BookingScreenState._muted),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: _BookingScreenState._muted, fontSize: 10),
      ),
    ],
  );
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.totalPrice,
    required this.selectedExtras,
  });

  final DateTime selectedDate;
  final String selectedTime;
  final int totalPrice;
  final Set<int> selectedExtras;

  @override
  Widget build(BuildContext context) {
    final date = _formatVietnameseDate(selectedDate);

    return SingleChildScrollView(
      key: const PageStorageKey('booking-success-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _BookingScreenState._teal,
              boxShadow: [
                BoxShadow(
                  color: _BookingScreenState._teal.withValues(alpha: .22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 45,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Đặt lịch thành công!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: _BookingScreenState._ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lịch hẹn của bạn đã được ghi nhận. LUNAS rất mong được đồng hành cùng bạn trên hành trình làm đẹp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookingScreenState._muted,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAE9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text.rich(
              TextSpan(
                style: TextStyle(
                  color: _BookingScreenState._muted,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(text: 'Mã lịch hẹn:  '),
                  TextSpan(
                    text: '#LUNAS1025',
                    style: TextStyle(
                      color: _BookingScreenState._teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _SuccessServiceCard(
            selectedExtras: selectedExtras,
            totalPrice: totalPrice,
          ),
          const SizedBox(height: 12),
          const _StudioCard(),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.calendar_month_outlined,
            title: 'Thời gian đặt lịch',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: _BookingScreenState._muted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$selectedTime (${_BookingScreenState._mainDuration})',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ',
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Số 123 Đường Hoa Mai, Quận 1, TP.HCM',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                _OutlineAction(
                  icon: Icons.navigation,
                  label: 'Chỉ đường',
                  onTap: () => _showLocalMessage(
                    context,
                    'Bản đồ sẽ được kết nối ở giai đoạn sau.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.event_note_outlined,
            title: 'Chi phí',
            child: Column(
              children: [
                _PriceLine(
                  label: 'Cắt tóc Layer nữ',
                  price: _BookingScreenState._mainPrice,
                ),
                for (final index in selectedExtras)
                  _PriceLine(
                    label: _BookingScreenState._extras[index].name,
                    price: _BookingScreenState._extras[index].price,
                  ),
                const Divider(height: 17),
                _PriceLine(
                  label: 'Tổng chi phí dự kiến',
                  price: totalPrice,
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OutlineAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Thêm vào lịch',
                  expanded: true,
                  onTap: () => _showLocalMessage(
                    context,
                    'Tính năng thêm vào lịch sẽ được bổ sung sau.',
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OutlineAction(
                  icon: Icons.navigation,
                  label: 'Chỉ đường',
                  expanded: true,
                  onTap: () => _showLocalMessage(
                    context,
                    'Bản đồ sẽ được kết nối ở giai đoạn sau.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BookingScreenState._teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Về trang chủ'),
            ),
          ),
          const SizedBox(height: 19),
          const Text(
            '—    Your hair, your story    —',
            style: TextStyle(
              color: _BookingScreenState._muted,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessServiceCard extends StatelessWidget {
  const _SuccessServiceCard({
    required this.selectedExtras,
    required this.totalPrice,
  });

  final Set<int> selectedExtras;
  final int totalPrice;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .8),
      border: Border.all(color: _BookingScreenState._rose),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Container(
          width: 94,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              colors: [Color(0xFFF2DDD6), Color(0xFFE9E6E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.face_3_outlined,
            size: 46,
            color: Color(0xFFAA827E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cắt tóc Layer nữ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tạo tầng tóc tự nhiên, giúp mái tóc bồng bềnh và mềm mại.',
                style: TextStyle(
                  fontSize: 12,
                  color: _BookingScreenState._muted,
                  height: 1.35,
                ),
              ),
              if (selectedExtras.isNotEmpty) ...[
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _BookingScreenState._tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✦  ${selectedExtras.map((index) => _BookingScreenState._extras[index].name).join(' · ')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: _BookingScreenState._teal,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Tổng chi phí dự kiến  ${_formatMoney(totalPrice)}đ',
                style: const TextStyle(
                  color: _BookingScreenState._ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StudioCard extends StatelessWidget {
  const _StudioCard();

  @override
  Widget build(BuildContext context) => _InfoCard(
    icon: Icons.storefront_outlined,
    title: 'LUNAS HAIR STUDIO',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salon tóc chuyên nghiệp, tạo nên phiên bản xinh đẹp nhất của bạn.',
          style: TextStyle(fontSize: 11, color: _BookingScreenState._muted),
        ),
        SizedBox(height: 7),
        Row(
          children: [
            Icon(
              Icons.phone_outlined,
              size: 14,
              color: _BookingScreenState._teal,
            ),
            SizedBox(width: 6),
            Text('0123 456 789', style: TextStyle(fontSize: 11)),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: _BookingScreenState._teal,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Số 123 Đường Hoa Mai, Quận 1, TP.HCM',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .78),
      border: Border.all(
        color: _BookingScreenState._rose.withValues(alpha: .85),
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: _BookingScreenState._muted),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              child,
            ],
          ),
        ),
      ],
    ),
  );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.price,
    this.emphasized = false,
  });

  final String label;
  final int price;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized
                  ? _BookingScreenState._teal
                  : _BookingScreenState._muted,
              fontSize: emphasized ? 12 : 11,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${_formatMoney(price)}đ',
          style: TextStyle(
            color: emphasized
                ? _BookingScreenState._teal
                : _BookingScreenState._ink,
            fontSize: emphasized ? 14 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: _BookingScreenState._teal,
        side: const BorderSide(color: _BookingScreenState._teal),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    return expanded
        ? SizedBox(width: double.infinity, child: content)
        : content;
  }
}

void _showLocalMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _formatVietnameseDate(DateTime date) {
  const weekdays = [
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
    'Chủ nhật',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);
