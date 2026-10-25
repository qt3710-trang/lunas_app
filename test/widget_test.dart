import 'package:flutter_test/flutter_test.dart';

import 'package:lunas_app/main.dart';

void main() {
  testWidgets('App khởi động không lỗi', (WidgetTester tester) async {
    await tester.pumpWidget(const LunasApp());
    expect(find.byType(LunasApp), findsOneWidget);
  });
}
