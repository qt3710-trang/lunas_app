import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

// main() có chữ async vì kết nối Firebase cần thời gian,
// mình phải "chờ" (await) nó xong rồi mới mở giao diện.
Future<void> main() async {
  // Bắt buộc gọi trước khi dùng plugin (như Firebase) ở trước runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi động Firebase bằng cấu hình flutterfire đã tạo.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Mỗi lần mở app đều bắt đầu ở trạng thái CHƯA đăng nhập.
  //    (Firebase mặc định tự nhớ đăng nhập, nên mình chủ động đăng xuất.)
  //    Người dùng sẽ thấy Intro -> Đăng nhập / Đăng ký như bình thường.
  await AuthService.instance.logout();

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