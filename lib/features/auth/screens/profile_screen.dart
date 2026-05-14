import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Profile screen — UC-04. Matches `mockup-screens/user_profile_screen.png`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _auth.loadProfile();
  }

  Future<void> _signOut() async {
    await _auth.logoutUser();
    // Router redirect will move us to /login.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return _ProfileMissing(onSignOut: _signOut);
          }
          return _ProfileBody(profile: profile, onSignOut: _signOut);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onSignOut;
  const _ProfileBody({required this.profile, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MaroonHeader(profile: profile),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats (placeholder counts until NAD-14 wires real data)
                _StatsRow(profile: profile),
                const SizedBox(height: AppSpacing.stackLg),

                _MenuTile(
                  icon: Icons.history,
                  label: 'My Reports',
                  onTap: () => context.push(AppRoutes.myReports),
                ),
                _MenuTile(
                  icon: Icons.handshake_outlined,
                  label: 'Volunteer History',
                  subtitle: 'Sprint 3 — coming soon',
                  enabled: false,
                ),
                _MenuTile(
                  icon: Icons.favorite_border,
                  label: 'Favorites',
                  subtitle: 'Sprint 3 — coming soon',
                  enabled: false,
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Account Settings',
                  subtitle: 'Sprint 4 — coming soon',
                  enabled: false,
                ),

                const SizedBox(height: AppSpacing.stackXl),

                OutlinedButton.icon(
                  onPressed: onSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaroonHeader extends StatelessWidget {
  final UserProfile profile;
  const _MaroonHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackXl,
        AppSpacing.containerPadding,
        AppSpacing.stackXl + AppSpacing.stackMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _GlassIconButton(
                  icon: Icons.chevron_left,
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.home),
                  tooltip: 'Back',
                ),
                const SizedBox(width: AppSpacing.stackSm),
                Expanded(
                  child: Text(
                    'My Profile',
                    style: AppText.bodyBase.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _GlassIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () {
                    // Sprint 4 (NAD-65) — Account Settings screen
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.onPrimary.withValues(alpha: 0.18),
                  child: Text(
                    _initials(profile.fullName),
                    style: AppText.headlineMd.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: AppText.headlineMd.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        style: AppText.bodySm.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.stackMd,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.18),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          profile.role.toUpperCase(),
                          style: AppText.labelCaps.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _StatsRow extends StatelessWidget {
  final UserProfile profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.stackMd,
          horizontal: AppSpacing.stackSm,
        ),
        child: Row(
          children: const [
            Expanded(
              child: _StatTile(
                icon: Icons.history,
                value: '—',
                label: 'Reports',
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _StatTile(
                icon: Icons.emoji_events_outlined,
                value: '—',
                label: 'Points',
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _StatTile(
                icon: Icons.favorite_border,
                value: '—',
                label: 'Saved',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppText.titleSm.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.labelCaps.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.outlineVariant,
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Card(
        child: InkWell(
          borderRadius: AppRadius.cardRadius,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackMd,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: enabled ? AppColors.primary : AppColors.outline,
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.bodyBase.copyWith(
                          color: enabled
                              ? AppColors.onSurface
                              : AppColors.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: AppText.bodySm
                                .copyWith(color: AppColors.outline),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMissing extends StatelessWidget {
  final VoidCallback onSignOut;
  const _ProfileMissing({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Profile data not found.',
              style: AppText.titleSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Sign out and try again, or contact support.',
              style: AppText.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Re-export for routing — not currently used externally but ensures the
/// file is reachable via go_router builders.
class ProfileScreenRoute {
  static String get path => AppRoutes.profile;
}

/// Small circular icon button with a translucent on-primary background
/// so it stays legible on the maroon header without competing with the
/// content. Reused for back + settings affordances.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onPrimary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: AppColors.onPrimary),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
