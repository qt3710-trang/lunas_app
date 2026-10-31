import 'package:firebase_auth/firebase_auth.dart';

/// Người dùng đang đăng nhập.
class AppUser {
  const AppUser({required this.id, required this.name, required this.phone});

  final String id; // uid của Firebase (mã riêng của mỗi tài khoản)
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
/// Dùng Firebase Auth thật.
///
/// Firebase không có kiểu "số điện thoại + mật khẩu", nên mình đổi
/// số điện thoại thành email giả: 0912345678 -> 0912345678@lunas.app
/// Người dùng không bao giờ thấy email này.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // "Cổng" nói chuyện với Firebase Auth.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _emailDomain = '@lunas.app';

  // ---------------------------------------------------------------
  // Người đang đăng nhập
  // ---------------------------------------------------------------

  /// Người đang đăng nhập (null = chưa đăng nhập).
  /// Lấy thẳng từ Firebase, nên tắt app mở lại Firebase vẫn nhớ.
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _toAppUser(user);
  }

  bool get isLoggedIn => _auth.currentUser != null;

  // ---------------------------------------------------------------
  // Đăng ký
  // ---------------------------------------------------------------

  /// Đăng ký tài khoản mới trên Firebase.
  Future<AppUser> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final cleanPhone = _cleanPhone(phone);
    try {
      // 1. Tạo tài khoản bằng email giả + mật khẩu.
      final result = await _auth.createUserWithEmailAndPassword(
        email: _phoneToEmail(cleanPhone),
        password: password,
      );
      final user = result.user!;

      // 2. Lưu tên hiển thị vào tài khoản Firebase.
      await user.updateDisplayName(name.trim());
      await user.reload(); // tải lại để Firebase cập nhật tên mới

      return AppUser(id: user.uid, name: name.trim(), phone: cleanPhone);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  // ---------------------------------------------------------------
  // Đăng nhập
  // ---------------------------------------------------------------

  /// Đăng nhập bằng số điện thoại + mật khẩu.
  Future<AppUser> login({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = _cleanPhone(phone);
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: _phoneToEmail(cleanPhone),
        password: password,
      );
      return _toAppUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  // ---------------------------------------------------------------
  // Quên mật khẩu
  // ---------------------------------------------------------------

  /// Email @lunas.app là email giả, không có hộp thư thật,
  /// nên KHÔNG gửi được thư đặt lại mật khẩu.
  /// Tạm thời báo người dùng liên hệ salon.
  Future<void> sendPasswordReset({required String phone}) async {
    throw AuthException(
      'Vui lòng liên hệ salon LUNAS để được hỗ trợ đặt lại mật khẩu.',
    );
  }

  // ---------------------------------------------------------------
  // Đăng xuất
  // ---------------------------------------------------------------

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------
  // Các hàm phụ (chỉ dùng trong file này, nên có dấu _ ở đầu)
  // ---------------------------------------------------------------

  /// Chỉ giữ lại chữ số: " 0912 345.678 " -> "0912345678".
  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  /// "0912345678" -> "0912345678@lunas.app"
  String _phoneToEmail(String cleanPhone) => '$cleanPhone$_emailDomain';

  /// Đổi người dùng của Firebase (User) thành AppUser của app mình.
  AppUser _toAppUser(User user) {
    final email = user.email ?? '';
    final phone = email.replaceAll(_emailDomain, '');
    return AppUser(
      id: user.uid,
      name: user.displayName ?? '',
      phone: phone,
    );
  }

  /// Đổi mã lỗi tiếng Anh của Firebase thành câu tiếng Việt.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Số điện thoại này đã được đăng ký';
      case 'invalid-email':
        return 'Số điện thoại không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự';
      // Firebase mới gộp chung "sai mật khẩu" và "chưa có tài khoản"
      // thành invalid-credential (để kẻ xấu không dò được SĐT nào đã đăng ký).
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Số điện thoại hoặc mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản này đã bị khoá';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần, vui lòng đợi một lúc rồi thử lại';
      case 'network-request-failed':
        return 'Không có kết nối mạng, vui lòng kiểm tra lại';
      case 'operation-not-allowed':
        return 'Chưa bật đăng nhập Email/Password trên Firebase';
      default:
        return 'Có lỗi xảy ra (${e.code}), vui lòng thử lại';
    }
  }
}