import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_preferences.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_summary.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';

import 'profile_management_card.dart';
import 'profile_management_item.dart';
import 'settings_section_label.dart';

class ProfileManagementSection extends ConsumerStatefulWidget {
  const ProfileManagementSection({
    super.key,
    required this.isAuthenticated,
    required this.onActionTap,
  });

  final bool isAuthenticated;
  final void Function(String message) onActionTap;

  @override
  ConsumerState<ProfileManagementSection> createState() =>
      _ProfileManagementSectionState();
}

class _ProfileManagementSectionState
    extends ConsumerState<ProfileManagementSection> {
  final Set<String> _loadingActions = <String>{};
  late final TextEditingController _displayNameController;
  late final FocusNode _displayNameFocusNode;
  bool _isEditingDisplayName = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _displayNameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayNameFocusNode.dispose();
    super.dispose();
  }

  List<ProfileManagementItem> _getItems(ProfileSummary? summary) {
    final String? displayName = summary?.displayName;

    String learningDesc =
        'Track lesson completion, milestones, and last activity.';
    if (summary != null && summary.completedLessons > 0) {
      learningDesc += ' ${summary.completedLessons} lessons completed.';
    }

    String scanDesc = 'Review prior scan results and retry translations.';
    if (summary != null && summary.scanHistoryItems > 0) {
      scanDesc += ' ${summary.scanHistoryItems} scans.';
    }

    String translationDesc = 'Save and revisit translated phrases quickly.';
    if (summary != null) {
      final int t = summary.translationHistoryItems;
      final int b = summary.bookmarkedTranslations;
      if (t > 0 || b > 0) {
        translationDesc += ' $t translations, $b bookmarked.';
      }
    }

    return <ProfileManagementItem>[
      ProfileManagementItem(
        id: 'edit-profile-identity',
        icon: Icons.badge_outlined,
        title: 'Edit profile identity',
        description: 'Update display name and avatar profile appearance.',
        primaryActionId: 'edit-name',
        primaryActionLabel: displayName != null && displayName.isNotEmpty
            ? 'Edit name ($displayName)'
            : 'Edit name',
        primaryActionMessage: 'edit-name',
        secondaryActionId: 'upload-avatar',
        secondaryActionLabel: 'Upload avatar',
        secondaryActionMessage: 'upload-avatar',
      ),
      ProfileManagementItem(
        id: 'learning-progress-dashboard',
        icon: Icons.menu_book_rounded,
        title: 'Learning progress dashboard',
        description: learningDesc,
        primaryActionId: 'view-progress',
        primaryActionLabel: 'View progress',
        primaryActionMessage: 'Progress dashboard will be available soon.',
        secondaryActionId: 'continue-lesson',
        secondaryActionLabel: 'Continue lesson',
        secondaryActionMessage: 'Lesson resume flow is available soon.',
      ),
      ProfileManagementItem(
        id: 'scanner-history',
        icon: Icons.document_scanner_outlined,
        title: 'Scanner history',
        description: scanDesc,
        primaryActionId: 'open-scan-history',
        primaryActionLabel: 'Open history',
        primaryActionMessage: 'Scanner history will be available soon.',
        secondaryActionId: 'clear-scan-history',
        secondaryActionLabel: 'Clear history',
        secondaryActionMessage: 'History cleanup flow is available soon.',
      ),
      ProfileManagementItem(
        id: 'translator-history-bookmarks',
        icon: Icons.translate_rounded,
        title: 'Translator history and bookmarks',
        description: translationDesc,
        primaryActionId: 'view-saved-translations',
        primaryActionLabel: 'View saved',
        primaryActionMessage: 'Saved translations will be available soon.',
        secondaryActionId: 'add-bookmark',
        secondaryActionLabel: 'Add bookmark',
        secondaryActionMessage: 'Bookmark flow is available soon.',
      ),
      const ProfileManagementItem(
        id: 'butty-data',
        icon: Icons.psychology_outlined,
        title: 'Butty chat & memory',
        description:
            'Manage your chat history (synced to Supabase) and the long-term '
            'facts Butty has learned about you. Memory survives "Start fresh" '
            'and reinstalls.',
        primaryActionId: 'open-butty-data',
        primaryActionLabel: 'Manage data',
        primaryActionMessage: 'open-butty-data',
      ),
      const ProfileManagementItem(
        id: 'accessibility-options',
        icon: Icons.accessibility_new_rounded,
        title: 'Accessibility options',
        description: 'Configure text scale, contrast, and motion comfort.',
        primaryActionId: 'open-accessibility-setup',
        primaryActionLabel: 'Accessibility setup',
        primaryActionMessage: 'open-accessibility-setup',
      ),
      const ProfileManagementItem(
        id: 'privacy-controls',
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy controls',
        description: 'Manage analytics consent and data sharing preferences.',
        primaryActionId: 'open-privacy-settings',
        primaryActionLabel: 'Privacy settings',
        primaryActionMessage: 'open-privacy-settings',
      ),
      const ProfileManagementItem(
        id: 'account-deletion-flow',
        icon: Icons.delete_forever_outlined,
        title: 'Account deletion flow',
        description: 'Run a safe and confirmed account deletion process.',
        primaryActionId: 'delete-account',
        primaryActionLabel: 'Delete account',
        primaryActionMessage: 'delete-account',
        secondaryActionId: 'account-deletion-learn-more',
        secondaryActionLabel: 'Learn more',
        secondaryActionMessage:
            'Review account data retention and deletion policies.',
      ),
    ];
  }

  Future<void> _handleAction(String actionId, String message) async {
    if (message == 'edit-name') {
      _startInlineNameEdit();
      return;
    }
    if (message == 'upload-avatar') {
      await _uploadAvatar();
      return;
    }
    if (message == 'open-accessibility-setup') {
      await _showAccessibilityDialog();
      return;
    }
    if (message == 'open-privacy-settings') {
      await _showPrivacyDialog();
      return;
    }
    if (message == 'open-butty-data') {
      context.push(AppConstants.routeButtyData);
      return;
    }
    if (message == 'delete-account') {
      await _confirmAndDeleteAccount();
      return;
    }

    if (_loadingActions.contains(actionId)) return;
    setState(() => _loadingActions.add(actionId));
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    widget.onActionTap(message);
    setState(() => _loadingActions.remove(actionId));
  }

  Future<void> _confirmAndDeleteAccount() async {
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

    if (!confirmed || !mounted) return;
    setState(() => _loadingActions.add('delete-account'));
    final result = await ref
        .read(authNotifierProvider.notifier)
        .deleteAccount();
    if (!mounted) return;
    setState(() => _loadingActions.remove('delete-account'));
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete your account. Please try again.'),
        ),
      ),
      (_) => context.go(AppConstants.routeLogin),
    );
  }

  void _startInlineNameEdit() {
    final summaryOpt = ref.read(profileSummaryNotifierProvider).value;
    final String initialName = summaryOpt?.toNullable()?.displayName ?? '';
    _displayNameController.text = initialName;
    _displayNameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _displayNameController.text.length,
    );
    setState(() => _isEditingDisplayName = true);
    _displayNameFocusNode.requestFocus();
  }

  void _cancelInlineNameEdit() {
    setState(() => _isEditingDisplayName = false);
  }

  Future<void> _saveInlineNameEdit() async {
    final summaryOpt = ref.read(profileSummaryNotifierProvider).value;
    final String initialName = summaryOpt?.toNullable()?.displayName ?? '';
    final String newName = _displayNameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.')),
      );
      return;
    }

    if (newName == initialName.trim()) {
      _cancelInlineNameEdit();
      return;
    }

    setState(() => _loadingActions.add('edit-name'));
    await ref
        .read(profileSummaryNotifierProvider.notifier)
        .updateDisplayName(newName);

    if (!mounted) return;
    setState(() => _loadingActions.remove('edit-name'));

    final currentState = ref.read(profileSummaryNotifierProvider);
    if (currentState.hasError) {
      _showErrorSnackBar('Failed to update name', currentState.error);
    } else {
      setState(() => _isEditingDisplayName = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Display name updated.')));
    }
  }

  Future<void> _uploadAvatar() async {
    if (_loadingActions.contains('upload-avatar')) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 88,
      );
      if (image == null || !mounted) return;

      setState(() => _loadingActions.add('upload-avatar'));
      final Uint8List bytes = await image.readAsBytes();
      await ref
          .read(profileSummaryNotifierProvider.notifier)
          .updateAvatar(
            bytes: bytes,
            fileName: image.name,
            mimeType: image.mimeType,
          );

      if (!mounted) return;
      final currentState = ref.read(profileSummaryNotifierProvider);
      if (currentState.hasError) {
        _showErrorSnackBar('Failed to upload avatar', currentState.error);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar updated.')));
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to upload avatar', e);
    } finally {
      if (mounted && _loadingActions.contains('upload-avatar')) {
        setState(() => _loadingActions.remove('upload-avatar'));
      }
    }
  }

  Future<void> _showAccessibilityDialog() async {
    final prefsOpt = ref.read(profilePreferencesNotifierProvider).value;
    final ProfilePreferences current =
        prefsOpt?.toNullable() ??
        const ProfilePreferences(
          highContrast: false,
          reducedMotion: false,
          dataSharingConsent: false,
        );

    final ProfilePreferences? newPrefs = await showDialog<ProfilePreferences>(
      context: context,
      builder: (BuildContext ctx) {
        bool highContrast = current.highContrast;
        bool reducedMotion = current.reducedMotion;

        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setInner) {
            return AlertDialog(
              title: const Text('Accessibility Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('High Contrast'),
                    value: highContrast,
                    onChanged: (bool val) => setInner(() => highContrast = val),
                  ),
                  SwitchListTile(
                    title: const Text('Reduced Motion'),
                    value: reducedMotion,
                    onChanged: (bool val) =>
                        setInner(() => reducedMotion = val),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(
                    ProfilePreferences(
                      highContrast: highContrast,
                      reducedMotion: reducedMotion,
                      dataSharingConsent: current.dataSharingConsent,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPrefs == null || !mounted) return;

    setState(() => _loadingActions.add('open-accessibility-setup'));
    await ref
        .read(profilePreferencesNotifierProvider.notifier)
        .updatePreferences(newPrefs);

    if (!mounted) return;
    setState(() => _loadingActions.remove('open-accessibility-setup'));

    final currentState = ref.read(profilePreferencesNotifierProvider);
    if (currentState.hasError) {
      _showErrorSnackBar('Failed to update preferences', currentState.error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accessibility settings updated.')),
      );
    }
  }

  Future<void> _showPrivacyDialog() async {
    final prefsOpt = ref.read(profilePreferencesNotifierProvider).value;
    final ProfilePreferences current =
        prefsOpt?.toNullable() ??
        const ProfilePreferences(
          highContrast: false,
          reducedMotion: false,
          dataSharingConsent: false,
        );

    final ProfilePreferences? newPrefs = await showDialog<ProfilePreferences>(
      context: context,
      builder: (BuildContext ctx) {
        bool consent = current.dataSharingConsent;

        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setInner) {
            return AlertDialog(
              title: const Text('Privacy Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Share Analytics Data'),
                    subtitle: const Text(
                      'Help us improve Kudlit by sharing anonymous usage data.',
                    ),
                    value: consent,
                    onChanged: (bool val) => setInner(() => consent = val),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(
                    ProfilePreferences(
                      highContrast: current.highContrast,
                      reducedMotion: current.reducedMotion,
                      dataSharingConsent: consent,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPrefs == null || !mounted) return;

    setState(() => _loadingActions.add('open-privacy-settings'));
    await ref
        .read(profilePreferencesNotifierProvider.notifier)
        .updatePreferences(newPrefs);

    if (!mounted) return;
    setState(() => _loadingActions.remove('open-privacy-settings'));

    final currentState = ref.read(profilePreferencesNotifierProvider);
    if (currentState.hasError) {
      _showErrorSnackBar(
        'Failed to update privacy settings',
        currentState.error,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings updated.')),
      );
    }
  }

  void _showErrorSnackBar(String prefix, Object? error) {
    String message = error.toString();
    if (error is Failure) {
      message = error.when(
        network: (String msg) => msg,
        unknown: (String msg) => msg,
        invalidCredentials: () => 'Invalid credentials',
        userNotFound: () => 'User not found',
        emailAlreadyInUse: () => 'Email already in use',
        weakPassword: () => 'Weak password',
        tooManyRequests: () => 'Too many requests',
        sessionExpired: () => 'Session expired',
        passwordResetEmailSent: () => 'Email sent',
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$prefix: $message')));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAuthenticated) return const SizedBox.shrink();

    final ProfileSummary? summary = ref
        .watch(profileSummaryNotifierProvider)
        .value
        ?.toNullable();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsSectionLabel(text: 'Profile management'),
        if (_isEditingDisplayName) ...<Widget>[
          _InlineNameEditor(
            controller: _displayNameController,
            focusNode: _displayNameFocusNode,
            isSaving: _loadingActions.contains('edit-name'),
            onCancel: _cancelInlineNameEdit,
            onSave: _saveInlineNameEdit,
          ),
          const SizedBox(height: 12),
        ],
        ProfileManagementCard(
          items: _getItems(summary),
          loadingActions: _loadingActions,
          onAction: _handleAction,
        ),
      ],
    );
  }
}

class _InlineNameEditor extends StatelessWidget {
  const _InlineNameEditor({
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isSaving,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              onSubmitted: (_) => isSaving ? null : onSave(),
              decoration: InputDecoration(
                counterText: '',
                labelText: 'Display name',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Save display name',
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : const Icon(Icons.check_rounded),
          ),
          IconButton(
            tooltip: 'Cancel display name edit',
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            onPressed: isSaving ? null : onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
