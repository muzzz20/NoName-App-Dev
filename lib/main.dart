import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StrayfriendsApp());
}

class StrayfriendsApp extends StatelessWidget {
  const StrayfriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strayfriends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Strayfriends', style: AppText.displayLg),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'UTM stray cat reporting & welfare platform',
                style: AppText.bodySm.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.stackXl),
              _StatusRow(
                label: 'Firebase project',
                value: app.options.projectId,
              ),
              _StatusRow(label: 'App ID', value: app.options.appId),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Sprint 1 screens come next (NAD-7..NAD-15).',
                style: AppText.bodySm.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: AppText.labelCaps)),
          Expanded(
            child: Text(
              value,
              style: AppText.bodySm.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
