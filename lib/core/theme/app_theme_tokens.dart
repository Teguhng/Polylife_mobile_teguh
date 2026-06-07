import 'package:flutter/material.dart';

extension AppThemeTokens on BuildContext {
  ThemeData get appTheme => Theme.of(this);

  ColorScheme get appScheme => appTheme.colorScheme;

  bool get isDarkMode => appTheme.brightness == Brightness.dark;

  Color get appBackground => appTheme.scaffoldBackgroundColor;

  Color get appSurface => isDarkMode ? const Color(0xFF0F172A) : Colors.white;

  Color get appSurfaceAlt =>
      isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

  Color get appSubtle =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  Color get appText =>
      isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get appMuted =>
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Color get appFaint =>
      isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  Color get appBorder =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  Color get appPrimary => appScheme.primary;

  Color get appPrimarySoft =>
      isDarkMode ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);

  Color get appSuccess =>
      isDarkMode ? const Color(0xFF34D399) : const Color(0xFF16A34A);

  Color get appSuccessSoft =>
      isDarkMode ? const Color(0xFF052E2B) : const Color(0xFFECFDF3);

  Color get appWarning =>
      isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

  Color get appWarningSoft =>
      isDarkMode ? const Color(0xFF422006) : const Color(0xFFFFF7ED);

  Color get appDanger =>
      isDarkMode ? const Color(0xFFFB7185) : const Color(0xFFE11D48);

  Color get appDangerSoft =>
      isDarkMode ? const Color(0xFF3F1D2B) : const Color(0xFFFFF1F2);

  List<BoxShadow> get appCardShadow {
    if (isDarkMode) {
      return const [];
    }

    return const [
      BoxShadow(color: Color(0x120F172A), blurRadius: 16, offset: Offset(0, 8)),
    ];
  }
}
