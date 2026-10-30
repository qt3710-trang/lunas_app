import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';

// main() có chữ async vì kết nối Firebase cần thời gian,
// mình phải "chờ" (await) nó xong rồi mới mở giao diện.
Future<void> main() async {
  // Bắt buộc gọi dòng này trước khi dùng plugin (như Firebase)
  // ở trước runApp(). Nó chuẩn bị "cầu nối" giữa Flutter và Android.
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi động Firebase bằng cấu hình flutterfire đã tạo
  // (file lib/firebase_options.dart).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dòng in ra để kiểm tra đã kết nối đúng project của nhóm.
  // Sau này chạy ổn định có thể xoá.
  debugPrint(
    'Firebase đã kết nối với project: ${Firebase.app().options.projectId}',
  );

  runApp(const LunasApp());
}

class LunasApp extends StatelessWidget {
  const LunasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LUNAS Hair Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}