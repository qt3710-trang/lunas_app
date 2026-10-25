import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../widgets/lunas_logo.dart';

/// GD2: Đăng nhập bằng số điện thoại + mật khẩu.
///
/// Hiện tại CHƯA nối Firebase: nhập đủ SĐT và mật khẩu là vào Trang chủ.
/// Giai đoạn 2 sẽ thay phần _login() bằng Firebase Auth.
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

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // TODO (giai đoạn 2): kiểm tra tài khoản với Firebase Auth.
      context.go('/home');
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature: sẽ làm ở giai đoạn sau')),
    );
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
                    onPressed: () => _showComingSoon('Đăng ký'),
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

                // Số điện thoại
                const Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Nhập số điện thoại của bạn',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (phone.length < 9) return 'Số điện thoại chưa đúng';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Mật khẩu
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
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Vui lòng nhập mật khẩu';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showComingSoon('Quên mật khẩu'),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _login,
                  child: const Row(
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
                      onPressed: () => _showComingSoon('Đăng ký'),
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
