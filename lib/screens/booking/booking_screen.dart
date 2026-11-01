import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking_models.dart';
import '../../repositories/booking_repository.dart';

/// Đặt lịch làm tóc. Catalog và giờ hoạt động được đọc từ Firestore;
/// nút xác nhận ghi lịch hẹn vào collection 'bookings'.
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

  final _repository = BookingRepository();
  BookingCatalog? _catalog;
  Object? _loadError;
  bool _isLoading = true;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _selectedTime;
  Set<String> _selectedExtras = {};
  bool _isConfirmed = false;
  bool _isSaving = false;
  String _bookingCode = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  int get _totalDuration {
    final catalog = _catalog;
    if (catalog == null) return 0;
    return catalog.mainService.durationMinutes +
        _selectedServices.fold<int>(
          0,
          (total, service) => total + service.durationMinutes,
        );
  }

  int get _totalPrice {
    final catalog = _catalog;
    if (catalog == null) return 0;
    return catalog.mainService.price +
        _selectedServices.fold<int>(
          0,
          (total, service) => total + service.price,
        );
  }

  List<BookingAdditionalService> get _selectedServices {
    final catalog = _catalog;
    if (catalog == null) return const [];
    return catalog.additionalServices
        .where((service) => _selectedExtras.contains(service.id))
        .toList(growable: false);
  }

  List<String> _startTimesFor(BookingCatalog catalog, Set<String> selectedIds) {
    final duration =
        catalog.mainService.durationMinutes +
        catalog.additionalServices
            .where((service) => selectedIds.contains(service.id))
            .fold<int>(0, (total, service) => total + service.durationMinutes);
    return catalog.salonSettings.startTimesForDuration(duration);
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final catalog = await _repository.loadCatalog();
      final initialExtras = <String>{
        if (catalog.additionalServices.any(
          (service) => service.id == 'goi-say-tao-kieu',
        ))
          'goi-say-tao-kieu',
      };
      final times = _startTimesFor(catalog, initialExtras);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _selectedExtras = initialExtras;
        _selectedTime = times.contains('13:00') ? '13:00' : times.firstOrNull;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _toggleExtra(String id) {
    final nextExtras = Set<String>.of(_selectedExtras);
    if (!nextExtras.add(id)) nextExtras.remove(id);
    final catalog = _catalog;
    final times = catalog == null
        ? const <String>[]
        : _startTimesFor(catalog, nextExtras);
    setState(() {
      _selectedExtras = nextExtras;
      if (!times.contains(_selectedTime)) _selectedTime = times.firstOrNull;
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

  Future<void> _confirmBooking() async {
    if (_isSaving) return; // đang lưu thì bỏ qua lần bấm thứ hai
    final catalog = _catalog;
    if (catalog == null) return;
    final settings = catalog.salonSettings;
    if (!settings.isBookingEnabled) {
      _showLocalMessage(context, 'Salon hiện đang tạm ngưng nhận đặt lịch.');
      return;
    }
    final time = _selectedTime;
    if (time == null) {
      _showLocalMessage(context, 'Không có giờ phù hợp trước giờ đóng cửa.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final code = await _repository.createBooking(
        mainService: catalog.mainService,
        additionalServices: _selectedServices,
        salonSettings: settings,
        date: _selectedDate,
        time: time,
      );
      if (!mounted) return;
      setState(() {
        _bookingCode = code;
        _isConfirmed = true;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final message = error is BookingDataException
          ? error.message
          : 'Không thể lưu lịch hẹn. Hãy thử lại sau.';
      _showLocalMessage(context, message);
    }
  }

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
            child: _isLoading
                ? const _BookingLoadingState(key: ValueKey('booking-loading'))
                : _loadError != null
                ? _BookingErrorState(
                    key: const ValueKey('booking-error'),
                    message: _loadErrorMessage(_loadError!),
                    onRetry: _loadCatalog,
                  )
                : _isConfirmed
                ? _SuccessContent(
                    key: const ValueKey('booking-success'),
                    bookingCode: _bookingCode,
                    mainService: _catalog!.mainService,
                    selectedServices: _selectedServices,
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime!,
                    totalDuration: _totalDuration,
                    totalPrice: _totalPrice,
                    salonSettings: _catalog!.salonSettings,
                  )
                : _BookingForm(
                    key: const ValueKey('booking-form'),
                    mainService: _catalog!.mainService,
                    additionalServices: _catalog!.additionalServices,
                    salonSettings: _catalog!.salonSettings,
                    availableTimes: _startTimesFor(_catalog!, _selectedExtras),
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    selectedExtras: _selectedExtras,
                    totalDuration: _totalDuration,
                    totalPrice: _totalPrice,
                    isSaving: _isSaving,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                        final times = _startTimesFor(
                          _catalog!,
                          _selectedExtras,
                        );
                        if (!times.contains(_selectedTime)) {
                          _selectedTime = times.firstOrNull;
                        }
                      });
                    },
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

String _loadErrorMessage(Object error) {
  if (error is BookingDataException) return error.message;
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Firestore từ chối quyền đọc dữ liệu đặt lịch. Hãy kiểm tra security rules.';
  }
  return 'Không thể tải dữ liệu đặt lịch từ Firestore. Hãy kiểm tra kết nối rồi thử lại.';
}

class _BookingLoadingState extends StatelessWidget {
  const _BookingLoadingState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _BookingScreenState._teal),
        SizedBox(height: 14),
        Text(
          'Đang tải thông tin dịch vụ…',
          style: TextStyle(color: _BookingScreenState._muted),
        ),
      ],
    ),
  );
}

class _BookingErrorState extends StatelessWidget {
  const _BookingErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 46,
            color: _BookingScreenState._muted,
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa tải được dữ liệu đặt lịch',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookingScreenState._ink,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _BookingScreenState._muted,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _BookingScreenState._teal,
              side: const BorderSide(color: _BookingScreenState._teal),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BookingNotice extends StatelessWidget {
  const _BookingNotice({
    required this.icon,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 9 : 12,
      vertical: compact ? 8 : 10,
    ),
    decoration: BoxDecoration(
      color: _BookingScreenState._tealLight.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _BookingScreenState._teal),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: _BookingScreenState._muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BookingForm extends StatelessWidget {
  const _BookingForm({
    super.key,
    required this.mainService,
    required this.additionalServices,
    required this.salonSettings,
    required this.availableTimes,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedExtras,
    required this.totalDuration,
    required this.totalPrice,
    required this.isSaving,
    required this.onDateChanged,
    required this.onChooseDate,
    required this.onTimeChanged,
    required this.onExtraChanged,
    required this.onConfirm,
  });

  static const _muted = _BookingScreenState._muted;
  static const _teal = _BookingScreenState._teal;

  final BookingService mainService;
  final List<BookingAdditionalService> additionalServices;
  final SalonSettings salonSettings;
  final List<String> availableTimes;
  final DateTime selectedDate;
  final String? selectedTime;
  final Set<String> selectedExtras;
  final int totalDuration;
  final int totalPrice;
  final bool isSaving;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onChooseDate;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<String> onExtraChanged;
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
          if (!salonSettings.isBookingEnabled) ...[
            const SizedBox(height: 14),
            const _BookingNotice(
              icon: Icons.pause_circle_outline,
              message: 'Salon hiện đang tạm ngưng nhận đặt lịch.',
            ),
          ],
          const SizedBox(height: 18),
          _MainServiceCard(service: mainService),
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
          _SectionHeading(
            icon: Icons.access_time_rounded,
            title: 'Chọn khung giờ',
            action: Text(
              '${salonSettings.openTime}–${salonSettings.closeTime}',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 10),
          const _BookingNotice(
            icon: Icons.info_outline,
            message: 'Giờ được tính theo thời lượng dịch vụ và giờ hoạt động; chưa kiểm tra lịch đã đặt.',
            compact: true,
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 9.0;
              final width = (constraints.maxWidth - spacing * 3) / 4;
              if (availableTimes.isEmpty) {
                return const _BookingNotice(
                  icon: Icons.event_busy_outlined,
                  message: 'Không có giờ bắt đầu nào đủ thời lượng trước giờ đóng cửa.',
                  compact: true,
                );
              }
              return Wrap(
                spacing: spacing,
                runSpacing: 9,
                children: [
                  for (final time in availableTimes)
                    _TimeTile(
                      time: time,
                      width: width,
                      selected: selectedTime == time,
                      enabled: true,
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
          for (final service in additionalServices) ...[
            _ExtraServiceTile(
              service: service,
              selected: selectedExtras.contains(service.id),
              onTap: () => onExtraChanged(service.id),
            ),
            const SizedBox(height: 8),
          ],
          const _UnavailableServiceTile(),
          const SizedBox(height: 18),
          _BookingSummary(
            mainService: mainService,
            selectedServices: additionalServices
                .where((service) => selectedExtras.contains(service.id))
                .toList(growable: false),
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            totalDuration: totalDuration,
            totalPrice: totalPrice,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  salonSettings.isBookingEnabled &&
                      availableTimes.isNotEmpty &&
                      selectedTime != null &&
                      !isSaving
                  ? onConfirm
                  : null,
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
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Xác nhận đặt lịch'),
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
  const _MainServiceCard({required this.service});

  final BookingService service;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
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
                  service.description,
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
                      '${service.durationMinutes} phút',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.paid_outlined,
                      size: 15,
                      color: _BookingScreenState._muted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${_formatMoney(service.price)}đ',
                      style: const TextStyle(fontSize: 12),
                    ),
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

class _ExtraServiceTile extends StatelessWidget {
  const _ExtraServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final BookingAdditionalService service;
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
                service.id == 'goi-say-tao-kieu'
                    ? Icons.face_retouching_natural
                    : Icons.spa_outlined,
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
                  '+${_formatMoney(service.price)}đ',
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

class _UnavailableServiceTile extends StatelessWidget {
  const _UnavailableServiceTile();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: _BookingScreenState._rose.withValues(alpha: .65),
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
          child: const Icon(
            Icons.water_drop_outlined,
            color: Color(0xFFC48483),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhuộm tóc',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              SizedBox(height: 3),
              Text(
                'Chưa có dữ liệu giá và thời lượng trên Firestore.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _BookingScreenState._muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Chưa khả dụng',
          style: TextStyle(color: _BookingScreenState._muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.mainService,
    required this.selectedServices,
    required this.selectedDate,
    required this.selectedTime,
    required this.totalDuration,
    required this.totalPrice,
  });

  final BookingService mainService;
  final List<BookingAdditionalService> selectedServices;
  final DateTime selectedDate;
  final String? selectedTime;
  final int totalDuration;
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
                    Text(mainService.name, style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    const _SummaryLabel(icon: Icons.add, label: 'Dịch vụ thêm'),
                    const SizedBox(height: 4),
                    if (selectedServices.isEmpty)
                      const Text(
                        'Không có',
                        style: TextStyle(
                          color: _BookingScreenState._muted,
                          fontSize: 12,
                        ),
                      )
                    else
                      for (final service in selectedServices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            service.name,
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
                      selectedTime == null
                          ? 'Chưa có giờ phù hợp'
                          : '$selectedTime ($totalDuration phút)',
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
    required this.bookingCode,
    required this.mainService,
    required this.selectedServices,
    required this.selectedDate,
    required this.selectedTime,
    required this.totalDuration,
    required this.totalPrice,
    required this.salonSettings,
  });

  final String bookingCode;
  final BookingService mainService;
  final List<BookingAdditionalService> selectedServices;
  final DateTime selectedDate;
  final String selectedTime;
  final int totalDuration;
  final int totalPrice;
  final SalonSettings salonSettings;

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
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: _BookingScreenState._muted,
                  fontSize: 12,
                ),
                children: [
                  const TextSpan(text: 'Mã lịch hẹn: '),
                  TextSpan(
                    text: bookingCode,
                    style: const TextStyle(
                      color: _BookingScreenState._ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _SuccessServiceCard(
            mainService: mainService,
            selectedServices: selectedServices,
            totalPrice: totalPrice,
          ),
          const SizedBox(height: 12),
          _StudioCard(settings: salonSettings),
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
                  '$selectedTime ($totalDuration phút)',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.schedule_outlined,
            title: 'Múi giờ salon',
            child: Row(
              children: [
                const Expanded(
                  child: Text('Giờ hẹn hiển thị theo múi giờ đã cấu hình.'),
                ),
                const SizedBox(width: 8),
                Text(
                  salonSettings.timezone,
                  style: const TextStyle(
                    color: _BookingScreenState._teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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
                _PriceLine(label: mainService.name, price: mainService.price),
                for (final service in selectedServices)
                  _PriceLine(label: service.name, price: service.price),
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
    required this.mainService,
    required this.selectedServices,
    required this.totalPrice,
  });

  final BookingService mainService;
  final List<BookingAdditionalService> selectedServices;
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
              Text(
                mainService.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                mainService.description,
                style: TextStyle(
                  fontSize: 12,
                  color: _BookingScreenState._muted,
                  height: 1.35,
                ),
              ),
              if (selectedServices.isNotEmpty) ...[
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
                    '✦  ${selectedServices.map((service) => service.name).join(' · ')}',
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
  const _StudioCard({required this.settings});

  final SalonSettings settings;

  @override
  Widget build(BuildContext context) => _InfoCard(
    icon: Icons.storefront_outlined,
    title: settings.salonName,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giờ hoạt động',
          style: TextStyle(fontSize: 11, color: _BookingScreenState._muted),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 14,
              color: _BookingScreenState._teal,
            ),
            const SizedBox(width: 6),
            Text(
              '${settings.openTime} – ${settings.closeTime}',
              style: const TextStyle(fontSize: 11),
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