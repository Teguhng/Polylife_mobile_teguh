import 'package:flutter/material.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';

enum AuthMessageTone { error, success }

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String badgeText;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final panelBackground = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.96)
        : const Color(0xFFFDFBFF).withValues(alpha: 0.96);
    final textColor = context.appText;
    final mutedColor = isDark
        ? const Color(0xFFA5B4FC)
        : const Color(0xFF6D6797);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF020617),
                        Color(0xFF111827),
                        Color(0xFF1E1B4B),
                      ]
                    : const [
                        Color(0xFFFFF7FB),
                        Color(0xFFF7F4FF),
                        Color(0xFFFDF8FF),
                      ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.3,
                child: CustomPaint(
                  painter: _GridPainter(
                    lineColor: const Color(
                      0xFF8181FF,
                    ).withValues(alpha: isDark ? 0.12 : 0.2),
                    step: 32,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -72,
            right: -44,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF4C1D95) : const Color(0xFFFFCCE1))
                        .withValues(alpha: 0.55),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color.fromRGBO(2, 6, 23, 0.8)
                        : const Color.fromRGBO(255, 255, 255, 0.7),
                    offset: const Offset(12, 12),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -88,
            left: -46,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF164E63) : const Color(0xFFC9E5FF))
                        .withValues(alpha: 0.55),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color.fromRGBO(2, 6, 23, 0.65)
                        : const Color.fromRGBO(255, 255, 255, 0.45),
                    offset: const Offset(-12, -12),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF8181FF),
                        width: 4,
                      ),
                      color: panelBackground,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFFC5D4FF),
                          offset: const Offset(12, 12),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const _CornerBlock(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AuthBrandHeader(badgeText: badgeText),
                              const SizedBox(height: 26),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 30,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ).copyWith(color: textColor),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ).copyWith(color: mutedColor),
                              ),
                              const SizedBox(height: 22),
                              ...children,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final muted = context.isDarkMode
        ? const Color(0xFFA5B4FC)
        : const Color(0xFF4C4C63);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          decoration: _inputDecoration(
            context: context,
            hintText: hintText,
            icon: icon,
          ),
          onFieldSubmitted: onSubmitted,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hintText,
    required IconData icon,
  }) {
    final isDark = context.isDarkMode;
    final borderColor = const Color(
      0xFF8181FF,
    ).withValues(alpha: isDark ? 0.55 : 0.4);

    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6D6797),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F4FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFFA7A6C9),
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF8181FF), width: 2),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8181FF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8B8FF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF2B2250), width: 2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }
}

class AuthMessageBox extends StatelessWidget {
  const AuthMessageBox({super.key, required this.message, required this.tone});

  final String message;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final isSuccess = tone == AuthMessageTone.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFDA4AF),
          width: 2,
        ),
        color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isSuccess ? const Color(0xFF166534) : const Color(0xFFBE123C),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.actionText,
    required this.onTap,
  });

  final String prefix;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (prefix.isNotEmpty)
            Text(
              prefix,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6A5BFF),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader({required this.badgeText});

  final String badgeText;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2B2250), width: 4),
            color: const Color(0xFF8181FF),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF2B2250),
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'PL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PolyLife',
              style: TextStyle(
                color: context.appText,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'WORKSPACE',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFA5B4FC)
                    : const Color(0xFF6D6797),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2B2250).withValues(alpha: 0.2),
              width: 2,
            ),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              color: Color(0xFF6D6797),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerBlock extends StatelessWidget {
  const _CornerBlock();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -22,
      right: 42,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2B2250), width: 4),
          color: const Color(0xFFF49CC8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF2B2250),
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.lineColor, required this.step});

  final Color lineColor;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.step != step;
  }
}
