import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// In-app help / getting-started + FAQ. NAD-65.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: const [
          _Section(
            title: 'Getting started',
            steps: [
              'Browse stray-cat reports and active campaigns on the home '
                  'screen — no account needed.',
              'Create an account (or sign in) to report a cat, donate, or '
                  'volunteer.',
              'Use the quick-nav on the home screen to reach Campaigns, '
                  'Volunteer activities, and Our Impact.',
            ],
          ),
          _Section(
            title: 'Reporting a cat',
            steps: [
              'Tap "Report a Cat", add a photo, set the location on the map, '
                  'choose a condition, and submit.',
              'Your reports appear under "My Reports".',
            ],
          ),
          _Section(
            title: 'Donating',
            steps: [
              'Open a campaign and tap "Donate Now".',
              'You are redirected to Stripe\'s secure checkout. In test mode '
                  'use card 4242 4242 4242 4242, any future expiry, any CVC.',
              'Your receipt and history appear under "My Donations".',
            ],
          ),
          _Section(
            title: 'Volunteering',
            steps: [
              'Open "Volunteer", pick an activity, and tap "Sign Up".',
              'Cancel anytime before the activity from the same screen or '
                  '"My Activities".',
            ],
          ),
          _Section(
            title: 'FAQ',
            steps: [
              'Is my donation real money? In test mode, no — no money moves.',
              'Who can create campaigns/activities? Admins and partner NGOs.',
              'How is my data used? Donations and reports are tied to your '
                  'account; the public stats page shows only anonymous totals.',
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> steps;
  const _Section({required this.title, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.titleSm.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.stackSm),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                        child: Text(s,
                            style: AppText.bodyBase
                                .copyWith(color: AppColors.secondary))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
