# Kudlit — Deployment Hardening Changes & Follow-ups (2026-06-26)

Companion to `2026-06-26_app_store_play_store_readiness_audit.md`. This logs what
was changed in the deployment-prep pass, what still needs **your** input before
you can ship, the **deferred Apple/Google sign-in blockers** (as requested), and
the high-ROI features that are scaffolded vs. still to wire.

> ⚠️ **Environment note:** these changes were authored in an environment with **no
> Flutter/Dart toolchain**, so the Dart could not be compile-checked here. Before
> merging/releasing, run:
> ```bash
> flutter pub get
> dart run build_runner build --delete-conflicting-outputs
> flutter analyze
> flutter test
> ```

---

## 1. Changes made in this pass (committed)

### Store-config blockers — fixed (declarative, low risk)
- **Bundle ID → `app.kudlit`** everywhere:
  - `android/app/build.gradle.kts` (`namespace`, `applicationId`)
  - `android/app/src/main/kotlin/app/kudlit/MainActivity.kt` (moved from `com/example/kudlit_ph`, `package app.kudlit`)
  - `ios/Runner.xcodeproj/project.pbxproj` (all 3 app configs + RunnerTests)
  - `ios/Runner/Info.plist` (`CFBundleURLName`)
- **iOS `NSCameraUsageDescription`** added (fixes guaranteed camera-tab crash + reject).
- **Android `CAMERA`** permission declared explicitly in `AndroidManifest.xml`.
- **Release signing** now reads `android/key.properties` (git-ignored); falls back
  to debug only when absent. See `android/key.properties.example`.
  - Added `ndk { abiFilters = arm64-v8a, armeabi-v7a }` to trim native libs.
  - Added `android/app/proguard-rules.pro` (keep rules) for when R8 is enabled.
- **HUGGINGFACE_TOKEN removed from the client bundle:** dropped from `build.sh`,
  `.github/workflows/deploy-pages.yml`, `.env.example`, and `main.dart`
  (`initializeFlutterGemma()` now passes no token). Only the client-safe
  `SUPABASE_URL`/`SUPABASE_ANON_KEY` remain in `.env`.
- **`.gitignore`** now also excludes `key.properties`, `*.jks`, `*.keystore`.
- **iOS `Runner.entitlements`** scaffolded (Sign in with Apple) — must be wired in
  Xcode (see §3).

### Launch-critical — fixed
- **Global error handling** in `main.dart`: `runZonedGuarded` + `FlutterError.onError`
  + `PlatformDispatcher.onError` + a branded `ErrorWidget.builder`, all routed to a
  new `lib/core/observability/error_reporter.dart` sink (ready to forward to Sentry).
- **Android Back no longer exits the app from any tab** — `HomeScreen` is wrapped in
  `PopScope`; Back returns to the Scan tab first.

### Account deletion — implemented end-to-end (store blocker)
- **Edge function** `supabase/functions/delete-account/` (verifies JWT → deletes
  avatar objects → `auth.admin.deleteUser` with cascade). Has a README.
- **Dart chain** (codegen-free): `AuthRepository.deleteAccount` →
  `AuthRepositoryImpl` → `SupabaseAuthDatasource(.Impl)` (invokes the function +
  signs out) → new `DeleteAccount` use case → `AuthNotifier.deleteAccount()`.
- **UI wired with a confirm dialog** at both entry points (the "soon" stubs are
  gone): `settings/danger_section.dart` and `settings/profile_management_section.dart`.

### High-ROI features — service scaffolds added
- `lib/core/audio/tts_service.dart` (`flutter_tts`, `fil-PH`) + `ttsServiceProvider`.
- `lib/core/feedback/review_service.dart` (`in_app_review`) + `reviewServiceProvider`.
- New deps added to `pubspec.yaml`: `flutter_tts`, `in_app_review`,
  `flutter_secure_storage`, `connectivity_plus`, `cached_network_image`.

### Landing site
- New **private** repo `KpG782/kudlit-landing` (Next.js + Tailwind) with the
  store-required `/privacy`, `/terms`, `/support`, and **`/delete-account`** pages.

---

## 2. ✅ Verification checklist (run when you have the toolchain)

- [ ] `flutter pub get`
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] `flutter analyze` (expect to fix small things in the new Dart — it was not
      compile-checked)
- [ ] `flutter test`
- [ ] `flutter build appbundle --release` (with `key.properties` present)
- [ ] Smoke-test: Settings → Delete account (against a deployed `delete-account` fn)
- [ ] Smoke-test: Back button on Translate/Learn/Butty returns to Scan, doesn't exit

---

## 3. 🔑 Needs YOUR input before shipping (cannot be done from code)

1. **Android upload keystore** — create it and add `android/key.properties`
   (template provided). Enroll in **Play App Signing**.
2. **Apple Developer Team** — set `DEVELOPMENT_TEAM` in Xcode, enable automatic
   signing, and add the **Sign in with Apple** capability (uses the scaffolded
   `Runner.entitlements`).
3. **Deploy the delete-account function** — `supabase functions deploy delete-account`.
   Confirm every app table is `references auth.users(id) on delete cascade`.
4. **Crash reporter DSN** — add `sentry_flutter` (or Crashlytics), initialize in
   `main()`, and forward the calls in `error_reporter.dart`. (Hooks are already in.)
5. **Buy `kudlit.app` + DNS** — point it at the landing host (Vercel recommended for
   Next.js; the repo is private so GitHub Pages would need Pro). Update OAuth/redirect
   allow-lists and any hard-coded URLs to the final domain.
6. **Rotate the old Hugging Face token** (it previously shipped in builds) and move
   gated model downloads to a server-minted signed URL or a public bucket.
7. **Pin `targetSdk`/`compileSdk`** to the current Play minimum and run Google's
   **16 KB page-size** check on the release AAB (both are *verify-current* values).
8. **Store listings** — adaptive Android icon (run `flutter_launcher_icons`),
   feature graphic, screenshots, descriptions, Data Safety form, App Privacy labels.

---

## 4. ⏸️ DEFERRED — Apple & Google Sign-In blockers (per your instruction)

These were intentionally **not** done in this pass. Each must be handled before
(or as part of) store submission:

1. 🚫 **Sign in with Apple is required (Apple Guideline 4.8)** because the app
   offers Google sign-in. To do: add `sign_in_with_apple`, add Supabase
   `OAuthProvider.apple`, add an iOS-only Apple button, configure the Apple
   provider in Supabase, and enable the SIWA capability (entitlement scaffolded).
2. 🚫 **Google Sign-In config under the new bundle ID `app.kudlit`** — the bundle ID
   change means you must update the Google Cloud OAuth client(s) (iOS + Android +
   Web), SHA-1/SHA-256 fingerprints for the new release keystore, the
   `GoogleService`/OAuth redirect URIs, and the Supabase Google provider's allowed
   redirect list. Verify `kudlit://auth/reset` and the web origin are allow-listed.
3. ⚠️ **Apple provider redirect** — when SIWA is added, register its return URL in
   Supabase and ensure the `kudlit://` scheme / Associated Domains are configured.
4. ⚠️ **Email verification deep link** — `signUpWithEmail` still passes no
   `emailRedirectTo`; set it so confirm links reopen the app (related auth gap).

---

## 5. 🧩 Recommended features — wired vs. to-wire

| Feature | Status | To finish |
|---|---|---|
| TTS pronunciation | Service + provider added | Add a tap-to-hear button on character gallery, translate output, quiz answers via `ref.read(ttsServiceProvider).speak(text)` |
| In-app review | Service + provider added | Call `ref.read(reviewServiceProvider).maybeRequestReview()` after a delight moment (lesson complete / good scan / streak) |
| Secure session storage | Dep added (`flutter_secure_storage`) | Pass a Keychain/Keystore-backed `LocalStorage` to `Supabase.initialize` (API is supabase_flutter-version-specific — verify) |
| Local streak persistence | Not started | Cache streak in SharedPreferences in `streak_provider.dart`; compute from local completions; never hard-reset to 0 on network error/guest |
| Name-in-Baybayin generator | Not started | New screen + route reusing the existing transliterate logic + `export_sheet.dart` share card |
| Network timeouts | Not started | `.timeout(Duration(seconds: 30))` on `functions.invoke` + model-download streams |
| Dead a11y toggles | Not started | Gate animations on Reduced Motion + add a High-Contrast theme variant (currently stored but inert) |
| Adaptive Android icon | Not started | `flutter_launcher_icons` config + run |

See the main audit report for full rationale and `file:line` evidence.

---

## 6. ✅ Implemented in the follow-up pass (2026-06-26, batches 2–4)

Now done + pushed: **InferenceGate** (on-device Gemma serialization), **network
timeouts** (gemini-proxy 30s; YOLO download 30s connect + 60s stall), **Sentry**
crash reporting (gated by `--dart-define=SENTRY_DSN`), **streak local
persistence**, **signed-AAB release CI** (`.github/workflows/release-android.yml`)
with obfuscation + symbol upload, **adaptive-icon config**, plus the earlier
account-deletion flow, crash hooks, `PopScope`, and the UX pass (retryable error
states, TTS "Listen" button, lesson-complete review prompt).

## 7. ⏸️ Deliberately documented (not committed) — needs the toolchain to verify

Two items were intentionally **not** committed blind because they're on fragile
critical paths and this environment has no Flutter compiler to verify them. Paste
these in and run `flutter analyze` to confirm.

### Secure session storage (auth critical path)
A wrong `LocalStorage` signature breaks the whole build, and wrong behavior
silently logs users out — so verify against your `supabase_flutter` 2.8.x.

```dart
// lib/core/auth/secure_local_storage.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage();
  static const String _key = 'supabase.session';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    final String? raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      final Object? t = m['access_token'] ??
          (m['currentSession'] as Map<String, dynamic>?)?['access_token'];
      return t is String ? t : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<void> persistSession(String s) => _storage.write(key: _key, value: s);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
```
Then in `main.dart`:
```dart
await Supabase.initialize(
  url: SupabaseConfig.url,
  anonKey: SupabaseConfig.anonKey,
  authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
);
```

### High-contrast theme + reduced-motion (currently inert toggles)
The `highContrast`/`reducedMotion` prefs live in the **profile-prefs** provider,
not the theme-driving `AppPreferences`. Two clean options:
1. **Recommended:** add `highContrast`/`reducedMotion` to `AppPreferences`
   (`app_preferences_provider.dart`) — the provider `app.dart` already watches —
   add `KudlitTheme.highContrastLight/Dark` variants, and migrate the settings
   toggles to write that provider. Then in `app.dart` pick the high-contrast
   theme when the flag is set, and gate `.animate()` chains on
   `MediaQuery.disableAnimationsOf(context) || prefs.reducedMotion`.
2. Or have `app.dart` also watch the existing profile-prefs provider (note it may
   be async/auth-gated → guard for theme flicker).

---

## 8. Remaining scanner/native items — ready-to-implement specs

These are the only UX-state items not committed, because they touch native
camera/permission behavior (which can't be verified without a device and could
regress the working `YOLOView` scanner) or need cross-widget threading. Each is
fully specified below so it can be dropped in during a toolchain-in-the-loop pass.

### 8.1 Native camera-permission-denied panel
`ScannerCamera` renders `YOLOView` directly once the model path resolves
(`scanner_camera.dart:357-369`); a native denial yields a black view with no
guidance. Add `permission_handler: ^11.3.1` to pubspec, then:
```dart
// before building YOLOView (native only):
final PermissionStatus status = await Permission.camera.status;
if (status.isDenied) {
  final PermissionStatus req = await Permission.camera.request();
  if (!req.isGranted) return _CameraPermissionPanel(
    permanentlyDenied: req.isPermanentlyDenied,
    onOpenSettings: openAppSettings,            // from permission_handler
    onRetry: () => ref.invalidate(/* the gate provider */),
  );
}
```
`_CameraPermissionPanel`: Butty illustration + "Kudlit needs camera access to
scan Baybayin." + an "Open settings" button (when permanently denied) or "Allow
camera". **Verify on a device** that this doesn't double-prompt with
`ultralytics_yolo`'s own request.

### 8.2 Native no-camera / init-failure boundary
Web already handles `cameras.isEmpty` (`scanner_camera.dart:456-462`). For
native, wrap the `YOLOView` mount in a try/error path and, on bind failure,
surface a `ScanNotice` ("No camera available — use Gallery instead") with the
existing gallery action. Reuse `_noticeForCaptureError` styling.

### 8.3 ModelNotSupportedScreen → "Try Gallery"
`ModelNotSupportedScreen` (`model_not_supported_screen.dart:36-74`) is a
dead-end. Add an `onTryGallery` callback param and a `FilledButton('Try Gallery
instead')`; thread the callback from `ScannerCamera` (where it's shown,
`scanner_camera.dart:331-334`) up to `scan_tab.dart`, which already owns the
gallery-pick flow (`scanTabControllerProvider` still-image path). Gallery
scanning works without the live camera, so unsupported devices stay usable.

### 8.4 Live "frame a glyph" hint
When the camera is live and `aggregatedWinner == null` (`scan_tab.dart:445-463`),
show a subtle centered hint ("Frame a Baybayin glyph") after ~1.5s idle. Gate on
a `Timer` reset by each detection so it only appears when nothing is detected;
hide it the moment a winner appears. Keep it low-opacity so it doesn't fight the
camera feed.

