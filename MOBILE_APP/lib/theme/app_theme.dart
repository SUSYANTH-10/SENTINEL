import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // --- Brand Color Tokens (Modern Fintech: Navy & Royal Blue) ---
  static const Color primaryNavy = Color(0xFF0F2744);
  static const Color primaryNavyDark = Color(0xFF0A192F);
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color brandBlueLight = Color(0xFF3B82F6);
  static const Color brandBlueAccent = Color(0xFF60A5FA);

  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color secondaryTealLight = Color(0xFF14B8A6);

  // --- Semantic State Colors ---
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertRedBg = Color(0xFFFEE2E2);
  static const Color warnOrange = Color(0xFFF59E0B);
  static const Color warnOrangeBg = Color(0xFFFEF3C7);
  static const Color safeGreen = Color(0xFF10B981);
  static const Color safeGreenBg = Color(0xFFECFDF5);

  // --- Neutral Tokens ---
  static const Color neutralSlate50 = Color(0xFFF8FAFC);
  static const Color neutralSlate100 = Color(0xFFF1F5F9);
  static const Color neutralSlate200 = Color(0xFFE2E8F0);
  static const Color neutralSlate300 = Color(0xFFCBD5E1);
  static const Color neutralSlate400 = Color(0xFF94A3B8);
  static const Color neutralSlate500 = Color(0xFF64748B);
  static const Color neutralSlate700 = Color(0xFF334155);
  static const Color neutralSlate800 = Color(0xFF1E293B);
  static const Color neutralSlate900 = Color(0xFF0F172A);
  static const Color neutralDarkBg = Color(0xFF0B0F19);
  static const Color neutralDarkSurface = Color(0xFF151D2E);

  // ============================================================
  // LIGHT THEME (Clean, Crisp, Modern Banking)
  // ============================================================
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: brandBlue,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBEAFE),
      onPrimaryContainer: const Color(0xFF1E3A8A),
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: neutralSlate900,
      surfaceContainerHighest: neutralSlate100,
      onSurfaceVariant: neutralSlate500,
      error: alertRed,
      onError: Colors.white,
      errorContainer: alertRedBg,
      onErrorContainer: const Color(0xFF991B1B),
      outline: neutralSlate300,
      outlineVariant: neutralSlate200,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: neutralSlate50,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: neutralSlate900,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: neutralSlate900,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: neutralSlate900),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: neutralSlate200, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: neutralSlate800,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: neutralSlate300, width: 1.2),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        prefixIconColor: neutralSlate400,
        suffixIconColor: neutralSlate400,
        labelStyle: const TextStyle(color: neutralSlate500, fontSize: 14),
        hintStyle: const TextStyle(color: neutralSlate400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralSlate300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralSlate300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: neutralSlate200,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: neutralSlate200, width: 1),
        ),
      ),
    );
  }

  // ============================================================
  // DARK THEME (Sleek Midnight Charcoal)
  // ============================================================
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: brandBlueAccent,
      onPrimary: neutralDarkBg,
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFDBEAFE),
      secondary: secondaryTealLight,
      onSecondary: neutralDarkBg,
      surface: neutralDarkSurface,
      onSurface: neutralSlate50,
      surfaceContainerHighest: const Color(0xFF1F293D),
      onSurfaceVariant: neutralSlate400,
      error: alertRed,
      onError: Colors.white,
      errorContainer: const Color(0xFF450A0A),
      onErrorContainer: const Color(0xFFFCA5A5),
      outline: const Color(0xFF334155),
      outlineVariant: const Color(0xFF243046),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: neutralDarkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: neutralDarkSurface,
        foregroundColor: neutralSlate50,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: neutralSlate50,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: neutralSlate50),
      ),
      cardTheme: CardThemeData(
        color: neutralDarkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF243046), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: neutralSlate50,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFF334155), width: 1.2),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralDarkSurface,
        prefixIconColor: neutralSlate400,
        suffixIconColor: neutralSlate400,
        labelStyle: const TextStyle(color: neutralSlate400, fontSize: 14),
        hintStyle: const TextStyle(color: neutralSlate500, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandBlueAccent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF243046),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: neutralDarkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF243046), width: 1),
        ),
      ),
    );
  }
}
