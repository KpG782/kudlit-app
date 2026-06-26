---
name: ui-ux-promax
description: Advanced UI/UX for producing visually exceptional, modern, highly polished, accessible interfaces with consistent spacing and smooth interactive feedback. Use when designing or refining any screen, widget, theme, state, or interaction in Kudlit.
user-invocable: true
---

# UI/UX Promax

Expert guidance for top-tier ("Promax") UI/UX in the Kudlit Flutter app.

## Core philosophy
1. **Modern aesthetics** — interfaces must work *and* look exceptional; prioritize visual impact.
2. **Consistent spacing** — every margin/padding is a multiple of a 4px base grid (4/8/12/16/24…).
3. **Interactive feedback** — every touchpoint has immediate feedback: pressed/hover states, haptics, loading, success/error.
4. **Platform-appropriate** — feel native: Material 3 on Android, Cupertino/HIG on iOS, or a strong custom brand (Kudlit DS).

## Procedural workflow
1. **Analyze the brand** — Kudlit = blue-tinted paper surfaces, dark denim ink, card-first layout, Butty mascot, Baybayin display font. Colors/type come from `lib/core/design_system/kudlit_colors.dart` + `kudlit_theme.dart`.
2. **Decompose** — break UI into small reusable widgets; `build()` < 40 lines; extract any subtree nesting 3+ levels into its own file (no `_buildX()` helpers).
3. **Accessibility first** — WCAG AA contrast (4.5:1 text), `Semantics` labels on icon buttons + meaningful images, respect `MediaQuery.disableAnimations` + the reduced-motion pref, support Dynamic Type via `textTheme` (avoid `FittedBox(scaleDown)` for content).
4. **Every state designed** — never a blank screen. Provide loading (skeletons > spinners), empty (use Butty + a clear CTA), error (friendly copy + retry), and success states.

## Execution checklist (must pass)
- [ ] Colors mapped to the Design System — **no hardcoded hex** in widgets.
- [ ] Spacing is consistent and on the 4px grid.
- [ ] Touch targets ≥ 48dp (Android) / 44pt (iOS).
- [ ] Animations are smooth (60fps), tied to a controller, and gated on reduced-motion.
- [ ] Semantic labels present for screen readers; focus order sane.
- [ ] Loading/empty/error/success states all handled and *designed*.
- [ ] Haptic feedback on key interactions (tab switch, toggle, submit, shutter).
- [ ] Dark mode verified.

## Kudlit-specific
- Reuse shared shells/tokens from `lib/core/design_system/` before introducing anything new.
- Use `assets/brand/` art and the Baybayin font from `assets/fonts/`.
- Keep widgets display-only; logic lives in Riverpod notifiers/use cases (widgets just read state + call methods).
