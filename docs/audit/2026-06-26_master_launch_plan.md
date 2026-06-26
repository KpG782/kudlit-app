# Kudlit — Master Launch Plan (verify → ship → make it a hit)

**Date:** 2026-06-26 · Consolidates the audit, deployment-hardening, UX-state, production/portfolio, and virality docs into **one gated, phased plan**. The order is deliberate: **prove it works → clear store blockers → polish → make it spreadable → launch & amplify.** You do not skip a gate.

---

## 0. Honest current status (read this first)

**Foundation is laid and code-reviewed — but NOT compile-verified.** This environment has no Flutter/Dart toolchain (clone blocked by the proxy), so every Dart change was written + adversarially static-reviewed, never `flutter analyze`'d or run. Treat the whole branch as **"reviewed, pending verification."**

What's **done in code** (branch `claude/app-store-readiness-audit-72i1jv`): bundle ID `app.kudlit`, camera perms, release-signing scaffold, secrets removed from bundle, crash hooks + Sentry wiring, network timeouts, on-device Gemma `InferenceGate`, streak persistence, account-deletion flow + Edge function, release CI, and a full UX-state pass (friendly/retry error states, empty/loading states, sign-out confirm, settings stubs wired, profile error-surfacing).

What's **specified but not built**: §8 native scanner items + secure token storage + high-contrast wiring (in the deployment-followups doc); the virality features (in the virality doc).

What needs **you** (can't be done from here): a real signing keystore, an Apple Developer team, deploying the Edge function, a Sentry DSN, buying `kudlit.app`, and **running the app**.

> **The single most important sentence in this plan:** nothing below "Phase 1" matters until **Phase 0** passes, because you cannot make an unverified app a hit.

---

## Guiding principle: gates, not vibes

Each phase has an **entry condition**, an **exit gate (definition of done)**, an **owner**, and the **top risk**. A phase is not "done" because the work happened — it's done when the gate is green. Don't build virality (Phase 3+) on top of an unverified base (Phase 0).

---

## Phase 0 — Make it provably work ✅ (the verification gate)
**Goal:** the app compiles, analyzes clean, tests pass, and the critical paths work on a real device. **This is the gate the whole project currently sits behind.**

**Owner:** you (you have Flutter) — or me, given an environment with `flutter` on PATH.

**Steps**
1. `flutter pub get` (6 new deps resolve).
2. `dart run build_runner build --delete-conflicting-outputs` (materialize `.g.dart`).
3. `flutter analyze` → **zero issues** (fix anything; ping me with the output and I'll clear it).
4. `flutter test` → green.
5. Smoke-test on a real Android device + one iOS device: launch, guest path, scan, translate (incl. AI failure + offline), Butty chat, a lesson + quiz, settings (sign-out confirm, **account deletion against a deployed Edge fn**), history screens (error → retry).

**Exit gate:** analyze clean · tests pass · a signed debug/release build runs · the 6 critical flows work on device · no raw-error screens · account deletion actually deletes.

**Top risk:** unverified Dart has a small error somewhere → `analyze` catches it; trivial to fix. (The release CI runs steps 1–4 automatically on a `v*` tag — that's your fastest green/red signal.)

---

## Phase 1 — Store-submittable (clear the blockers)
**Entry:** Phase 0 green.
**Goal:** both store consoles accept a build to an internal/TestFlight track.

**Steps**
- **Identity & signing:** create the upload keystore + `android/key.properties`; set Apple `DEVELOPMENT_TEAM` + automatic signing (bundle ID is already `app.kudlit`).
- **Auth blockers (deferred earlier):** add **Sign in with Apple** (Apple 4.8); reconfigure **Google OAuth** for `app.kudlit` (new clients + release SHA-1/256 + Supabase redirect allow-list); set `emailRedirectTo` on sign-up.
- **Account deletion:** `supabase functions deploy delete-account`; confirm tables cascade.
- **Web/legal URLs:** buy `kudlit.app`, deploy the `kudlit-landing` site, point DNS — this provides the required Privacy / Support / **/delete-account** URLs.
- **Store config:** pin `targetSdk`/`compileSdk` to Play's current minimum (**verify current**); run the **16 KB page-size** check on the AAB (**verify current**); generate the adaptive icon (`dart run flutter_launcher_icons`).
- **Listings:** complete **Data Safety** (Play) + **App Privacy** (Apple) accurately; feature graphic, screenshots, localized (EN + Filipino) descriptions.

**Exit gate:** a signed AAB + iOS archive upload successfully to internal/TestFlight; both privacy forms submitted; all required URLs live.

**Top risk:** the Apple/Google auth reconfig — budget real time; it's fiddly and blocks iOS especially.

---

## Phase 2 — "Don't embarrass us" quality (polish + observability live)
**Entry:** Phase 1 green (build is in testers' hands).
**Goal:** clean, accessible, observable — no rough edges a reviewer or first user will hit.

**Steps**
- Implement the **§8 native scanner items** (camera-permission panel, no-camera boundary, ModelNotSupported→Gallery, live-glyph hint) — now you have a device to verify.
- **Secure token storage** (flutter_secure_storage, specced) + **high-contrast / reduced-motion** wiring.
- **Crash reporting live** (set `SENTRY_DSN`) + **analytics** on the core funnel behind a consent gate.
- Run on a **device matrix**; fix crashes/jank; confirm dark mode + Dynamic Type.

**Exit gate:** crash-free sessions healthy on the matrix · all four states on every screen · a11y toggles actually work · analytics + crash data flowing.

**Top risk:** native camera-permission double-prompt with `ultralytics_yolo` — verify on device.

---

## Phase 3 — Make it spreadable (the viral loop)
**Entry:** Phase 2 green (the app is solid and instrumented).
**Goal:** a working, measurable viral loop — *the* prerequisite for "a hit."

**Steps (the 1-week sprint from the virality doc)**
- **Name-in-Baybayin first-run hero** wired to the existing `export_sheet.dart` share card.
- **Attribution + referral link + `kudlit.app` watermark on every share** (today the loop leaks — no attribution).
- **Share CTAs** on streak-milestone + lesson-complete moments.
- **Instrument share-rate + k-factor + time-to-first-share.**

**Exit gate:** a user can go install → name → share with an attributed link in <1 min; share-rate + k-factor are measured.

**Top risk:** shipping shares with no attribution (loop leaks) — make attribution non-negotiable in this phase.

---

## Phase 4 — The breakout content engine (the 10x)
**Entry:** Phase 3 green (loop works, you can see share-rate).
**Goal:** content that spreads on its own.

**Steps**
- **Stroke-by-stroke name VIDEO export** (vertical, TikTok/Reels) using `StrokePattern`/`TimedPoint` — the 10x bet.
- **Tattoo / wall-art design mode** (real search demand + monetization).
- (Later) **Living Script** personal handwriting font — the long-term moat.

**Exit gate:** a shareable vertical video that looks good unedited; tattoo art is typographically correct.

**Top risk:** video render quality/perf — prototype the renderer early; keep clips short.

---

## Phase 5 — Launch & amplify (make it a hit)
**Entry:** Phases 3–4 green (spreadable + breakout content).
**Goal:** distribution + momentum.

**Steps**
- **Staged rollout** (Play %), TestFlight → production; remote kill-switch ready.
- **Seed content** in Filipino/diaspora + language-learning + tattoo communities; post the name-video format on TikTok/Reels yourself first.
- **ASO:** localized (EN + Filipino) title/subtitle/keywords ("Baybayin", "Alibata", "Filipino script", "name in Baybayin", "Baybayin translate"), captioned screenshots, a preview video (use the stroke animation).
- **In-app review** prompts at delight moments (already wired) → ratings velocity.
- **PR angle:** "on-device AI reviving an endangered ancestral script" — pitch heritage + tech press; tie to Buwan ng Wika / Independence Day moments.
- **Iterate weekly on share-rate** — double down on whatever format spreads.

**Exit gate (definition of "a hit"):** k-factor trending toward/above ~0.5 in a target community · D7 retention at/above category norm · ratings velocity climbing · at least one organic content format breaking out.

**Top risk:** launching before the loop is instrumented — you won't know what's working. (That's why Phase 3 gates this.)

---

## How we'll know it's a hit (instrument in Phase 2/3, watch from launch)
- **Share rate** = shares ÷ active users (the virality KPI).
- **k-factor** = referral installs ÷ sharers (>0.5 = real word-of-mouth; >1 = exponential).
- **Time-to-first-share** (target: first session).
- **Activation → D1/D7 retention** (does the hook convert to a habit?).
- **Ratings velocity + crash-free %** (store health gates featuring).

---

## The critical path (what to do first, in order)
1. **Phase 0** — run `flutter analyze`/`test`; tell me what it says; I clear anything it flags. *(Nothing else matters until this is green.)*
2. **Phase 1** — keystore + Apple team + deploy Edge fn + buy/deploy `kudlit.app` + auth reconfig → first internal build in testers' hands.
3. **Phase 3 sprint** — the spreadability wiring (cheapest path to a working viral loop).
4. **Phase 4** — the name-video engine (the breakout).
5. **Phase 5** — staged launch + seed + ASO + PR.

> Phases 2 and 4 can overlap once Phase 1 ships an internal build; Phases 3→5 are the "hit" engine and must sit on a verified, store-accepted base.
