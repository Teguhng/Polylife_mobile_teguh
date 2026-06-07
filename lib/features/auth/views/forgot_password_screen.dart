import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_frame.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  Future<void> _handleResetRequest() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorText = 'Masukkan email yang valid.';
        _successText = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _successText = null;
    });

    final result = await ref
        .read(authProvider.notifier)
        .requestPasswordReset(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _successText = result.message;
        _errorText = null;
      } else {
        _errorText = result.message;
        _successText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      badgeText: 'RESET',
      title: 'Lupa password?',
      subtitle:
          'Masukkan email akunmu, lalu ikuti link reset yang dikirim ke email.',
      children: [
        if (_errorText != null) ...[
          AuthMessageBox(message: _errorText!, tone: AuthMessageTone.error),
          const SizedBox(height: 18),
        ],
        if (_successText != null) ...[
          AuthMessageBox(message: _successText!, tone: AuthMessageTone.success),
          const SizedBox(height: 18),
        ],
        AuthTextField(
          label: 'Email',
          controller: _emailController,
          hintText: 'nama@kampus.ac.id',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          onSubmitted: (_) {
            if (!_isLoading) {
              _handleResetRequest();
            }
          },
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          text: 'KIRIM LINK RESET',
          isLoading: _isLoading,
          onPressed: _handleResetRequest,
        ),
        const SizedBox(height: 24),
        AuthFooterLink(
          prefix: '',
          actionText: 'Kembali ke login',
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
