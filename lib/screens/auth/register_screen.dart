import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/auth_service.dart';

/// Màn Đăng ký: họ tên, SĐT, mật khẩu, nhập lại mật khẩu.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();   // để kiểm tra cả form một lần
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;
  bool _agree = false;   // đã tích "Đồng ý điều khoản" chưa

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Mọi ô tự kiểm tra (chạy các hàm validator bên dưới)
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      _toast('Bạn cần đồng ý Điều khoản sử dụng');
      return;
    }

    // 2. Gọi service
    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.register(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _toast('Chào mừng ${user.name}!');
      context.go('/home');                 // 3. Thành công -> Trang chủ
    } on AuthException catch (e) {
      _toast(e.message);                   // Lỗi -> hiện câu báo
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),   // có nút quay lại màn Đăng nhập
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tạo tài khoản', style: AppTheme.titleFont(size: 30)),
                const SizedBox(height: 8),
                const Text(
                  'Đăng ký để lưu mẫu tóc yêu thích và đặt lịch nhanh hơn.',
                  style: TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 28),

                _label('Họ và tên'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Nguyễn Thảo Uyên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),

                _label('Số điện thoại'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  // Chỉ cho gõ chữ số, tối đa 10 số
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 0912345678',
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
                const SizedBox(height: 16),

                _label('Mật khẩu'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    hintText: 'Ít nhất 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Mật khẩu phải có ít nhất 6 ký tự' : null,
                ),
                const SizedBox(height: 16),

                _label('Nhập lại mật khẩu'),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _hidePassword,
                  decoration: const InputDecoration(
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v != _passwordController.text ? 'Mật khẩu nhập lại không khớp' : null,
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.teal,
                  title: const Text(
                    'Tôi đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư của LUNAS',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Đăng ký'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản?'),
                    TextButton(
                      onPressed: () => context.pop(),   // quay lại Đăng nhập
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}