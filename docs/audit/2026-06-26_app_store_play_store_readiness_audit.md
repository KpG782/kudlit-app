# 📱 Kudlit — App Store & Play Store Readiness + UX Audit

**Date:** 2026-06-26
**Audit mode:** FULL (Store-Compliance + Functionality + UX + Hardening + Brainstorm)
**Method:** 10 parallel code-reading auditors over the real tree (`/home/user/kudlit-app`), every BLOCKER/CRITICAL cross-checked against source. Findings cite `file:line`.
**Reviewer persona:** Staff mobile engineer + senior product designer + store release manager.

> **How to read this:** Section 1 confirms what the app is. Section 2 is the blunt verdict + the exact list that blocks submission *today*. Section 3 is the full findings, grouped by dimension. Section 4 is the brainstorm/enhancement mandate. Section 5 is the roadmap (fast-ship vs long-term). Section 6 is the three things to do first.

---

## Severity model

| Tag | Meaning |
|---|---|
| 🚫 **BLOCKER** | Will be rejected at review **or** is outright broken/crashes. Guideline/policy cited. |
| 🔴 **CRITICAL** | Ships, but causes data loss, security/privacy exposure, crashes, or a major UX failure. Launch-critical. |
| 🟠 **MAJOR** | Real quality / retention / perf hit. Fix before scaling. |
| 🟡 **MINOR** | Polish, inconsistency, small friction. |
| 🟢 **ENHANCEMENT** | Not a problem; would make it great. |

*Severities reflect store-submission reality: a "launch-critical but not a literal rejection" item (e.g. no crash reporting) is tagged 🔴, not 🚫. Where a store value may have moved since training, the row is marked **(verify current)** with where to check.*

---

## 1) App understanding (confirm or correct me)

**Kudlit** is a Flutter, mobile-first **Baybayin** (ancient Philippine script) learning + translation app: it scans glyphs (on-device YOLO→TFLite), translates Filipino↔Baybayin, runs lessons/quizzes/a character gallery, and offers an AI companion **"Butty"** (Gemma on-device / Gemini via a Supabase Edge proxy) — aimed at Filipino learners (and the diaspora) who want to read, write, and understand Baybayin in one tool. It targets **Android, iOS, and Web** (Web is the dev/design target; Cloudflare Pages + GitHub Pages deploy paths exist), auth is **Supabase** (email, Google OAuth, phone OTP), and there is **no monetization today** (free, no IAP/ads).

**Stack & conventions that apply:** Flutter/Dart + Riverpod + go_router + Supabase + on-device YOLO/TFLite & Gemma. → **Material 3** conventions apply to Android/Web, **Apple HIG** applies to the (currently barely-configured) iOS target, layered with the in-repo Kudlit design system.

**Current store status:** **NOT submitted to either store.** The only public build is a **sideloaded Android APK** at `v1.0.0` (`versionName=1.0.0`, `versionCode=2`) off a GitHub Release (`README.md:33-39`); `pubspec.yaml:19` = `1.0.0+1`. There is **no iOS build/signing pipeline** and no mobile release CI.

---

## 2) Verdict

**🚫 Not submittable to Apple or Google today.** This is a genuinely well-built app — clean architecture, a real design system, server-side AI key, RLS on every table, an exemplary Scan tab — but it is blocked by a tight, fixable cluster of pre-submission gatekeepers, all confirmed in code.

### The store-submission blockers (fix all of these before either store will accept it)

| # | Blocker | Store / Guideline | Evidence |
|---|---|---|---|
| 1 | **Placeholder bundle ID `com.example.*`** (`com.example.kudlitPh` iOS / `com.example.kudlit_ph` Android) | Apple **2.1** + Play package policy — both reject `com.example.*` | `android/app/build.gradle.kts:9,24`; `ios/Runner.xcodeproj/project.pbxproj:484,666,688` |
| 2 | **Release signed with the DEBUG keystore** (+ `isMinifyEnabled=false`) | Play — debug-signed bundle rejected on upload | `android/app/build.gradle.kts:35-39` |
| 3 | **No Android App Bundle (.aab) build at all** — CI is web-only | Play requires AAB for new apps | `build.sh` (web only); no `flutter build appbundle` anywhere |
| 4 | **No Sign in with Apple** while Google sign-in is offered | Apple **4.8** | `lib/features/auth/...login_secondary_auth_row.dart:31-37`; zero `apple` refs in `lib/` |
| 5 | **No in-app account deletion** — it is a "coming soon" stub | Apple **5.1.1(v)** + Play account-deletion policy | `lib/.../settings/danger_section.dart:25-27` (`isSoon:true`); `profile_management_section.dart:158-170` |
| 6 | **No publicly reachable web URL for data/account deletion** | Play Data Safety requirement | privacy policy is in-app only (`privacy_policy_screen.dart:100-102`) |
| 7 | **Missing `NSCameraUsageDescription`** while the camera scanner is the headline feature → **iOS crash on first camera access** + reject | Apple **5.1.1 / 2.1** | `ios/Runner/Info.plist:52-54` (photo lib only); `pubspec.yaml:69` (`camera`) |
| 8 | **No iOS code-signing team / no entitlements file** — cannot archive, and SIWA capability is impossible until this exists | Apple **2.1** (prerequisite) | `ios/Runner.xcodeproj/project.pbxproj:223,448,571,628`; no `Runner.entitlements` |

### Then these launch-critical items (won't necessarily get rejected, but you should not launch without them)

- 🔴 **HUGGINGFACE_TOKEN ships inside the app** via the bundled `.env` asset (extractable) — `pubspec.yaml:103`, `build.sh:27`, `local_gemma_datasource.dart:162`.
- 🔴 **Session JWTs stored in plaintext** (no `flutter_secure_storage`) — refresh-token theft = account takeover.
- 🔴 **No crash reporting + no app-root error handling** (`FlutterError.onError`/`runZonedGuarded`/`ErrorWidget.builder` all absent) — you'd launch blind.
- 🔴 **No timeouts/retries anywhere** — cloud AI and model downloads can hang forever.
- 🔴 **On-device Gemma has no concurrency guard** (the documented fix was never implemented) — overlapping inferences garble output / spike memory.
- 🔴 **Silent web/guest data loss** — history "saves" then vanishes on reload with no warning.
- 🔴 **System Back exits the app from any home tab** (no `PopScope`) — core Android UX failure.

### What the prior (2026-05-14) audit *actually* fixed — verified in current code ✅

Credit where due — these are confirmed remediated, which materially lowers risk:

- ✅ **Gemini API key is now server-side** behind the `gemini-proxy` Edge Function; the client never sees it (`translator_providers.dart:51-61`, `supabase/functions/gemini-proxy/index.ts:111`).
- ✅ **Admin route is gated by a real role check** (default-deny) — `/admin/stroke-recorder` redirects non-admins (`app_router.dart:106-112` + `currentUserRoleProvider`).
- ✅ **Password-recovery handler + forced reset screen** exist (`router_listenable.dart:36-43`, `app_router.dart:61-64`).
- ✅ **sqflite is `kIsWeb`-guarded** in all six datasources (no `MissingPluginException` on web).
- ✅ **Phone OTP resend cooldown is real** (live `Timer.periodic` + 5-attempt lockout) — not dead code.
- ✅ **RLS enabled + per-user scoped on every table**; role self-promotion blocked server-side; `.env` git-ignored and never committed.

---

## 3) Findings by dimension

### 3.1 — Apple App Store compliance

| Sev | Finding | Evidence | Why it matters (guideline) | Fix | Effort |
|---|---|---|---|---|---|
| 🚫 | No Sign in with Apple (only Google + phone + email) | `login_secondary_auth_row.dart:31-37`; `auth_repository.dart:16`; no apple pkg in pubspec | **4.8** — third-party social login requires SIWA as an equal option | Add `sign_in_with_apple` + Supabase `OAuthProvider.apple`, iOS-gated button, SIWA entitlement | M |
| 🚫 | In-app account deletion is a "soon" stub | `danger_section.dart:22-28` (`isSoon:true`); `profile_management_section.dart:158-170`; no `deleteAccount` in repo | **5.1.1(v)** — account-creating apps must delete in-app (not "email us") | Confirm dialog → Edge Function `auth.admin.deleteUser(id)` + cascade delete → local sign-out | M |
| 🚫 | Missing `NSCameraUsageDescription` while camera is used | `Info.plist:52-54`; `scanner_camera.dart:454,495,567` | **5.1.1 / 2.1** — camera access w/o purpose string → runtime crash + reject | Add honest string ("Kudlit uses the camera to scan and recognize Baybayin characters.") | S |
| 🚫 | Placeholder bundle ID `com.example.kudlitPh` | `project.pbxproj:484,666,688`; `Info.plist:62` | **2.1** — `com.example.*` not registerable / flagged incomplete | Adopt real reverse-DNS (e.g. `ph.kudlit.app`) across pbxproj (3 configs), Info.plist, Supabase redirects, Android | S |
| 🔴 | No signing team / no entitlements file | `project.pbxproj:223,448,571,628`; no `*.entitlements` | **2.1** — can't produce a signed archive; SIWA needs entitlement | Set `DEVELOPMENT_TEAM`, enable signing, add `Runner.entitlements` (SIWA + Associated Domains) | M |
| 🟠 | No hosted Privacy Policy / Support URL (in-app screens only) | `privacy_policy_screen.dart` in-app only; no `https://` policy URL in `lib` | **5.1.1 / App Store Connect** requires live URLs | Host policy + support page; add URLs in ASC | S |
| 🟠 | App Privacy "nutrition labels" not prepared; collection is broad | `privacy_policy_screen.dart:26-71`; `cloud_gemma_datasource.dart` | **5.1.1(i)** — mismatched labels = rejection/removal | Complete App Privacy form (Contact Info, User Content, Identifiers, Diagnostics) accurately | M |
| 🟠 | Dead "mic / listening" UI (voice input promised, not wired) | `mic_button.dart:3-38`; `input_strip.dart:38` (no render site) | **2.1 / 4.2** — non-functional controls read as incomplete. *Note: no mic API is called, so `NSMicrophoneUsageDescription` is not required yet — but add it if you wire this up* | Delete the dead widgets, or implement STT + add mic/speech usage strings | S |
| 🟠 | "Coming soon" placeholders across Profile management | `profile_management_section.dart:99-170` (6+ "available soon") | **2.1 / 4.2** minimum functionality | Hide unfinished entries or implement them | S |
| 🟢 | No ATT/IDFA exposure (no ad SDKs) — good | pubspec (no ads/IDFA) | **5.1.2** — no ATT prompt needed today **(verify current** if analytics SDK added**)** | None now | — |
| 🟢 | No 3.1.1 payment trap (free app) — good | no `in_app_purchase` | **3.1.1** | Revisit if paid AI added (must use IAP) | — |

**Apple strengths:** custom 1024² icon (RGB, no alpha) + full icon set + LaunchImage (not defaults); `IPHONEOS_DEPLOYMENT_TARGET=16.0`, modern SceneDelegate, iPhone+iPad family; honest in-app Privacy/Terms screens incl. camera/AI disclosures; `NSPhotoLibraryUsageDescription` present + read-only gallery; `kudlit://` scheme registered.

---

### 3.2 — Google Play compliance

| Sev | Finding | Evidence | Why it matters (policy) | Fix | Effort |
|---|---|---|---|---|---|
| 🚫 | `applicationId` = `com.example.kudlit_ph` (+ `namespace`) | `build.gradle.kts:9,24` | `com.example.*` rejected; can't create listing | Real reverse-domain ID (`ph.kudlit.app`); update namespace + applicationId | S |
| 🚫 | Release signed with **debug** keystore | `build.gradle.kts:35-37` | Debug-signed AAB/APK rejected on upload | Upload keystore + `key.properties` (gitignored) + real release `signingConfig`; enroll Play App Signing | M |
| 🚫 | No AAB build exists; pipeline is web-only | `build.sh` (web only) | Play requires `.aab` for new apps | Add `flutter build appbundle --release` to CI; document in CLAUDE.md | S |
| 🚫 | No functional in-app account deletion (stub) | `danger_section.dart:25-27`; only `gemini-proxy` Edge fn exists | Play User-Data / account-deletion policy | Real deletion Edge fn + cascade; wire button + confirm | M |
| 🚫 | No public web URL for deletion requests | privacy in-app only; none in `web/` | Play Data Safety "data deletion" requires a reachable URL | Publish hosted policy + "Request data deletion" page; add to Data Safety | S–M |
| 🔴 | API secrets bundled via `.env` asset (HF token) | `pubspec.yaml:106-107`; `build.sh:27` | Assets are trivially extractable from AAB | Remove HF/secret keys from bundled `.env`; keep server-side; rotate | M |
| 🔴 | `targetSdk`/`minSdk` float on Flutter defaults | `build.gradle.kts:27-28` | Play enforces a rolling **min target API** (was API 35 in 2025) **(verify current 2026)** | Pin `targetSdk`/`compileSdk` to current Play minimum | S |
| 🔴 | Release `isMinifyEnabled=false`/`isShrinkResources=false` | `build.gradle.kts:38-39` | Ships bloated, un-obfuscated release w/ readable strings | Enable R8 + keep rules for TFLite/YOLO/gemma natives; test release | M |
| 🟠 | No adaptive launcher icon (legacy bitmap only) | `mipmap-*/ic_launcher.png`; no `mipmap-anydpi-v26/` | Listing-quality flag on modern Android | Generate adaptive icon via `flutter_launcher_icons` | S |
| 🟠 | 16 KB native page-size compliance unverified (TFLite/YOLO `.so`) | `ultralytics_yolo`+`flutter_gemma` AARs; `ndkVersion=flutter.ndkVersion` | Rolling 16 KB page-size enforcement **(verify current 2026 deadline)** | Build AAB, run Google's 16 KB check on bundled `.so`; pin NDK r27+; upgrade plugins if needed | M |
| 🟠 | Data Safety form needs careful, accurate declaration | `camera`/`image_picker`; Supabase email/Google/**phone OTP**; chat→Gemini | Mismatched Data Safety = top rejection/enforcement cause | Map every item → purpose + sharing (Supabase, Google AI); link policy URL | M |
| 🟠 | No Play Integrity / abuse protection on auth (phone OTP = SMS cost) | no integrity pkg; phone OTP present | Abuse/SMS-cost risk | Supabase phone rate-limiting + Play Integrity/reCAPTCHA on OTP | M |
| 🟡 | CAMERA permission not declared in app manifest (relies on plugin merge) | `AndroidManifest.xml:2-6` | Functionally OK (merger adds it); confirm no orphan `RECORD_AUDIO` | Verify merged manifest after AAB; remove unused audio perms | S |
| 🟢 | Lean, low-risk permission set; no high-risk perms → no Declaration Form/FGS | `AndroidManifest.xml:2-6,54-59` | Good | Keep minimal | — |
| 🟢 | Required store assets (feature graphic, screenshots, descriptions) not yet produced | `web/screenshots`/`web/social` exist; no Play-spec assets | Listing prerequisite (not code blocker) | Feature graphic 1024×500, ≥2 phone screenshots, short/full descriptions, content rating | M |

**Play strengths:** minimal permissions (no `QUERY_ALL_PACKAGES`/all-files/background-location/SMS/FGS → no Declaration Form); server-side AI proxy already correct architecture; privacy policy drafted; maskable web icons present; modern toolchain (AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17).

**(verify current):** exact 2026 target-API minimum + 16 KB page-size deadline — confirm in Play Console → Policy / Target-API requirements before final AAB.

---

### 3.3 — Functionality, states & auth flows

| Sev | Finding | Evidence | Why it matters | Fix | Effort |
|---|---|---|---|---|---|
| 🔴 | No timeout on cloud AI calls — `functions.invoke` can hang forever | `cloud_gemma_datasource.dart:348-356`; `gemini-proxy/index.ts:146` | Captive-portal/slow-proxy hangs chat with spinner stuck; only fix is force-kill | `.timeout(30s)` on all invoke/http/download awaits + friendly error | M |
| 🔴 | No timeout on YOLO model-download stream | `yolo_model_cache.dart:97-114` | First-run scanner setup hangs on flaky net; the 20s "stall detector" is cosmetic (`ai_inference_provider.dart:26`) | Idle/read timeout on request+stream; delete partial + fail fast | M |
| 🔴 | Silent web/guest data loss — in-memory history vanishes on reload, no warning | `sqlite_chat_datasource.dart:163-223`; `sqlite_scan_history_datasource.dart:120-122` | Looks like data corruption to the user | Persistent "session-only on web / sign in to keep" notice | M |
| 🔴 | No retries/backoff; no connectivity awareness | project-wide; no `retry`/`connectivity_plus` | A single blip permanently fails a turn/download; can't tell offline from server error | `connectivity_plus` + small exponential-backoff wrapper on idempotent reads | M |
| 🔴 | Chat sync has no client id / upsert → double-insert on re-sync | `supabase_chat_datasource.dart:22-31`; cf. facts use unique constraint `:62-66` | Re-sync/retry duplicates cloud chat rows | Client UUID + `upsert(onConflict: client_id)` | M |
| 🟠 | Email-verification link doesn't deep-link back (`signUp` has no `emailRedirectTo`) | `supabase_auth_datasource.dart:144-147` vs reset/OAuth `:86,180` | Confirm link opens web Site URL, not the app | Pass `emailRedirectTo: kudlit://auth/...` in `signUp` | S |
| 🟠 | Password-recovery gate is in-memory only — kill mid-reset → into `/home` w/ old password | `router_listenable.dart:48`; `reset_password_screen.dart:111` | Silent reset abandon | Persist pending flag; re-evaluate on cold start | M |
| 🟠 | Raw error strings leak into UI on ~7 screens | `translate_text_controller.dart:391`; `scan_history_screen.dart:89→185`; `translation_history_screen.dart:88→180`; `lesson_stage_screen.dart:113→292`; `butty_data_screen.dart:247` | `e.toString()` exposes internals, looks broken | Map via existing `Failure`/`AppConstants` pattern | M |
| 🟠 | Empty/blocked Gemini response → silent blank chat bubble | `cloud_gemma_datasource.dart:144,371-402`; `butty_chat_controller.dart:142` | MAX_TOKENS/SAFETY block looks like Butty froze | If empty text, throw → existing "Try again?" path | S |
| 🟠 | No retry/resend on a failed chat message | `butty_chat_controller.dart:177-191` | User must retype after a blip | Retry affordance on failed turn | S |
| 🟠 | Profile/learning collapse `AsyncValue` via `.value ??` → loading/error invisible | `learn_home_body.dart:123,126`; `learning_progress_screen.dart:36`; `profile_tab.dart:148` | Failed fetch looks like a wiped account (0 lessons/streak) | Use `.when()` with skeleton + retry | M |
| 🟠 | Profile management has no offline read fallback | `profile_management_repository_impl.dart:33,64` | Offline/web → profile errors; offline writes silently lost | Cache-first + queue writes | M |
| 🟠 | No model-download integrity check (no checksum) | `yolo_model_cache.dart:101-118`; `ai_model_info.dart` (no hash) | Truncated-but-200 download cached as valid → cryptic failures | sha256 verify before version stamp | M |
| 🟡 | Sign-out: no confirm, errors swallowed (always navigates away) | `settings_screen.dart:33-38`; `auth_notifier.dart:95-99` | Accidental sign-out; inconsistent session on failure | Confirm dialog; check `Either` result | S |
| 🟡 | Delete-account stub (snackbar only) | `danger_section.dart:26-27` | Store/GDPR/Play deletion expectation unmet (see blockers) | Implement or hide until ready | M |
| 🟡 | No state restoration (process death loses draft/scroll/quiz) | none in `lib/` | Android low-mem kill loses in-progress state | `restorationScopeId` on key screens | M |
| 🟡 | No `maxLength`; password min only 6 chars, no strength rules | `sign_up_screen.dart:57`; `reset_password_screen.dart:45` | Unbounded input; weak policy | Add `maxLength` + stronger password rule | S |
| 🟡 | Reset-password surfaces raw `AuthException.message` | `reset_password_screen.dart:88-93` | Inconsistent with mapped auth screens | Route through `_mapFailure` | S |
| 🟢 | No push notifications at all | not in pubspec | No re-engagement (deliberate decision needed) | Add FCM/local notifications if desired | L |

**Functionality strengths:** Scanner state coverage is exemplary (loading / no-glyphs / permission-denied / no-webcam / model-not-ready / unsupported-device / web-vs-native, all friendly-mapped); quiz/gallery/Butty-data use `.when()` cleanly; Butty has typing indicator, streaming cursor, offline-disabled input, seeded greeting; local-first writes with fire-and-forget cloud sync that never crashes UI; memory-fact dedup via DB unique constraint; local→cloud inference failover; clean PKCE auth + implicit token refresh.

---

### 3.4 — UI/UX & accessibility

| Sev | Finding | Evidence | Why it matters | Fix | Effort |
|---|---|---|---|---|---|
| 🔴 | **System Back exits the app from any home tab** (no `PopScope`; tabs are `PageView` state, not routes) | `home_screen.dart:177-186`; zero `PopScope` in repo | #1 Android nav expectation broken; predictive-back opted-in but unhandled | `PopScope(canPop: activeTab==scan, onPopInvokedWithResult:…)` to fall back to default tab | M |
| 🔴 | **"Reduced Motion" setting is dead** — pref stored, no animation reads it; `MediaQuery.disableAnimations` never checked | `accessibility_dialog.dart:22,46`; ~39 `flutter_animate` uses play regardless | WCAG 2.3.3 + false-advertised a11y control; harms vestibular users | Gate `.animate()`/splash on `disableAnimationsOf(context) || prefs.reducedMotion` | M |
| 🔴 | **"High Contrast" setting is dead** — pref stored, no theme variant selected | `accessibility_dialog.dart:39-40`; `app.dart:22-23` (only themeMode read) | Same false-promise a11y problem | Add high-contrast `ThemeData` selected from pref, or remove | M |
| 🔴 | **Language toggle is cosmetic** — hardcoded `'EN'`, no handler; no i18n infra at all | `login_language_toggle.dart:4-43`; `app.dart:19-26` (no locale/delegates) | Bilingual Filipino app that can't switch UI language; broken-looking + ASC metadata risk | Remove the toggle, or add `gen_l10n` + `.arb` + locale pref | S (remove) / L (build) |
| 🔴 | **Zero iOS HIG adaptation** — no Cupertino/`.adaptive`/platform override; Material everywhere, no iOS edge-swipe back | `kudlit_theme.dart:81,243`; `app_router.dart:130-229` (all Material `builder`) | iOS feels like an Android port; missing back-swipe gesture | Adaptive `pageBuilder` (Cupertino on iOS), `Switch.adaptive`, `*.adaptive` indicators | L |
| 🟠 | Splash secondary text fails WCAG AA (~2.3:1) | `splash_screen.dart:123-127,194-198` | First screen unreadable for low-vision/sunlight | Lighten captions to ≥`blue800` (~8:1) | S |
| 🟠 | Inactive AI-source pill text fails AA (~1.9:1) + color-only state | `app_header.dart:284,192` | Unselected option nearly invisible | Full `onSurfaceVariant`; add non-color selected cue | S |
| 🟠 | AppBar title contrast borderline (4.29:1, passes only as "large/bold") | `kudlit_theme.dart:86-87`; `kudlit_colors.dart:10,37` | Any non-bold white on `topbar` fails AA | Darken `topbar` to `blue400` (6.8:1) | S |
| 🟠 | Dynamic Type defeated — hardcoded `fontSize:` wrapped in `FittedBox(scaleDown)` | `floating_tab_nav.dart:319-324`; `scan_tab.dart:895-901`; `app_header.dart:273-285` | At 200% OS scale chrome stays tiny/clamps → WCAG 1.4.4 fail | Use `textTheme.*`; allow reflow; reserve `FittedBox` for fixed chrome | L |
| 🟠 | Floating tab nav is non-standard, low-discoverability (tap-to-reveal corner pill) | `floating_tab_nav.dart:13-82`; `home_screen.dart:187-194` | Primary nav hidden behind an extra tap; awkward one-handed reach | Validate vs M3 `NavigationBar`; if kept, expand by default + labels | L |
| 🟠 | History error states leak raw exceptions | `scan_history_screen.dart:89,185`; `translation_history_screen.dart` | Users see stacky text, no recovery CTA | Friendly mapper (reuse model-setup pattern) | S |
| 🟡 | Loading is raw spinners, not skeletons (branded skeleton infra unused) | `scan_history_screen.dart:88`; `character_gallery_screen.dart:49`; `splash_screen.dart:186` | Worse perceived perf on core lists | Layout-matched skeletons; route via `KudlitLoadingIndicator` | M |
| 🟡 | Empty states have copy but no CTA | `scan_history_screen.dart:109-162`; `learning_progress_screen.dart:12-19` | Misses time-to-value lever | Add primary CTA ("Scan now"/"Translate something") | S |
| 🟡 | No pre-permission priming for camera | `scan_tab.dart:577-588`; `scanner_camera.dart:81-103` | Cold prompts deny more; no Settings-deep-link recovery | One-screen rationale before first OS prompt | S |
| 🟡 | Meaningful brand images lack `semanticLabel` (~30 `Image.asset`) | `app_header.dart:111`; `login_butty_area.dart:26`; `lesson_detail_card.dart:121` | Screen readers skip/announce filenames | `excludeFromSemantics` for decorative; label meaningful ones | M |
| 🟡 | Haptics only on Scan tab; rest silent | `scan_tab.dart:112,191,229`; none in nav/toggles | Inconsistent tactile language | `selectionClick` on tab/toggle changes | S |
| 🟡 | Status-bar style uncontrolled (no `SystemUiOverlayStyle`) | Info.plist absent; no `AnnotatedRegion` in `lib/` | Icon contrast may clash with colored header/themes | Set per-theme via `AnnotatedRegion`/`appBarTheme.systemOverlayStyle` | S |
| 🟢 | Design-token drift — brand hex inline instead of tokens; dark consts outside `KudlitColors` | `scan_tab.dart:830`; `floating_tab_nav.dart:108-118`; `kudlit_theme.dart:165-169` | Reskin/high-contrast/dark tuning error-prone | Centralize spacing/radius/motion tokens in Dart; fold dark consts in | L |
| 🟢 | RTL not ready (~190 physical `EdgeInsets`/`Positioned` vs ~4 `*Directional`) | `scan_tab.dart:636` | No impact today (EN+FIL are LTR); future cost | Prefer `*Directional` in new code | L |

**UX strengths:** the **Scan tab is an accessibility exemplar** — real `Semantics` on every control, a regression test enforcing ≥48dp targets, `liveRegion` notices, tooltips; **dark mode fully implemented** (body ~15:1); permissions are contextual/just-in-time; thorough responsive density handling; polished error UX with brand-voice copy; the `colors_and_type.css` token system is more rigorous than most apps ship.

---

### 3.5 — Performance & reliability

| Sev | Finding | Evidence | Why it matters | Fix | Effort |
|---|---|---|---|---|---|
| 🔴 | **On-device Gemma concurrency fix never implemented** — one shared model, zero serialization across Butty/translate/scanner/sketchpad/memory-extraction | `local_gemma_datasource.dart:194-306`; `translate_sketchpad_controller.dart:129`; `memory_extraction_service.dart:83`; `docs/local_gemma_concurrency_audit_and_plan.md` ("awaiting approval") | Overlapping native inferences tear the model down mid-use → memory/CPU spike, heat, garbled/truncated replies | Implement the planned `InferenceGate` (serialize + supersede lanes), or a single mutex around `generate`/`analyzeImage`/model-load | M |
| 🔴 | `.env` bundled as a Flutter asset → secrets ship in the app | `pubspec.yaml` assets `- .env`; `main.dart:12`; `local_gemma_datasource.dart:162` | Secrets in a shipped asset aren't secret (HF token) | Remove `.env` from assets; inject via `--dart-define`/secure config; rotate | S |
| 🔴 | No app-lifecycle pause for camera/YOLO (only Butty observes lifecycle) | `home_screen.dart:84-108`; `butty_chat_screen.dart:42-52` | Camera+YOLO can keep running backgrounded → battery/heat/ANR | `WidgetsBindingObserver` on `HomeScreen`; pause on `paused/inactive` when on Scan | S |
| 🔴 | All 4 tabs mounted for app lifetime via `PageView` — `ScanTab` (camera + `YOLOView`) never torn down off-tab | `home_screen.dart:177-185`; `scanner_camera.dart:50-54` | Native camera texture stays resident; "pause" is a band-aid, not teardown | `IndexedStack` w/ lazy keep-alive for cheap tabs; dispose `YOLOView` off-Scan | M |
| 🟠 | Cold start blocks first frame on 3 sequential awaits | `main.dart:10-19` (`dotenv` → `Supabase.initialize` (network) → `initializeFlutterGemma`) | TTI gated by a network round-trip; slow-net launch looks hung | `runApp` first (splash), then async init; defer Gemma bootstrap | S |
| 🟠 | Shutter capture decodes full-res `RepaintBoundary`→PNG on main isolate (no `compute()` anywhere) | `scan_tab.dart:234-243`; web path `web_tflite_model_runtime.dart:56-64` | PNG encode of 1.5×-DPR full screen janks the shutter; large model payload | Lower `pixelRatio`, JPEG not PNG, move encode/resize off main isolate | M |
| 🟠 | Chat history loads ALL rows (no pagination); full list re-spread per streamed token | `chat_history_provider.dart:32`; `butty_chat_controller.dart:149-154` | Unbounded memory + O(n)/token GC churn in long chats | Page history (cloud already `limit:100`); mutate only streaming tail | M |
| 🟠 | Gemma download has no RAM/storage guard; model kept resident + 2nd context during `analyzeImage` | `local_gemma_datasource.dart:64-143,264-276` | OOM-kill driver on low-RAM devices | Device-RAM gate; release model when cloud/backgrounded; never hold two contexts | M |
| 🟡 | Avatars/glyphs use raw `Image.network`, no caching/decode-sizing | `profile_hero_avatar.dart:126`; `reference_glyph_card.dart:59` | Re-download on rebuild; full-res decode into 88px slot | `cached_network_image` or `cacheWidth/cacheHeight` | S |
| 🟡 | Scanner `evaluate` cancels Dart-side only; native inference runs to completion | `scanner_evaluation_provider.dart:55,158,174` | Stacked native AI calls waste CPU/battery | Tie cancellation to the gate (supersede `scan` lane) | M |
| 🟢 | `flutter_animate` on always-mounted screens may keep tickers active off-screen | `typing_bubble.dart`, `profile_hero_card.dart`, etc. | Possible idle frame work **(verify with perf overlay)** | Gate animations to active tab | S |
| 🟢 | Android `minSdk` floats on Flutter default; no `abiFilters` | `build.gradle.kts:27` | MediaPipe/NNAPI floors may be higher; x86 libs inflate size **(verify current)** | Pin `minSdk` to gemma floor; add arm64/armeabi `abiFilters` | S |

**Performance strengths:** **no model bundled** (assets ~988 KB; models downloaded on demand w/ progress + cancel) — right call for install size; YOLO output throttled (250ms) + temporally filtered (2-hit) before touching the tree; lazy lists where they matter; clean `const` decomposition keeps rebuild scope tight; camera lifecycle on tab-change handled + `CameraController` disposed correctly; repo-level local→cloud failover uses `await for` to catch stream errors.

---

### 3.6 — Security & privacy (OWASP Mobile Top 10)

| Sev | Finding | Evidence | Why it matters | Fix | Effort |
|---|---|---|---|---|---|
| 🔴 | **HUGGINGFACE_TOKEN bundled in client `.env`** (prior key-in-bundle issue only half-fixed) | `pubspec.yaml:103`; `build.sh:27`; `local_gemma_datasource.dart:162,313`; `.env.example:7` | Leaked HF token → abuse of owner's HF account/quota + gated-model access | Signed-URL/proxy Edge fn for gated downloads, or public bucket + drop token; rotate | M |
| 🔴 | **Session JWTs stored in plaintext** (default storage; no `flutter_secure_storage`) | `main.dart:13-16`; pubspec (no secure storage) | Rooted/backed-up device or web XSS → refresh-token theft = account takeover (M9) | Custom `LocalStorage` backed by Keychain/Keystore in `Supabase.initialize` | M |
| 🔴 | **No account deletion or data export** (GDPR Art.17/20, CCPA + store policy) | zero `deleteAccount`/`exportData` hits across `lib/`+`supabase/` | Privacy-law violation + store-rejection blocker | In-app delete → service-role `admin.deleteUser()` (cascade) + delete avatar; add export | M–L |
| 🟠 | `data_sharing_consent` toggle is decorative — gates nothing | `privacy_dialog.dart:15-51`; persisted `local_profile_management_datasource.dart:211`; no read-side branch | Presenting a non-functional consent switch is itself a GDPR/CCPA violation | Gate cloud sync/analytics/optional AI on `consent==true`, or remove | S |
| 🟠 | Missing `NSCameraUsageDescription` (also a privacy-manifest concern) | `Info.plist:53` photo-only | iOS crash + reject (see Apple blockers) | Add camera (+mic if used) usage strings | S |
| 🟠 | Email confirmation disabled (`enable_confirmations=false`, "set true for prod") | `supabase/config.toml:108` | Unverified-email squatting/spam/reset-abuse **(verify on live project)** | Enable confirmations in production | S |
| 🟡 | Stroke patterns world-readable (anon SELECT) incl. `device_info` | `migrations/20260504100000_stroke_patterns_public_read.sql` | `device_info` leaked to anon aids fingerprinting (order/timing is low-sensitivity) | Strip `device_info` from anon-exposed rows / public view | S |
| 🟡 | Admin route enforced client-side at router; protection relies on RLS | `app_router.dart:103-112`; `current_user_role_provider.dart` | Acceptable — `stroke_patterns` INSERT/DELETE re-check `is_admin()` server-side | Keep RLS as source of truth; confirm `verify_jwt` on | — |
| 🟡 | Local SQLite (chat + AI "memory facts") unencrypted | `sqlite_chat_datasource.dart:42` | Conversation + personal facts readable from backup/rooted device | `sqflite_sqlcipher` w/ Keychain/Keystore key | M |
| 🟡 | Edge Function CORS `Access-Control-Allow-Origin: *` | `gemini-proxy/index.ts:52` | Any origin can invoke (bounded by JWT + rate limit) | Restrict to known web origins | S |
| 🟢 | No input sanitization before Gemini (prompt injection) — output-only `safe_ai_output` | `safe_ai_output.dart`; `cloud_gemma_datasource.dart:122-145` | Limited impact (no tools/secrets to model); chatbot scope | Keep strong system prompt; cap input length; treat output untrusted | S |
| 🟢 | Edge rate limit is in-memory per-isolate (best-effort) | `gemini-proxy/index.ts:27-47` | Weak per-user cap under fan-out → cost abuse | Postgres/Upstash counter keyed by `user_id` w/ TTL | M |

**Security strengths:** **Gemini key is genuinely server-side** (proxy verifies JWT before calling Google; no `apiKey` plumbing in `lib/`); `.env` git-ignored + never committed; **RLS enabled + per-user scoped on every table**; privilege escalation blocked (`role` non-self-promotable, `is_admin()` is `security definer` w/ pinned search_path); avatar storage path-scoped to `auth.uid()`; **no cleartext HTTP** (no `usesCleartextTraffic`/`NSAllowsArbitraryLoads`); OAuth/reset via registered scheme + origin-bound web redirect; session timeboxing configured; service-role client uses `persistSession:false`.

**(verify on live project, not just local config):** `enable_confirmations`, function `verify_jwt`, and whether prod CI actually sets `HUGGINGFACE_TOKEN` into the bundle.

---

### 3.7 — Observability & production engineering

| Sev | Finding | Evidence | Why it matters | Fix | Effort |
|---|---|---|---|---|---|
| 🔴 | No crash reporting (no Crashlytics/Sentry/Bugsnag) | pubspec; grep → none | Launch blind; can't measure crash-free rate or triage field crashes | Add `sentry_flutter`/`firebase_crashlytics`; init before `runApp` | M |
| 🔴 | No app-root error handling (no `FlutterError.onError`/`runZonedGuarded`/`ErrorWidget.builder`) | `main.dart:10-20`; grep → none | Uncaught errors silently dropped/red-screen; even a crash SDK won't capture without hooks | Wrap `runApp` in `runZonedGuarded`; set the 3 hooks → reporter | S |
| 🔴 | Release Android signed with debug keys; minify/shrink off; no mapping produced | `build.gradle.kts` release block | Play rejects; Android traces unsymbolicated even with a reporter | Upload keystore + `key.properties`; enable R8; upload mapping | M |
| 🔴 | No symbolication / dSYM / mapping upload anywhere | grep `split-debug-info`/`obfuscate`/`mapping`/`dSYM` → none; `build.sh` web-only | Any future crash trace is obfuscated junk | Build `--obfuscate --split-debug-info`; upload symbols/mapping/dSYM in CI | M |
| 🔴 | No analytics at all (no activation/retention/funnel) | pubspec; grep → none | No idea if users onboard/translate/retain | Analytics SDK behind a thin interface; instrument scan→detect→translate + lesson-complete + sign-in funnel | M |
| 🔴 | No mobile build/release pipeline — CI is web-only | `deploy-pages.yml` (web); `lint.yml` (analyze) | The APK is hand-built; no reproducible signed/versioned release, no staged rollout/rollback | GH Actions: `flutter build appbundle --release` + secret signing + obfuscation + symbol upload + `upload-google-play` (staged `userFraction`) | L |
| 🟠 | No remote config / feature flags / kill switch / forced-update | grep → none | Can't disable a broken model URL or force users off a crashing build; bad release unrecoverable | Firebase Remote Config or Supabase flags table; min-version gate + forced-update screen | M |
| 🟠 | No integration/E2E tests (no `integration_test/`, no Patrol/Maestro) | no dir; pubspec → none | 41 widget/unit tests but the camera→YOLO→translate path + auth never run end-to-end | `integration_test` + ≥1 happy-path E2E + auth flow on an emulator in CI | M |
| 🟠 | Critical-path test gaps: account deletion, offline, translate-failure | `profile_management_section.dart:161-165`; `translate_text_controller_test.dart:28-62` | Highest-risk flows are untested | Implement + test deletion; offline/model-missing translate fallback tests | M |
| 🟠 | No performance/RUM monitoring (mobile or web) | no perf dep; nginx static | No model-load/inference/cold-start/Web-Vitals visibility on a perf-sensitive ML app | Firebase Performance/Sentry traces around model load + inference; web RUM beacon | M |
| 🟠 | Analytics opt-out promised in plans but no analytics exists | `docs/profile_management_feature_plan.md:41` | Toggle would be cosmetic; sequence consent before instrumentation | Add analytics behind a consent gate from day one | S |
| 🟡 | No semver discipline / changelog / release tags | `pubspec.yaml:19` stuck `1.0.0+1`; `git tag` empty | Can't correlate a field crash to a commit | `CHANGELOG.md`, tag releases, bump `+build` in CI | S |
| 🟡 | 86 `debugPrint` across 24 files; no structured logging | grep → 86 hits | Low risk (stripped in release) but ad-hoc, no breadcrumbs | Logger abstraction w/ levels → crash-reporter breadcrumbs | S |
| 🟡 | No documented min-supported-OS policy | `build.gradle.kts:27` | No controlled deprecation; old-OS users can't be steered off | Pin + document `minSdk`/iOS target; pair w/ forced-update | S |
| 🟢 | Web env secrets written to shipped `.env` asset | `build.sh:23-28`; `deploy-pages.yml:33-45` | Any key in web `.env` is publicly fetchable (see Security) | Proxy via Edge Functions; never bundle service keys | M |

**Observability strengths:** **lint is enforced in CI on every PR** (`flutter analyze --fatal-infos`, fails the build — `lint.yml:57-59`); reproducible pinned web build (Dockerfile + healthcheck); decent web edge hygiene (X-Frame-Options, nosniff, immutable caching); no secrets leaked through the 86 debugPrints; cloud-sync failures kept non-fatal ("(non-fatal)") — a good resilience pattern that just needs a real sink; solid 41-file widget/unit base (auth use-cases, cloud Gemma streaming, scanner) to build E2E on.

---

### 3.8 — Growth, monetization & ASO

| Sev | Finding | Evidence | Why it matters | Fix | Effort |
|---|---|---|---|---|---|
| 🔴 | Not on either store; APK distribution w/ placeholder IDs + debug signing | `README.md:37-44`; `build.gradle.kts:35-37,9,24` | Zero organic ASO discovery — the #1 channel for a niche cultural app | Ship to both stores (see blockers) | M |
| 🔴 | iOS `NSCameraUsageDescription` missing (flagship feature) | `Info.plist` (photo-only) | Crash + reject kills scan on day one | Add usage string | S |
| 🟠 | No in-app review prompt (`in_app_review` absent) | pubspec; grep → none | Ratings volume/recency is a top ASO factor; starts cold | `in_app_review` after a delight moment (lesson done / good scan / 3-day streak), once per version | S |
| 🟠 | Streak is remote-only, not persisted; returns 0 for guests/offline | `streak_provider.dart:16-33` (`if userId==null return 0`; `catch(_) return 0`) | Core retention hook shows 0 for the guest cohort + flickers offline | Cache locally; compute from local completions; reconcile when authed; never hard-reset on error | M |
| 🟠 | No notifications of any kind | pubspec; AndroidManifest perms `:2-6` | Daily/streak reminders = highest-leverage retention for streak learning apps | `flutter_local_notifications` for local streak reminders first; `POST_NOTIFICATIONS` w/ soft pre-prompt | M |
| 🟠 | No referral/invite/deep-link loop; shares carry no install link | only Supabase auth deep links; no `app_links`/referral | Viral shares don't convert/attribute — the loop leaks | Add store/deep link + referral code to share/export payloads; web smart banner | M |
| 🟠 | English-only despite Filipino-market targeting; toggle is placeholder | no `flutter_localizations`/`.arb`; `login_language_toggle.dart:29` | Filipino UI + listing lifts PH ASO/conversion/trust | `flutter_localizations` + en/fil ARBs; localize store metadata | L |
| 🟠 | No store-listing metadata in repo (only generic pubspec line) | no `fastlane/metadata`; `pubspec.yaml:2` | Title/subtitle/keywords are the core ASO surface | Draft localized title/subtitle/keywords ("Baybayin","Alibata","Filipino script","learn/translate Baybayin"); version under `fastlane/metadata` | M |
| 🟡 | Cold camera permission prompt (no priming) | `scanner_camera.dart` direct access | Higher hard-deny on the flagship feature | One-screen rationale before OS prompt | S |
| 🟡 | No milestones/streak-freeze/XP/badges | `learning_progress_screen.dart`; `learn_home_body.dart:203` | Missing habit-forming dopamine + shareable moments | Milestone celebrations + monthly streak-freeze + shareable badge (reuse export card) | M |
| 🟡 | No preview video; screenshots are raw frames | `docs/release-screenshots/*.png`; no `.mp4`/feature graphic | Captioned/framed shots + video lift conversion | Captioned framed screenshots + 15–30s reel + Play feature graphic | M |
| 🟢 | Monetization: none today; architecture has store-rule trade-offs to plan | cloud AI is server-cost-bearing; on-device path exists (`app_preferences_provider.dart:8`) | Unlimited free cloud AI won't scale; *how* you charge is store-rule-sensitive | If monetizing AI/lessons (digital goods) → **must** use Apple IAP / Play Billing; never web checkout in-app. Safer: cosmetic/export packs or "Kudlit Pro" subscription via IAP, or push AI on-device. Avoid ads in an education/cultural app | — |
| 🟢 | Guest path strong but loses everything on close (no anon→account migration) | `login_screen.dart:65-66`; sync gated behind auth | Invested guests churn instead of converting | Contextual "save your streak — sign up" nudge after first value + migrate guest data | M |

**Growth strengths:** genuinely differentiated core (camera Baybayin OCR + on-device AI tutor — collapses 2–3 tools into one); Butty's persistent semantic memory is real personalization/stickiness (and runs on-device — privacy/offline angle); excellent time-to-first-value (guest → translate in ~2 taps); a ready-made viral artifact already exists (branded multi-theme export PNG via `export_sheet.dart`); cost-aware AI architecture (server key + rate limit + on-device fallback); launch-ready brand/mascot/icons.

---

## 4) Brainstorm / enhancement mandate

*Grounded in what's already built (so nothing below re-proposes existing features). Confirmed NOT built: TTS, notifications/home widget, daily glyph, community/UGC, teacher mode, leaderboard, AR overlay, true stroke-order scoring, first-class name-in-Baybayin generator.*

### 5–10 high-impact upgrades

| Idea | User value | Effort | Store-policy caveat |
|---|---|---|---|
| **A. TTS pronunciation everywhere** (`flutter_tts`, `fil-PH`) on gallery glyphs, translate results, quiz — Baybayin is *spoken* first; silent glyphs are a glaring gap | High | **S** | None |
| **B. True stroke-order handwriting scoring** — the admin `StrokePattern`/`TimedPoint` recorder already captures timed reference strokes; today `draw` mode only re-detects the finished glyph. Score count/order/direction via DTW → "3/4 strokes, you started bottom-up" | High | **M** | None |
| **C. Daily Glyph + smart local notifications** — streaks exist but nothing reminds; "Your 6-day streak ends in 4 hours" | High | **S–M** | Android 13+ `POST_NOTIFICATIONS` runtime prompt; opt-in only |
| **D. "Name in Baybayin" generator → existing share card** — promote the chat suggestion to a first-run surface; reuse `export_sheet.dart` | High (virality) | **M** | None |
| **E. Offline-first lessons & gallery** — full beginner track + gallery + TTS with zero network, honest offline banner instead of spinners | High | **S** | None (helps review — reviewers test on bad networks) |
| **F. Scan → annotated result card** (per-glyph highlight + confidence + one-tap "Butty, explain") — bridges Scan→Learn→Butty | High | **M** | None |
| **G. Skill-tree / lesson map** (Duolingo-style unlock over existing progress data) | Medium | **M** | None |
| **H. Accessibility + Tagalog localization pass** (make the dead a11y toggles real; semantic labels; real `fil` locale) | Medium | **S–M** | A11y label gaps are a soft review risk |

### The 10x idea — **"Living Script": your handwriting becomes the app's font**

Fuse the *already-recorded* `StrokePattern`/`TimedPoint` system (B) with the export card (D): as the user practices, capture their own glyph strokes; once they've drawn all base characters, **generate a personal Baybayin handwriting "font"** they can type any name/phrase in and share as a branded image — *in their own hand, earned through practice*. A translator outputs a Unicode font anyone has; Kudlit outputs **your ancestral script in your own handwriting** — learning + identity (huge for the diaspora) + virality (every share is unique and credits Kudlit). The scoring engine, stroke recorder, and export pipeline already exist; this is integration + a glyph-compositing step. **Effort: L (mostly assembly).**

### If you had only ONE WEEK (goal: first submission + don't embarrass the team)

1. **Offline-first hardening + honest empty/error states (E + fix the raw-error leaks).** Reviewers test on bad networks and tap every dead-end; "spinner/blank screen" is the most common rejection/embarrassment. **Highest risk-reduction.**
2. **TTS on glyphs + translate results (A).** One dependency, one button — instantly makes the app feel complete in the 90-second demo (which currently has no audio).
3. **"Name in Baybayin" generator wired to the existing share card (D, scoped — skip the widget).** The screenshot that gets posted + the listing hero, reusing `export_sheet.dart`.

*Deliberately deferred from week one: notifications (runtime-permission UX needs care) and any community/UGC (triggers Apple 1.2 / Google UGC moderation requirements — keep social out of v1).*

---

## 5) Roadmap

### A) FAST-SHIP — minimum to pass review + not embarrass us (ordered)

1. **Real bundle ID** (`ph.kudlit.app` or similar) across Android + iOS (pbxproj ×3, Info.plist, Supabase redirects). *[S]*
2. **iOS signing team + `Runner.entitlements`** (enables archive + SIWA capability). *[M]*
3. **`NSCameraUsageDescription`** (+ mic strings only if you wire voice). *[S]*
4. **Android release signing** (upload keystore + `key.properties`, Play App Signing) + **enable R8**. *[M]*
5. **AAB build** (`flutter build appbundle --release`) wired into CI. *[S]*
6. **Sign in with Apple** (package + Supabase provider + iOS-gated button + entitlement). *[M]*
7. **Real in-app account deletion** (Edge fn `admin.deleteUser` + cascade + avatar delete) **+ hosted web deletion URL**. *[M]*
8. **Hosted Privacy Policy + Support URLs**; complete **App Privacy** form + **Play Data Safety**. *[S–M]*
9. **Remove HF token from the bundle** (proxy/signed-URL or public bucket) + rotate; stop bundling `.env`. *[M]*
10. **Crash reporting + app-root error hooks** (`runZonedGuarded` + `FlutterError.onError` + reporter) and **timeouts** on all network/download awaits. *[M]*
11. **Pin `targetSdk`/`minSdk`** to current Play minimum **(verify current)**; run the **16 KB page-size** check on bundled `.so` **(verify current)**. *[S–M]*
12. **Polish that reviewers see:** fix system-Back (`PopScope`), make Reduced-Motion/High-Contrast actually work or remove them, remove the cosmetic language toggle + dead mic/"coming soon" stubs, map the ~7 raw-error screens, add adaptive Android icon. *[S–M each]*

### B) LONG-TERM — architecture / quality / scale

- **On-device Gemma `InferenceGate`** (serialize + supersede lanes) — eliminate the concurrency crashes/garble.
- **Tab shell rework** — `IndexedStack` w/ lazy keep-alive + camera teardown off-Scan; app-lifecycle pause.
- **Secure token storage** (Keychain/Keystore) + **SQLCipher** for chat/memory.
- **Mobile release CI** (fastlane/GH Actions: signing, obfuscation, symbol upload, staged rollout, rollback) + **semver/changelog/tags**.
- **Analytics behind a real consent gate** + **performance/RUM** + **remote config / kill switch / forced-update**.
- **Integration/E2E tests** for scan→translate, auth, offline, account deletion.
- **Real i18n** (`gen_l10n`, en/fil) + Dynamic Type via `textTheme` (drop `FittedBox(scaleDown)` for content) + iOS HIG adaptation.
- **Network resilience layer** (`connectivity_plus` + backoff + idempotent chat upsert + download checksums).
- **Retention engine** (local-persisted streaks, notifications, milestones, in-app review, referral loop).

---

## 6) Top 3 — do these first

1. **Clear the store-identity + signing blockers (bundle ID → iOS signing/entitlements → Android release keystore → AAB).** *Why:* nothing else matters until an artifact can actually be uploaded and archived; these are pure config, ~1–2 days total, and they unblock both stores at once.
2. **Implement the three legally/policy-mandated flows: in-app account deletion (+ web URL), Sign in with Apple, and `NSCameraUsageDescription`.** *Why:* these are guaranteed, non-negotiable rejections (Apple 5.1.1(v), 4.8, 5.1.1) — and the missing camera string is also a *guaranteed iPhone crash* on the flagship feature. No amount of polish gets past them.
3. **Get eyes + guardrails on production: crash reporting + app-root error handling + network timeouts, and remove the HUGGINGFACE_TOKEN from the bundle.** *Why:* you currently launch blind (no crash visibility), can hang forever on bad networks, and ship an extractable credential. These are the difference between "we shipped" and "we shipped and can survive the first week."

---

### Appendix — audit method & caveats

- **Auditors (parallel, real-code):** Apple compliance, Play compliance, Functionality/states, UI/UX/a11y, Performance/reliability, Observability/prod-eng, Security/privacy, Growth/ASO, plus App-understanding and Brainstorm. Every BLOCKER/CRITICAL was cross-checked against source.
- **Could not run the app** in this environment, so the few runtime-dependent items are marked *(verify with perf overlay / on a device)*: off-screen ticker behavior, exact composited contrast ratios, and the literal Back-press animation (code path is unambiguous).
- **Live-project items to confirm in Supabase** (not just local config): `enable_confirmations`, function `verify_jwt`, and whether prod CI sets `HUGGINGFACE_TOKEN` into the bundle.
- **Rolling store values to re-confirm before final build:** Play target-API minimum (2026), 16 KB page-size enforcement deadline, ATT applicability if any analytics SDK is added.
