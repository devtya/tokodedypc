import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════════════════════
  //  PALETTE — DedyStore Design System (green-themed, OKLCH-based)
  // ═══════════════════════════════════════════════════════════════════

  // ── DARK PALETTE ──────────────────────────────────────────────────
  static const Color background = Color(0xFF1B1E1C);
  static const Color surface = Color(0xFF232825);
  static const Color border = Color(0xFF3D423F);
  static const Color divider = Color(0xFF3A3F3C);
  static const Color muted = Color(0xFF293228);
  static const Color grey = Color(0xFF6B7A70);
  static const Color white = Color(0xFFFFFFFF);
  static const Color white06 = Color(0x0FFFFFFF);
  static const Color white03 = Color(0x08FFFFFF);
  static const Color white02 = Color(0x05FFFFFF);

  // ── Primary (Green) ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2DC571);
  static const Color onPrimary = Color(0xFF0F1E14);
  static const Color primaryContainer = Color(0xFF1A3A28);
  static const Color primaryContainerLight = Color(0xFF245A38);
  static const Color primarySoft = Color(0x1F2DC571);
  static const Color primaryBorder = Color(0x33FFFFFF);

  // ── Secondary / Accent ───────────────────────────────────────────
  static const Color secondary = Color(0xFF28332B);
  static const Color onSecondary = Color(0xFFF1F4EF);
  static const Color accent = Color(0xFF273B2D);
  static const Color onAccent = Color(0xFFF1F4EF);

  // ── Status ───────────────────────────────────────────────────────
  static const Color error = Color(0xFFE74C3C);
  static const Color errorSoft = Color(0x14E74C3C);
  static const Color errorBorder = Color(0x4DE74C3C);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF3498DB);
  static const Color success = Color(0xFF2DC571);

  // ── Surface variants ─────────────────────────────────────────────
  static const Color surfaceContainerLow = Color(0xFF1B1E1C);
  static const Color surfaceInput = Color(0xFF232825);

  // ── LIGHT PALETTE ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FBF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFDDE6DE);
  static const Color lightDivider = Color(0xFFE4EBE4);
  static const Color lightGrey = Color(0xFF72877A);
  static const Color lightText = Color(0xFF1C2E25);
  static const Color lightTextSecondary = Color(0xFF4A5F52);

  // ── Light secondary / accent ─────────────────────────────────────
  static const Color lightSecondary = Color(0xFFEAF0E8);
  static const Color lightOnSecondary = Color(0xFF2A4E38);
  static const Color lightAccent = Color(0xFFE2EDE0);
  static const Color lightOnAccent = Color(0xFF244A33);

  // ── BACKWARD-COMPATIBLE ALIASES ──────────────────────────────────
  static const Color primaryGreen = primary;
  static const Color accentGreen = primary;
  static const Color lightGreen = primaryContainer;
  static const Color darkGreen = onPrimary;
  static const Color warningRed = error;
  static const Color warningOrange = warning;
  static const Color neutralGrey = grey;

  // ── SIDEBAR PALETTE ────────────────────────────────────────────────
  static const Color sidebarBackgroundDark = Color(0xFF111827);  // Gray 900
  static const Color sidebarBackgroundLight = Color(0xFF0F172A); // Slate 900

  // ── SEMANTIC NAVIGATION COLORS ─────────────────────────────────────
  static const Color navDashboard = primary;
  static const Color navKasir = primary;
  static const Color navProduk = Color(0xFF3498DB);      // Info (Biru)
  static const Color navTransaksi = Color(0xFF009688);   // Teal
  static const Color navLaporan = Color(0xFF9C27B0);     // Purple
  static const Color navPembelian = Color(0xFF009688);   // Teal
  static const Color navPurchaseOrder = Color(0xFFFF9800); // Warning (Orange)
  static const Color navSupplier = Color(0xFF795548);    // Brown
  static const Color navHutang = Color(0xFFFF9800);       // Warning (Orange)
  static const Color navOnlineOrder = Color(0xFF3F51B5);  // Indigo
  static const Color navPengguna = Color(0xFF795548);     // Brown
  static const Color navPengaturan = Color(0xFF6B7A70);   // Neutral Grey

  // ── Border Radii (DedyStore System) ──────────────────────────────
  static const double radiusSm = 7;
  static const double radiusMd = 10;
  static const double radiusLg = 12;
  static const double radiusXl = 17;
  static const double radius2xl = 22;
  static const double radius3xl = 26;
  static const double radius4xl = 31;

  // ── Font ─────────────────────────────────────────────────────────
  static final String? fontFamily = GoogleFonts.inter().fontFamily;

  // ══════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ══════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        secondary: primary,
        onSecondary: onPrimary,
        error: error,
        surface: surface,
        onSurface: white,
        outline: border,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        labelStyle: const TextStyle(
          color: grey,
          fontSize: 9,
          letterSpacing: 1.5,
        ),
        hintStyle: const TextStyle(color: grey, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return const Color(0xFF3A3F3C);
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ══════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: fontFamily,

      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD5F5E3),
        secondary: primary,
        onSecondary: Colors.white,
        error: error,
        surface: lightSurface,
        onSurface: lightText,
        outline: lightBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: lightBorder, width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        labelStyle: const TextStyle(
          color: lightGrey,
          fontSize: 9,
          letterSpacing: 1.5,
        ),
        hintStyle: const TextStyle(color: lightGrey, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(color: lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return const Color(0xFFDDE6DE);
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurface,
        contentTextStyle: const TextStyle(color: lightText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
