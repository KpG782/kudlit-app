import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom breathing room that scrollable tab screens add so their last item is
/// not flush against the docked nav bar. (The bar now docks in its own row, so
/// screens no longer need to reserve its full height.)
const double kFloatingNavClearance = 16.0;

/// The four primary app tabs.
enum AppTab { scan, translate, learn, butty }

const Map<AppTab, ({IconData icon, String label})> _kTabs =
    <AppTab, ({IconData icon, String label})>{
      AppTab.scan: (icon: Icons.qr_code_scanner, label: 'Scan'),
      AppTab.translate: (icon: Icons.g_translate, label: 'Translate'),
      AppTab.learn: (icon: Icons.auto_stories_rounded, label: 'Learn'),
      AppTab.butty: (icon: Icons.chat_bubble_outline_rounded, label: 'Butty'),
    };

/// Always-expanded, blurred-glass floating pill docked at the bottom. All four
/// destinations are always visible and switch in a single tap.
class FloatingTabNav extends StatelessWidget {
  const FloatingTabNav({
    required this.activeTab,
    required this.onTabSelected,
    super.key,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _NavPill(activeTab: activeTab, onTabSelected: onTabSelected),
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.activeTab, required this.onTabSelected});

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 30,
            spreadRadius: -6,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: <Widget>[
                for (final AppTab tab in AppTab.values)
                  Expanded(
                    child: _NavItem(
                      icon: _kTabs[tab]!.icon,
                      label: _kTabs[tab]!.label,
                      active: tab == activeTab,
                      onTap: () => onTabSelected(tab),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = active ? cs.onPrimary : cs.onSurface.withAlpha(210);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      button: true,
      selected: active,
      label: '$label tab',
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 52),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? cs.primary : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: fg,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
