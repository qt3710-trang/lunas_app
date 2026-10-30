import 'package:go_router/go_router.dart';

import '../screens/ar_try/ar_try_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/intro/intro_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/styles/hair_style_detail_screen.dart';
import '../screens/styles/styles_screen.dart';

/// Toàn bộ đường đi giữa các màn hình của app.
///
/// /intro -> /login -> (5 tab có thanh menu dưới)
/// Thêm màn mới (ví dụ chi tiết mẫu tóc, đặt lịch thành công)
/// thì khai báo thêm GoRoute ở đây.
final appRouter = GoRouter(
  initialLocation: '/intro',
  routes: [
    // Địa chỉ gốc "/" -> tự chuyển về màn Giới thiệu (tránh trang "Page Not Found")
    GoRoute(path: '/', redirect: (context, state) => '/intro'),

    // GD1: Giới thiệu
    GoRoute(path: '/intro', builder: (context, state) => const IntroScreen()),

    // GD2: Đăng nhập
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // Đăng ký tài khoản (mở từ màn Đăng nhập)
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // 5 tab chính, dùng chung thanh menu dưới.
    // Mỗi tab giữ nguyên trạng thái khi chuyển qua lại.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/styles',
            builder: (context, state) => const StylesScreen(),
            routes: [
              // Chi tiết mẫu tóc, vẫn nằm trong tab Mẫu nên giữ thanh menu dưới.
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    HairStyleDetailScreen(styleId: state.pathParameters['id']!),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/ar', builder: (context, state) => const ArTryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/booking', builder: (context, state) => const BookingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
