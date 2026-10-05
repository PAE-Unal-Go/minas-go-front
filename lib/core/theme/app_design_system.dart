import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Primary
  static const Color primaryMain = Color(0xFF0E147A);
  static const Color primaryDark = Color(0xFF0A0F5A);
  static const Color primaryLight = Color(0xFF1C2AD8);

  // Secondary
  static const Color secondaryMain = Color(0xFF2DD4BF);
  static const Color secondaryDark = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFF99F6E4);

  // Accent
  static const Color accentMain = Color(0xFFFF6B6B);
  static const Color accentDark = Color(0xFFE63946);
  static const Color accentLight = Color(0xFFFFB4A2);

  // Neutral
  static const Color background = Color(0xFFF5F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color primaryMain40 = Color(0x660E147A);
  static const Color primaryMain30 = Color(0x4D0E147A);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Gamification states
  static const Color stateLocked = Color(0xFFCBD5E1);
  static const Color stateAvailable = Color(0xFF2DD4BF);
  static const Color stateDiscovered = Color(0xFFFF6B6B);
  static const Color stateCompleted = Color(0xFFF59E0B);
}

abstract final class AppTypography {
  static const String fontFamilyBase = 'Poppins';

  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 24;
  static const double fontSize2xl = 32;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const double lineHeightTight = 1.2;
  static const double lineHeightBase = 1.5;
  static const double lineHeightRelaxed = 1.7;
}

abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppShadows {
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x140F172A),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x1F0F172A),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x290F172A),
    blurRadius: 40,
    offset: Offset(0, 16),
  );
}

abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryMain, AppColors.primaryLight],
  );

  static const LinearGradient exploration = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryMain, AppColors.secondaryMain],
  );
}

abstract final class AppLayout {
  static const double containerMaxWidth = 1200;
  static const Duration transitionBase = Duration(milliseconds: 180);
}

class AppTheme {
  static ThemeData light() {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryMain,
        secondary: AppColors.secondaryMain,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      dividerColor: AppColors.border,
      disabledColor: AppColors.disabled,
    );
  }
}
