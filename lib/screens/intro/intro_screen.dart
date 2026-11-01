import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// GD1: Màn giới thiệu – logo + nút "Chạm để bắt đầu".
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      Image.asset(
                        'assets/branding/lunas_logo.png',
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                        semanticLabel: 'LUNAS Hair Studio',
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Khám phá vẻ đẹp của bạn\nbắt đầu từ mái tóc',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(flex: 2),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Chạm để bắt đầu'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'BEAUTY  ·  HAIR  ·  STYLE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
