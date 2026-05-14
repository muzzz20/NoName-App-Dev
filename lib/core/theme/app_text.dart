import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale from DESIGN.md (Inter font, mobile-first).
///
/// Naming follows the DESIGN.md frontmatter keys exactly:
/// `display-lg`, `headline-md`, `title-sm`, `body-base`, `body-sm`, `label-caps`.
class AppText {
  AppText._();

  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 41 / 34,
        letterSpacing: -0.02 * 34,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 30 / 24,
        letterSpacing: -0.01 * 24,
        color: AppColors.onSurface,
      );

  static TextStyle get titleSm => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 25 / 20,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyBase => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 24 / 17,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 21 / 15,
        color: AppColors.onSurface,
      );

  /// Uppercase metadata labels (chips, small tags).
  static TextStyle get labelCaps => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        color: AppColors.onSurfaceVariant,
      );

  /// Build a Material 3 [TextTheme] from the design tokens.
  ///
  /// Mapping rationale (DESIGN.md naming → Material naming):
  /// - `display-lg`  → displayMedium  (we don't define displayLarge/Small)
  /// - `headline-md` → headlineMedium
  /// - `title-sm`    → titleLarge      (DESIGN.md "title-sm" is what M3 calls titleLarge in scale)
  /// - `body-base`   → bodyLarge       (17px is the "comfortable read" size)
  /// - `body-sm`     → bodyMedium
  /// - `label-caps`  → labelSmall      (uppercase tags)
  static TextTheme buildTextTheme() {
    return TextTheme(
      displayLarge: displayLg,
      displayMedium: displayLg,
      displaySmall: headlineMd,
      headlineLarge: headlineMd,
      headlineMedium: headlineMd,
      headlineSmall: titleSm,
      titleLarge: titleSm,
      titleMedium: titleSm,
      titleSmall: titleSm,
      bodyLarge: bodyBase,
      bodyMedium: bodySm,
      bodySmall: bodySm,
      labelLarge: labelCaps,
      labelMedium: labelCaps,
      labelSmall: labelCaps,
    );
  }
}
