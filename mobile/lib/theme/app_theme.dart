import 'package:flutter/material.dart';

abstract final class AppColors {
  static const coral = Color(0xFFF76543);
  static const coralDark = Color(0xFFD94E31);
  static const coralSoft = Color(0xFFFFD9CA);
  static const cream = Color(0xFFFFF6EF);
  static const creamDeep = Color(0xFFF8E8DE);
  static const cocoa = Color(0xFF49342E);
  static const cocoaMuted = Color(0xFF9D7365);
  static const mint = Color(0xFF49BC85);
  static const mintSoft = Color(0xFFE4F7EF);
  static const amber = Color(0xFFF2A13B);
  static const amberSoft = Color(0xFFFFF1D9);
  static const white = Color(0xFFFFFEFC);
  static const outline = Color(0xFFEFD9CE);
  static const shadow = Color(0x247E4534);
  static const error = Color(0xFFC83F38);
}

abstract final class AppTheme {
  static const double pagePadding = 20;
  static const double cardRadius = 28;
  static const double controlRadius = 18;

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.coral,
      onPrimary: Colors.white,
      secondary: AppColors.mint,
      onSecondary: Colors.white,
      surface: AppColors.white,
      onSurface: AppColors.cocoa,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.outline,
      surfaceContainerHighest: AppColors.creamDeep,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
    );

    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: AppColors.outline),
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.cocoa,
            displayColor: AppColors.cocoa,
          )
          .copyWith(
            displaySmall: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
            headlineMedium: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
            headlineSmall: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
            titleLarge: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 21,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
            titleMedium: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            bodyLarge: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: const TextStyle(
              color: AppColors.cocoa,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            labelLarge: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.cocoa,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.cocoa,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: const TextStyle(
          color: AppColors.cocoaMuted,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFB6A49C),
          fontWeight: FontWeight.w500,
        ),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.coral,
            width: 2,
          ),
        ),
        errorBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.coralSoft,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cocoa,
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.coral,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.coral,
        disabledColor: AppColors.creamDeep,
        labelStyle: const TextStyle(
          color: AppColors.cocoa,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
        side: const BorderSide(color: AppColors.outline),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerColor: AppColors.outline,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.coral,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cocoa,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];
}
