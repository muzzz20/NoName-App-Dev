import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Temporary home screen until NAD-12 (Reports Feed) lands.
/// Confirms auth flow works end-to-end by showing current user email
/// + entry points to Profile + sign out.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strayfriends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.submitReport),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Report a Cat'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back!', style: AppText.headlineMd),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                user?.email ?? '—',
                style: AppText.bodySm.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: AppSpacing.stackXl),
              Card(
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports Feed coming next',
                        style: AppText.titleSm,
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        'This screen will be replaced by the Reports Feed '
                        '(NAD-12). Auth flow is verified — you can register, '
                        'log in, view your profile, and sign out.',
                        style: AppText.bodySm,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
