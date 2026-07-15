import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ride Buddy visual system — bright commute / sky + asphalt energy.
class AppTheme {
  static const brandBlue = Color(0xFF1D4ED8);
  static const brandOrange = Color(0xFFEA580C);
  static const ink = Color(0xFF0F172A);
  static const inkMuted = Color(0xFF64748B);
  static const surface = Color(0xFFF8FAFC);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const skyTop = Color(0xFFE8F1FF);
  static const skyMid = Color(0xFFF5F8FC);
  static const line = Color(0xFFE2E8F0);
  static const success = Color(0xFF059669);
  static const danger = Color(0xFFDC2626);

  static TextTheme _textTheme(TextTheme base) {
    final body = GoogleFonts.dmSansTextTheme(base).apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final display = GoogleFonts.outfitTextTheme(base);
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: ink, letterSpacing: -1),
      displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.8),
      displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: ink),
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.6),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: ink),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: ink),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: ink),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: ink),
      bodyLarge: body.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.4, color: inkMuted),
      bodySmall: body.bodySmall?.copyWith(color: inkMuted),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: brandOrange,
      onSecondary: Colors.white,
      surface: surfaceElevated,
      onSurface: ink,
      error: danger,
      onError: Colors.white,
      outline: line,
      surfaceContainerHighest: skyMid,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: brandBlue, width: 1.4),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlue,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: inkMuted),
        labelStyle: const TextStyle(color: inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surfaceElevated,
        indicatorColor: brandBlue.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? brandBlue : inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? brandBlue : inkMuted, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: skyMid,
        selectedColor: brandOrange.withOpacity(0.18),
        checkmarkColor: brandOrange,
        side: const BorderSide(color: line),
        labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: brandBlue,
        contentPadding: EdgeInsets.symmetric(horizontal: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandBlue,
        linearTrackColor: line,
      ),
    );
  }
}
