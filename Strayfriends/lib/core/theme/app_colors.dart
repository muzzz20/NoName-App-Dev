import 'package:flutter/material.dart';

/// Strayfriends color palette — "Humane Modernity" design system.
///
/// Source: `/AD/design-reference/DESIGN.md` (frontmatter `colors:` block).
/// All hex values must match DESIGN.md exactly. If you need a new color,
/// add it to DESIGN.md first.
class AppColors {
  AppColors._();

  // --- Surfaces (warm cream foundation) ---
  static const surface = Color(0xFFF8F9FB);
  static const surfaceDim = Color(0xFFD9DADC);
  static const surfaceBright = Color(0xFFF8F9FB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F6);
  static const surfaceContainer = Color(0xFFEDEEF0);
  static const surfaceContainerHigh = Color(0xFFE7E8EA);
  static const surfaceContainerHighest = Color(0xFFE1E2E4);
  static const surfaceVariant = Color(0xFFE1E2E4);
  static const surfaceTint = Color(0xFFB22B1D);
  static const background = Color(0xFFF8F9FB);

  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF5A413D);
  static const onBackground = Color(0xFF191C1E);
  static const inverseSurface = Color(0xFF2E3132);
  static const inverseOnSurface = Color(0xFFF0F1F3);

  // --- Primary (UTM Maroon) ---
  static const primary = Color(0xFF570000);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF800000);
  static const onPrimaryContainer = Color(0xFFFF8371);
  static const inversePrimary = Color(0xFFFFB4A8);
  static const primaryFixed = Color(0xFFFFDAD4);
  static const primaryFixedDim = Color(0xFFFFB4A8);
  static const onPrimaryFixed = Color(0xFF410000);
  static const onPrimaryFixedVariant = Color(0xFF8F0F07);

  // --- Secondary (Soft Beige neutral) ---
  static const secondary = Color(0xFF605E5B);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE6E2DD);
  static const onSecondaryContainer = Color(0xFF666460);
  static const secondaryFixed = Color(0xFFE6E2DD);
  static const secondaryFixedDim = Color(0xFFC9C6C1);
  static const onSecondaryFixed = Color(0xFF1C1C19);
  static const onSecondaryFixedVariant = Color(0xFF484743);

  // --- Tertiary (Dark earth) ---
  static const tertiary = Color(0xFF2A2620);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF403C35);
  static const onTertiaryContainer = Color(0xFFADA69D);
  static const tertiaryFixed = Color(0xFFE9E1D7);
  static const tertiaryFixedDim = Color(0xFFCDC5BC);
  static const onTertiaryFixed = Color(0xFF1E1B15);
  static const onTertiaryFixedVariant = Color(0xFF4A463F);

  // --- Error / Emergency ---
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // --- Outlines ---
  static const outline = Color(0xFF8E706C);
  static const outlineVariant = Color(0xFFE2BFB9);

  // --- Semantic aliases ---
  /// Reserved strictly for high-priority alerts (injured animals, urgent reports).
  static const emergency = error;

  /// Card border tint per DESIGN.md "Cards & Bento Grid".
  static const cardBorder = Color(0xFFEFE7DD);
}
