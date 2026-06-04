import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Shows a modal bottom sheet prompting an unauthenticated user to sign in
/// before performing an auth-gated action (donate, volunteer, report, …).
///
/// Centralizes the "Sign in required" UX so every visitor gate across the
/// app looks and behaves identically. [action] completes the sentence
/// "Sign in to …" (e.g. `'donate'`, `'report a cat'`).
void showSignInPrompt(BuildContext context, String action) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.stackLg, 0,
              AppSpacing.stackLg, AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Sign in required',
                  style: AppText.titleSm, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.stackXs),
              Text('Sign in to $action.',
                  style: AppText.bodySm.copyWith(color: AppColors.secondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.stackLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.login);
                  },
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
