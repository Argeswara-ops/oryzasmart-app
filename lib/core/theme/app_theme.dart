import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Field dashboard palette for agricultural IoT.
  static const primaryGreen = Color(0xFF059669);
  static const primaryGreenDark = Color(0xFF047857);
  static const primaryGreenLight = Color(0xFF10B981);
  static const mintAccent = Color(0xFF34D399);
  static const mintLight = Color(0xFFD1FAE5);
  static const bgMint = Color(0xFFF4FAF7);
  static const cardBorder = Color(0xFFDDEAE3);
  static const warning = Color(0xFFD97706);
  static const critical = Color(0xFFDC2626);
  static const infoBlue = Color(0xFF0284C7);
  static const teal = Color(0xFF0D9488);
  static const textStrong = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        primaryContainer: mintLight,
        onPrimaryContainer: primaryGreenDark,
        secondary: teal,
        tertiary: warning,
        error: critical,
        surface: Colors.white,
        onSurface: textStrong,
      ),
      scaffoldBackgroundColor: bgMint,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgMint,
        foregroundColor: textStrong,
        titleTextStyle: TextStyle(
          color: textStrong,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 12,
        shadowColor: primaryGreen.withValues(alpha: 0.08),
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 19);
          }
          return const IconThemeData(color: textMuted, size: 18);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryGreen,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            );
          }
          return const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryGreen;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF334155);
          }),
          side: WidgetStateProperty.all(const BorderSide(color: cardBorder)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
