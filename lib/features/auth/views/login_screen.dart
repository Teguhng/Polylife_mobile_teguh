import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_frame.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Email dan password wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await ref.read(authProvider.notifier).login(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      badgeText: 'MASUK',
      title: 'Selamat datang kembali di PolyLife',
      subtitle:
          'Pantau jadwal kuliah, IPK, dan pengingat penting dari satu tempat.',
      children: [
        if (_errorText != null) ...[
          AuthMessageBox(message: _errorText!, tone: AuthMessageTone.error),
          const SizedBox(height: 18),
        ],
        AutofillGroup(
          child: Column(
            children: [
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                hintText: 'nama@kampus.ac.id',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                hintText: '********',
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  TextInput.finishAutofillContext();
                  if (!_isLoading) {
                    _handleLogin();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : () => context.go('/forgot-password'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6A5BFF),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Lupa password?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AuthPrimaryButton(
          text: 'LOGIN',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 24),
        AuthFooterLink(
          prefix: 'Belum punya akun? ',
          actionText: 'Register',
          onTap: () => context.go('/register'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
