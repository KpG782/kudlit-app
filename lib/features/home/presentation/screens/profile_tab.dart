import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_summary.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';

/// Profile tab — shows user info when authenticated, or a sign-in prompt for guests.
class ProfileTab extends StatelessWidget {
  const ProfileTab({this.user, super.key});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: user == null
            ? _GuestProfile(onSignIn: () => context.go(AppConstants.routeLogin))
            : _UserProfile(user: user!),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxHeight < 520 ||
            constraints.maxWidth > constraints.maxHeight;
        final double mascotSize = compact ? 78 : 112;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            compact ? 18 : 28,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      'assets/brand/ButtyWave.webp',
                      width: mascotSize,
                      height: mascotSize,
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Text(
                      'Kumusta, Bisita!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create an account to save your progress and access your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: cs.onSurface.withAlpha(180),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 26),
                    _PrimaryProfileAction(
                      label: 'Sign In or Create Account',
                      onTap: onSignIn,
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryProfileAction extends StatelessWidget {
  const _PrimaryProfileAction({
    required this.label,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: cs.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserProfile extends ConsumerWidget {
  const _UserProfile({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<Option<ProfileSummary>> summaryAsync = ref.watch(
      profileSummaryNotifierProvider,
    );
    final ProfileSummary? summary = summaryAsync.value?.toNullable();
    final bool summaryFailed =
        summaryAsync.hasError && !summaryAsync.hasValue;

    final String displayName =
        summary?.displayName ?? user.email.split('@').first;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxHeight < 560 ||
            constraints.maxWidth > constraints.maxHeight;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            compact ? 16 : 24,
            18,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (summaryFailed) ...<Widget>[
                    _ProfileSyncErrorBanner(
                      onRetry: () =>
                          ref.invalidate(profileSummaryNotifierProvider),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                  ],
                  _ProfileRow(
                    cs: cs,
                    displayName: displayName,
                    email: user.email,
                    avatarUrl: summary?.avatarUrl,
                    onTap: () => context.push(AppConstants.routeSettings),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  _HistoryShortcut(
                    cs: cs,
                    icon: Icons.document_scanner_outlined,
                    title: 'Scanner History',
                    subtitle: 'Review saved scans and readings',
                    onTap: () => context.push(AppConstants.routeScanHistory),
                  ),
                  const SizedBox(height: 10),
                  _HistoryShortcut(
                    cs: cs,
                    icon: Icons.translate_rounded,
                    title: 'Translation History',
                    subtitle: 'Find past translations and bookmarks',
                    onTap: () =>
                        context.push(AppConstants.routeTranslationHistory),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSyncErrorBanner extends StatelessWidget {
  const _ProfileSyncErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: cs.errorContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withAlpha(70)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Couldn\'t load your profile details.',
              style: TextStyle(fontSize: 12.5, color: cs.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({required this.avatarUrl, required this.email});

  final String? avatarUrl;
  final String email;

  @override
  Widget build(BuildContext context) {
    final String? safeAvatarUrl =
        avatarUrl != null && avatarUrl!.trim().isNotEmpty
        ? avatarUrl!.trim()
        : null;

    if (safeAvatarUrl != null) {
      return Image.network(
        safeAvatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return _ProfileInitials(email: email);
        },
      );
    }

    return Image.asset(
      'assets/brand/user.profile/butty.thumbsup.webp',
      fit: BoxFit.cover,
    );
  }
}

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.primaryContainer,
      child: Center(
        child: Text(
          email.isNotEmpty ? email[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.cs,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.onTap,
  });

  final ColorScheme cs;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: _ProfileAvatarImage(
                    avatarUrl: avatarUrl,
                    email: email,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        color: cs.onSurface.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: cs.onSurface.withAlpha(90),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryShortcut extends StatelessWidget {
  const _HistoryShortcut({
    required this.cs,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        color: cs.onSurface.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withAlpha(90),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
