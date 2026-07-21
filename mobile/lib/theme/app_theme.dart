import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const coral = Color(0xFFF0653F);
  static const coralLight = Color(0xFFF98E6E);
  static const appBg = Color(0xFFFFF3EC);
  static const panelBg = Color(0xFFFFF8F3);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF4A352D);
  static const textSecondary = Color(0xFFA56A58);
  static const textMuted = Color(0xFFB98A7A);
  static const fieldLabel = Color(0xFFC19585);
  static const placeholder = Color(0xFFC7A99E);
  static const border = Color(0xFFF2E5DB);
  static const inputBorder = Color(0xFFF0DCD0);
  static const inactiveTab = Color(0xFFCDB0A4);
  static const chevron = Color(0xFFD8B6A8);
  static const warnBg = Color(0xFFFFF2E2);
  static const warnBorder = Color(0xFFFFE0C2);
  static const warnIcon = Color(0xFFD98A2F);
  static const warnText = Color(0xFFA8701F);
  static const error = Color(0xFFC83F38);
}

abstract final class AppTheme {
  static const double pagePadding = 20;
  static const double cardRadius = 20;
  static const double sheetRadius = 28;
  static const double controlRadius = 14;

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.coral,
      onPrimary: Colors.white,
      secondary: AppColors.coralLight,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      surfaceContainerHighest: AppColors.panelBg,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.appBg,
    );

    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBg,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fredoka(
          color: AppColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: GoogleFonts.hankenGrotesk(
          color: AppColors.fieldLabel,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.hankenGrotesk(
          color: AppColors.placeholder,
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
          disabledBackgroundColor: AppColors.coralLight,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.coral,
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.coral,
        disabledColor: AppColors.border,
        labelStyle: GoogleFonts.fredoka(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.fredoka(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.inputBorder),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerColor: AppColors.border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.coral,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.hankenGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    final body = GoogleFonts.hankenGroteskTextTheme(base).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return body.copyWith(
      displaySmall: GoogleFonts.fredoka(
        color: AppColors.textPrimary,
        fontSize: 26,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: GoogleFonts.fredoka(
        color: AppColors.textPrimary,
        fontSize: 22,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      headlineSmall: GoogleFonts.fredoka(
        color: AppColors.textPrimary,
        fontSize: 19,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.fredoka(
        color: AppColors.textPrimary,
        fontSize: 15.5,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.fredoka(
        color: AppColors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        color: AppColors.textPrimary,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: GoogleFonts.fredoka(
        color: AppColors.textPrimary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.fredoka(
        color: AppColors.textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x80C4553B),
          blurRadius: 28,
          spreadRadius: -18,
          offset: Offset(0, 13),
        ),
      ];
}
