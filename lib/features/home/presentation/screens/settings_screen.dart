import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/settings_header.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/settings_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AuthUser?> authState = ref.watch(authNotifierProvider);
    final AuthUser? user = authState.value;
    final double bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const SettingsHeader(),
            Expanded(
              child: SettingsList(
                user: user,
                isAuthLoading: authState.isLoading,
                bottomPadding: bottom,
                onActionTap: (String message) =>
                    _showActionSnackBar(context, message),
                onSignOutTap: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppConstants.routeLogin);
                  }
                },
                onDeleteAccountTap: () => _confirmAndDeleteAccount(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showActionSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
              'This permanently deletes your account and all your data — '
              'profile, history, chats, and saved progress. This cannot be '
              'undone.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!confirmed || !context.mounted) return;

  final Either<Failure, Unit> result = await ref
      .read(authNotifierProvider.notifier)
      .deleteAccount();
  if (!context.mounted) return;
  result.fold(
    (_) => _showActionSnackBar(
      context,
      'Could not delete your account. Please try again.',
    ),
    (_) => context.go(AppConstants.routeLogin),
  );
}
