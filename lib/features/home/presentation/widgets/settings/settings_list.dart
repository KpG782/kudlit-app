import 'package:flutter/material.dart';

import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/about_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/account_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/activity_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/admin_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/ai_models_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/danger_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/personalization_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/preferences_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/profile_compact_card.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/sign_out_tile.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({
    super.key,
    required this.user,
    required this.isAuthLoading,
    required this.bottomPadding,
    required this.onActionTap,
    required this.onSignOutTap,
    required this.onDeleteAccountTap,
  });

  final AuthUser? user;
  final bool isAuthLoading;
  final double bottomPadding;
  final void Function(String message) onActionTap;
  final Future<void> Function() onSignOutTap;
  final Future<void> Function() onDeleteAccountTap;

  @override
  Widget build(BuildContext context) {
    final AuthUser? u = user;
    final double horizontalInset = MediaQuery.sizeOf(context).width < 380
        ? 12
        : 16;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding + 28),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: u != null
                      ? ProfileCompactCard(user: u)
                      : AccountSection(user: null),
                ),
                const SizedBox(height: 18),
                if (u != null) ...<Widget>[
                  ActivitySection(onActionTap: onActionTap),
                  const SizedBox(height: 18),
                ],
                const PreferencesSection(),
                const SizedBox(height: 18),
                const AiModelsSection(),
                const SizedBox(height: 18),
                if (u != null) ...<Widget>[
                  const AdminSection(),
                  const SizedBox(height: 18),
                  const PersonalizationSection(),
                  const SizedBox(height: 18),
                ],
                const AboutSection(),
                if (u != null || isAuthLoading) ...<Widget>[
                  const SizedBox(height: 18),
                  SignOutTile(isLoading: isAuthLoading, onTap: onSignOutTap),
                ],
                if (u != null) ...<Widget>[
                  const SizedBox(height: 14),
                  DangerSection(onDeleteAccountTap: onDeleteAccountTap),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
