import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Emerald Green palette tailored for Agricultural IoT
  static const primaryGreen = Color(0xFF059669); // Emerald 600
  static const primaryGreenDark = Color(0xFF047857); // Emerald 700
  static const primaryGreenLight = Color(0xFF10B981); // Emerald 500
  static const mintAccent = Color(0xFF34D399); // Emerald 400
  static const mintLight = Color(0xFFD1FAE5); // Emerald 100
  static const bgMint = Color(0xFFF2FBF6); // Soft mint background
  static const cardBorder = Color(0xFFE2F1E8); // Subtle green-gray border

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        primaryContainer: mintLight,
        onPrimaryContainer: primaryGreenDark,
        secondary: const Color(0xFF0D9488), // Teal accent
        tertiary: const Color(0xFFD97706), // Amber warning
        error: const Color(0xFFDC2626), // Red alert
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: bgMint,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgMint,
        foregroundColor: Color(0xFF0F172A),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
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
            return const IconThemeData(color: primaryGreen, size: 21);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryGreen,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
