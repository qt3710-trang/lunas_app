import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/lunas_logo.dart';

/// Màn Đăng nhập bằng số điện thoại + mật khẩu.
/// Gọi AuthService.login() (Firebase Auth).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Hộp "Quên mật khẩu": nhập SĐT rồi gửi yêu cầu.
  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _phoneController.text.trim());
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(hintText: 'Số điện thoại đã đăng ký'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;

    try {
      await AuthService.instance.sendPasswordReset(phone: phone);
      _toast('Đã gửi hướng dẫn đặt lại mật khẩu');
    } on AuthException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => context.push('/register'),
                    child: const Text('Đăng ký'),
                  ),
                ),
                const SizedBox(height: 8),
                const LunasLogo(size: 0.7),
                const SizedBox(height: 32),
                Text(
                  'Chào mừng bạn trở lại!',
                  textAlign: TextAlign.center,
                  style: AppTheme.titleFont(size: 28),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để tiếp tục hành trình khám phá\nphong cách tóc của riêng bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey, height: 1.5),
                ),
                const SizedBox(height: 32),

                const Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  // Chỉ cho gõ chữ số, tối đa 10 số
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Nhập số điện thoại của bạn',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final phone = v?.trim() ?? '';
                    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
                    // Số di động VN: 10 số, bắt đầu bằng 03, 05, 07, 08, 09
                    if (!RegExp(r'^0[35789]\d{8}$').hasMatch(phone)) {
                      return 'Số điện thoại không hợp lệ (10 số, đầu 03/05/07/08/09)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Đăng nhập'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bạn chưa có tài khoản?'),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Đăng ký ngay'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Khi tiếp tục, bạn đồng ý với Điều khoản sử dụng\nvà Chính sách quyền riêng tư của LUNAS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}