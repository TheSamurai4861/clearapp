import 'package:flutter/material.dart';

/// Design tokens defining the visual identity of ClearApp.
/// This includes colors, spacing, borders, shadows, and the global ThemeData.
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color obsidian = Color(0xFF090A0F);      // Primary deep background
  static const Color deepSpace = Color(0xFF0F111A);     // Secondary background/surfaces
  static const Color cardBg = Color(0xFF161925);        // Card background
  static const Color surfaceElevated = Color(0xFF1F2336); // Elevated elements (dialogs, sheets)
  
  // Brand & Accents
  static const Color electricBlue = Color(0xFF00F0FF);  // Vibrant accent (primary)
  static const Color neonPurple = Color(0xFF9D00FF);   // Cyberpunk secondary accent
  static const Color hotPink = Color(0xFFFF007A);      // Error/warning or action accent
  
  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [electricBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient obsidianGradient = LinearGradient(
    colors: [obsidian, deepSpace],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Status & Semantic
  static const Color success = Color(0xFF00FF87);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF00A3FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);   // Pure white for headers
  static const Color textSecondary = Color(0xFF8F9CAE); // Cool grey for subtitles/body
  static const Color textMuted = Color(0xFF5A667A);     // Darker grey for disabled/muted text
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppBorderRadius {
  AppBorderRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: AppColors.electricBlue.withOpacity(0.2),
      blurRadius: 15,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 10,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.electricBlue,
      scaffoldBackgroundColor: AppColors.obsidian,
      cardColor: AppColors.cardBg,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.neonPurple,
        tertiary: AppColors.hotPink,
        surface: AppColors.deepSpace,
        error: AppColors.error,
        onPrimary: AppColors.obsidian,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: AppColors.electricBlue,
          letterSpacing: 1.25,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.lgRadius,
          side: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: AppColors.obsidian,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mdRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlue,
          side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mdRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.electricBlue,
        foregroundColor: AppColors.obsidian,
        elevation: 6,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.textSecondary.withOpacity(0.1),
        thickness: 1,
        space: AppSpacing.lg,
      ),
    );
  }
}
