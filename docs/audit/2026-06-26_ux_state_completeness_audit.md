# Kudlit — UX-State Completeness Audit (main feature screens)

**Date:** 2026-06-26 · **Method:** 4 parallel code-readers over current source, every claim cited `file:line`. Produced with `/superpowers` + `/ui-ux-promax`.

Covers state handling (**empty / loading / error / success**) for every main screen: Scan, Translate, Learn (+ lesson stage, quiz, gallery), Butty chat, Profile, Settings, and the history screens. Several items were **fixed in this same pass** (§3).

---

## 1. State matrix (current)

Legend: ✅ handled · ⚠️ partial · ❌ missing · 🩹 fixed this pass

| Screen | Empty | Loading | Error | Success | Key cite |
|---|---|---|---|---|---|
| **Scan tab** | ⚠️ no live "no glyph" hint | ✅ full-screen spinner | ✅ friendly notices | ✅ result + banner | `scan_tab.dart:352,431,445,1580` |
| **Scan history** | ✅ "No scans yet" | ✅ | ✅ friendly + retry | ✅ | `scan_history_screen.dart:87-214` |
| **ScannerCamera (native)** | n/a | ✅ ModelNotReady | ✅ friendly + retry/setup | ✅ YOLOView | `scanner_camera.dart:344-369` |
| **ScannerCamera (web)** | ✅ no-webcam | ✅ | ✅ friendly status cards | ✅ | `scanner_camera.dart:437-491,612-653` |
| **Translate (text)** | ✅ EmptyOutput | ⚠️ button-only, no output typing | 🩹 was raw → now friendly | ✅ FilledOutput + Listen | `translate_text_mode_panel.dart`; `translate_text_controller.dart:391` |
| **Translate (sketchpad)** | ✅ guards | ✅ "Butty is thinking…" | 🩹 was raw → now friendly | ✅ feedback bubble | `translate_sketchpad_controller.dart:199` |
| **Translate model banner** | ✅ idle | ✅ progress bar | 🩹 was raw `$e` → now friendly | ✅ ready/setup | `translate_model_status_banner.dart:23` |
| **Butty chat** | ✅ seeded greeting | ✅ typing bubble + cursor | ✅ friendly bubble | ✅ streaming | `butty_chat_controller.dart:177-191`, `chat_message_list.dart:28` |
| **Learn home/tab** | n/a (hardcoded) | ❌ collapses to 0 | ❌ collapses to 0 | ✅ | `learn_home_body.dart:122-126` |
| **Lesson stage** | ✅ null→spinner | ✅ | 🩹 was raw `Exception:` → now friendly + retry | ✅ | `lesson_stage_screen.dart:113,277` |
| **Quiz** | ✅ friendly | ✅ | ✅ friendly (no retry) | ✅ | `quiz_screen.dart:51-54,100-130` |
| **Character gallery** | ✅ context-aware | ✅ | ✅ friendly (no retry) | ✅ | `character_gallery_screen.dart:49-85` |
| **Learning progress** | ⚠️ implicit | ❌ collapses to 0 | ❌ collapses to 0 (looks wiped) | ✅ | `learning_progress_screen.dart:35-37` |
| **Profile tab** | ✅ guest CTA | ❌ none | ❌ silent (fold Left→None) | ✅ | `profile_tab.dart:148`; `profile_management_provider.dart:79,180` |
| **Settings** | ✅ guest | ⚠️ only sign-out | ⚠️ snackbars only | ✅ | `settings_list.dart:40-85` |
| **Translation history** | ✅ | ✅ | ✅ friendly + retry | ✅ | `translation_history_screen.dart:87-209` |
| **Butty data** | ✅ per-section | ✅ skeletons | 🩹 was raw → now friendly + retry | ✅ | `butty_data_screen.dart:247,625,1097` |

**Gold-standard screens** (use as the pattern): Translation history, Character gallery, Quiz, Butty chat, the scanner notice/model flows.

---

## 2. Scanner / Translate / Butty specifics

- **Scanner:** web handles permission-denied + no-webcam (`scanner_camera.dart:444-491`); native model-not-loaded / URL-missing / device-unsupported all friendly (`model_not_ready_screen.dart`, `model_not_supported_screen.dart`). **Gaps:** no **native** camera-permission-denied UI (renders `YOLOView` directly, `scanner_camera.dart:357-369`); no native no-camera/init-failure state; `ModelNotSupportedScreen` is a dead-end (no Gallery fallback); model dropdown error has no retry (`yolo_model_dropdown.dart:40`).
- **Translate:** empty-input → prompt ✅; AI failure now friendly 🩹; **gaps:** no output typing indicator in text mode while awaiting first token; an empty/blocked AI response leaves a **silent blank** (no card ever appears) — `translate_text_controller.dart:375`.
- **Butty:** typing indicator ✅, friendly error bubble ✅, seeded greeting ✅. **Gaps:** an empty-but-successful (zero-token) stream is filtered out → no bubble at all (`chat_message_list.dart:24`); failed message has no tap-to-retry (text says "Try again?" but isn't actionable).

---

## 3. ✅ Fixed in this pass (committed)

1. **Translate text** raw leak `'Could not complete AI request: $error'` → friendly (`translate_text_controller.dart:391`).
2. **Sketchpad** raw leak `'...sketch feedback: $error'` → friendly (`translate_sketchpad_controller.dart:199`).
3. **Model status banner** raw `'Offline model error: $e'` → friendly (`translate_model_status_banner.dart:23`).
4. **Lesson stage** raw `Exception:` dump → friendly copy **+ a "Try again"** that reloads the lesson (`lesson_stage_screen.dart:113`, `_ErrorView`).
5. **Butty data** raw `e.toString()` (chat + memory) → friendly **+ "Try again"** that invalidates the provider (`butty_data_screen.dart:247,625,1097`).
6. **Sign-out confirmation** dialog added (was a one-tap destructive action) (`settings_screen.dart`).

(Earlier passes already fixed scan + translation history error states and wired account-deletion confirm dialogs.)

---

## 4. Long-term plan (prioritized) — what's good to update next

### P1 — "failed load looks like a wiped account" (highest user-trust risk)
- 🩹 **DONE — `learning_progress_screen.dart:35`**: added loading + error/retry guards (`_ProgressScaffold` / `_ProgressErrorView`) so a failed fetch no longer renders as "0 lessons, everything locked". Empty map still = genuine new user.
- 🩹 **DONE — `learn_home_body.dart:122`**: the Learn tab keeps its static lessons but now shows a non-blocking "Couldn't sync your progress — Retry" banner on `hasError`. Streak already degrades gracefully via the local-persistence cache.
- ⏸️ **DEFERRED (domain-layer prerequisite) — Profile.** `profile_management_provider.dart:79` folds `Left → None`, but the `GetProfileSummary` use case returns `Left` for **both** a real fetch error **and** a brand-new user with no profile row. Surfacing `Left` as an error would wrongly show an error banner to legitimate new users. **Fix the domain layer first:** have the repository/use case return `Right(empty summary)` for "no row yet" and reserve `Left` for real failures; *then* `profile_tab.dart:148` can show an error+retry on `hasError` safely. (No `requireValue` consumers exist, so the provider flip is otherwise safe.) Current behavior degrades to the email-prefix name — not a data-loss view, so this is lower severity than the two above.

### P2 — scanner robustness
- **Native camera-permission-denied** panel (check `permission_handler` before `YOLOView`; "Open settings" CTA).
- **Native no-camera / init-failure** error boundary around `YOLOView`.
- **`ModelNotSupportedScreen`** → add a "Try Gallery instead" action (gallery scanning works without live camera).
- **Model dropdown** error → tap to `ref.invalidate(availableYoloModelsProvider)`.

### P3 — translate/butty polish
- Output **typing indicator** in translate text mode (reuse sketchpad `_ThinkingDots`).
- **Empty/blocked AI response** → friendly "Butty didn't have anything to add." (translate) / "Hmm, I blanked — try rephrasing?" (butty) instead of a silent blank.
- **Retry affordance** on failed Butty message + translate feedback card (re-send last turn).
- **Live "no glyph in frame"** subtle hint overlay on the scan camera after idle.

### P4 — settings/profile consistency
- **Replace the 6 "coming soon" stubs** in `profile_management_section.dart:101,104,113,116,125,128` — wire to the real routes that `activity_section.dart` already uses (`routeLearningProgress`, `routeScanHistory`, `routeTranslationHistory`), or remove them.
- **Translation history "Clear all"** — `clearHistory()` exists (`translation_history_provider.dart:114`) but no UI calls it; add a confirmed action in the header (mirror butty_data).
- Add retry buttons to **Quiz** + **Character gallery** error states (low priority — copy is already friendly).
- Verify whether `privacy_dialog.dart` / `accessibility_dialog.dart` are dead code (profile_management_section builds its own inline dialogs).

---

## 5. Verification note
Authored without a Flutter toolchain (clone blocked by the proxy). Run
`flutter pub get && flutter analyze && flutter test` (or push a `v*` tag — the
release CI runs them) to confirm. The §3 fixes are localized string/widget
changes reviewed for correctness; the §4 items are intentionally deferred to a
toolchain-verified pass because they restructure `AsyncValue` consumption and
platform-permission flows.
