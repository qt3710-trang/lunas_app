/// Người dùng đang đăng nhập.
class AppUser {
  const AppUser({required this.id, required this.name, required this.phone});

  final String id;     // D3: chính là uid của Firebase
  final String name;
  final String phone;
}

/// Lỗi đăng nhập / đăng ký, kèm câu báo tiếng Việt.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Nơi DUY NHẤT xử lý tài khoản: đăng ký, đăng nhập, đăng xuất.
/// Bây giờ: dữ liệu giả. Bài D3: đổi sang Firebase Auth.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // "Bảng tài khoản" giả: SĐT -> thông tin. Có sẵn 1 tài khoản để thử.
  final Map<String, Map<String, String>> _accounts = {
    '0901234567': {'id': 'demo_user', 'name': 'Linh', 'password': '123456'},
  };

  AppUser? _currentUser;

  /// Người đang đăng nhập (null = chưa đăng nhập).
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Đăng ký tài khoản mới.
  Future<AppUser> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_accounts.containsKey(phone)) {
      throw AuthException('Số điện thoại này đã được đăng ký');
    }

    final id = 'user_$phone';
    _accounts[phone] = {'id': id, 'name': name, 'password': password};
    _currentUser = AppUser(id: id, name: name, phone: phone);
    return _currentUser!;
  }

  /// Đăng nhập.
  Future<AppUser> login({required String phone, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final account = _accounts[phone];
    if (account == null) {
      throw AuthException('Số điện thoại chưa được đăng ký');
    }
    if (account['password'] != password) {
      throw AuthException('Mật khẩu không đúng');
    }

    _currentUser = AppUser(id: account['id']!, name: account['name']!, phone: phone);
    return _currentUser!;
  }

  /// Quên mật khẩu.
  Future<void> sendPasswordReset({required String phone}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_accounts.containsKey(phone)) {
      throw AuthException('Số điện thoại chưa được đăng ký');
    }
  }

  /// Đăng xuất.
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}