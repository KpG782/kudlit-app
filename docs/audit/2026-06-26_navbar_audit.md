# Kudlit — Navbar UX audit + 3 modern options

**Interactive comparison:** open `docs/navbar-prototypes/index.html` in a browser and tap the tabs (every option switches pages in **one tap**).

## The problem (confirmed in code)

`FloatingTabNav` (`lib/features/home/presentation/widgets/floating_tab_nav.dart:13-37`) is a **64 px pill in the bottom-right corner** that, when collapsed, shows **only the active tab's icon** (`_CollapsedPill`, `:193-215`). To switch tabs the user must:

1. **Tap to expand** the pill (`_toggle`, `:32`), then
2. **Tap a destination**, which selects + collapses (`_select`, `:34-37`).

→ **2 taps for every page change**, and the other 3 destinations are **invisible** until expanded. Compounding issues: corner placement (awkward one-handed on large phones, obscures bottom-right content) and labels wrapped in `FittedBox(scaleDown)` (`:307`) that can shrink very small.

This is the friction you reported. The fix in all three options: destinations always visible, **1 tap** to switch.

## The 3 modern options

| # | Option | Keeps brand? | Notes |
|---|---|---|---|
| **1** | **Material 3 `NavigationBar`** (full-width, labels, active pill indicator) | colors only | **Recommended.** Standard, expected, most accessible, full-width thumb reach. |
| **2** | **Floating glass pill, always expanded** (centered, blurred, sliding highlight) | ✅ strong | Keeps Kudlit's signature floating/glass look but shows all 4 + 1 tap. Best "brand + usability" balance. |
| **3** | **Expanding active item** (icons-only inactive; active reveals a colored label pill) | ✅ playful | Trendy micro-interaction, compact; inactive labels hidden (icon literacy) and must respect reduced-motion. |

## Recommendation

- **Ship Option 1 (`NavigationBar`)** for the cleanest, most accessible result, **or Option 2** if keeping the floating-glass identity matters to you. Both are a single tap and remove the hidden-state problem.
- **Either way, also enable swipe between tabs:** the shell already uses a `PageView` (`home_screen.dart:177`) with `NeverScrollableScrollPhysics` — switch to `BouncingScrollPhysics`/`ClampingScrollPhysics` so users can also swipe, and keep the bottom bar in sync.

## How to apply in Flutter (Option 1, sketch)

Replace the `Positioned(FloatingTabNav(...))` in `home_screen.dart` with a `Scaffold.bottomNavigationBar`:

```dart
bottomNavigationBar: NavigationBar(
  selectedIndex: _activeTab.index,
  onDestinationSelected: (i) => _onTabSelected(AppTab.values[i]),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
    NavigationDestination(icon: Icon(Icons.g_translate), label: 'Translate'),
    NavigationDestination(icon: Icon(Icons.auto_stories_rounded), label: 'Learn'),
    NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Butty'),
  ],
),
```

Then:
- delete the `Positioned` floating-nav overlay + the `kFloatingNavClearance` bottom padding screens reserve for it,
- allow `PageView` swipe (change the physics) and call `_syncScannerInference` on swipe just like on tap,
- theme `NavigationBar` via `KudlitTheme` (indicator = `KudlitColors.blue500`) so it stays on-brand,
- gate any indicator animation on reduced-motion (per the a11y follow-up).

Option 2 keeps your existing `FloatingTabNav` widget — just remove the collapsed/expanded state machine (`_expanded`, `_toggle`, `_CollapsedPill`) and always render `_ExpandedItems`, centered, with a sliding active highlight.

> Note: I did not change the live navbar — this is an audit + prototypes for you to choose from. Say which option you want and I'll implement it (verified with `flutter analyze`).
