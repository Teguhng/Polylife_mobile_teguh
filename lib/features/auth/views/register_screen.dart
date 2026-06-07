import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_frame.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmation = _passwordConfirmationController.text;

    final localError = _validateInput(
      name: name,
      email: email,
      password: password,
      confirmation: confirmation,
    );

    if (localError != null) {
      setState(() {
        _errorText = localError;
        _successText = null;
      });
      return;
    }

    TextInput.finishAutofillContext();
    setState(() {
      _isLoading = true;
      _errorText = null;
      _successText = null;
    });

    final result = await ref
        .read(authProvider.notifier)
        .register(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: confirmation,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _successText = result.message;
        _errorText = null;
        _passwordController.clear();
        _passwordConfirmationController.clear();
      } else {
        _errorText = result.message;
        _successText = null;
      }
    });
  }

  String? _validateInput({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) {
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmation.isEmpty) {
      return 'Nama, email, dan password wajib diisi.';
    }

    if (!email.contains('@')) {
      return 'Format email belum valid.';
    }

    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }

    if (password != confirmation) {
      return 'Konfirmasi password belum sama.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      badgeText: 'DAFTAR',
      title: 'Buat akun PolyLife',
      subtitle: 'Mulai rapikan jadwal, tugas, catatan, dan pengingat kampusmu.',
      children: [
        if (_errorText != null) ...[
          AuthMessageBox(message: _errorText!, tone: AuthMessageTone.error),
          const SizedBox(height: 18),
        ],
        if (_successText != null) ...[
          AuthMessageBox(message: _successText!, tone: AuthMessageTone.success),
          const SizedBox(height: 18),
        ],
        AutofillGroup(
          child: Column(
            children: [
              AuthTextField(
                label: 'Nama',
                controller: _nameController,
                hintText: 'Nama lengkap',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                hintText: 'nama@kampus.ac.id',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Minimal 8 karakter',
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Konfirmasi Password',
                controller: _passwordConfirmationController,
                hintText: 'Ulangi password',
                icon: Icons.lock_reset_outlined,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _handleRegister();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          text: 'REGISTER',
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),
        const SizedBox(height: 24),
        AuthFooterLink(
          prefix: 'Sudah punya akun? ',
          actionText: 'Login',
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }
}
