import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'home_care_treatments.dart';

class HomeCareDetailScreen extends StatelessWidget {
  const HomeCareDetailScreen({
    super.key,
    required this.treatment,
    required this.onBook,
  });

  final HomeCareTreatment treatment;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      title: Text(
        treatment.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _CareCover(treatment: treatment),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ảnh minh họa: cottonbro studio / Pexels',
                    style: TextStyle(fontSize: 10, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CHĂM SÓC TÓC TẠI LUNAS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(treatment.title, style: AppTheme.titleFont(size: 29)),
                  const SizedBox(height: 14),
                  Text(treatment.introduction, style: _bodyStyle),
                  const SizedBox(height: 28),
                  _heading('Liệu trình này dành cho ai?'),
                  for (final item in treatment.suitableFor) _bullet(item),
                  const SizedBox(height: 20),
                  _heading('Quy trình chăm sóc'),
                  const Text(
                    'Các bước dưới đây mang tính tham khảo và được điều chỉnh '
                    'sau khi chuyên viên xem trực tiếp tình trạng tóc.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (index, step) in treatment.steps.indexed)
                    _step(index + 1, step),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: treatment.accent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading('Lợi ích hướng tới'),
                        for (final item in treatment.benefits)
                          _bullet(item, icon: Icons.check_circle_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _heading('Chăm sóc sau liệu trình'),
                  for (final item in treatment.aftercare) _bullet(item),
                  const SizedBox(height: 8),
                  const Text(
                    'Cảm nhận sau chăm sóc tùy thuộc chất tóc và cách duy trì '
                    'tại nhà. Hãy trao đổi cùng chuyên viên để thống nhất mục tiêu phù hợp.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _heading('Chọn cách chăm sóc phù hợp với bạn'),
                  const Text(
                    'Trao đổi cùng LUNAS về tình trạng tóc và mong muốn của bạn '
                    'trước khi chọn liệu trình.',
                    style: _bodyStyle,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 20),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Tư vấn & đặt lịch',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  static const _bodyStyle = TextStyle(
    fontSize: 13,
    height: 1.65,
    color: AppColors.textDark,
  );

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: AppTheme.titleFont(size: 21)),
  );

  Widget _bullet(String text, {IconData icon = Icons.circle_outlined}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(icon, size: 16, color: AppColors.teal),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: _bodyStyle)),
          ],
        ),
      );

  Widget _step(int number, HomeCareStep step) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: treatment.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$number',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(step.description, style: _bodyStyle),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CareCover extends StatelessWidget {
  const _CareCover({required this.treatment});

  final HomeCareTreatment treatment;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(treatment.coverImageUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return _placeholder();
    }
    return Image.network(
      treatment.coverImageUrl,
      fit: BoxFit.cover,
      cacheWidth: 1400,
      semanticLabel: 'Ảnh minh họa ${treatment.title}',
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || frame != null ? child : _placeholder(loading: true),
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder({bool loading = false}) => Container(
    color: treatment.accent,
    alignment: Alignment.center,
    child: loading
        ? const CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2)
        : const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa_outlined, color: AppColors.teal, size: 38),
              SizedBox(height: 8),
              Text(
                'Ảnh minh họa liệu trình',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
  );
}
