import 'package:flutter/material.dart';

/// Spacing scale from DESIGN.md — 4px baseline rhythm.
///
/// - Page margins: `containerPadding` (20px, intentionally wider than Material's 16px)
/// - Grid gutters: `gutter` (16px)
/// - Vertical stacks: `stackSm` / `stackMd` / `stackLg`
class AppSpacing {
  AppSpacing._();

  static const double unit = 4;

  /// Standard mobile page margin (DESIGN.md: 20px for "calm vibe").
  static const double containerPadding = 20;

  /// Gap between grid items.
  static const double gutter = 16;

  static const double stackXs = 4;
  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 24;
  static const double stackXl = 32;

  /// Default `EdgeInsets.all(containerPadding)` for page roots.
  static const EdgeInsets pagePadding = EdgeInsets.all(containerPadding);

  static const EdgeInsets horizontalPagePadding =
      EdgeInsets.symmetric(horizontal: containerPadding);
}

/// Border radius scale.
///
/// - `sm` (4): pills/chips inner
/// - `md` (12): buttons, inputs
/// - `lg` (16): cards, primary containers
/// - `xl` (24): hero cards
/// - `full` (9999): pill chips, status tags
class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pillRadius =
      BorderRadius.all(Radius.circular(full));
}
