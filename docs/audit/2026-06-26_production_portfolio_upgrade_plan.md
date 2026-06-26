# Kudlit — Production & Portfolio Upgrade Plan (trend-backed)

**Date:** 2026-06-26
**Method:** Produced with the repo's own process skills — **`/ui-ux-promax`** (UI/UX execution checklist) and **`/superpowers`** (brainstorm → plan → verify → review), now installed under `skills/` and `.claude/skills/`. Trends below are from live web research (sources at the end). Companion to the readiness audit + deployment-hardening docs of the same date.

> **Goal:** take Kudlit from "passes review" to **a real, production-grade app that stands out in a portfolio** — by aligning its genuinely unique angle (on-device AI + camera OCR for an *endangered ancestral script*) with where the market is going in 2026.

---

## 1. Where Kudlit stands now (post-hardening)

Already shipped this cycle (see `2026-06-26_deployment_changes_and_followups.md`): real bundle ID, camera permission, release signing scaffold, secrets removed from bundle, global crash/error hooks, account deletion (in-app + Edge fn), `PopScope`, TTS + in-app-review services, retryable error states, a "Listen" button, and a Next.js landing site with the legal/deletion URLs.

**The honest gap to "production":** no crash *reporter* wired (hooks exist, DSN doesn't), no analytics on the funnel, no mobile release CI, on-device Gemma concurrency unguarded, network calls have no timeouts, and several high-retention features (notifications, real streak persistence, true handwriting scoring) aren't built. None are hard — they're the difference between "demo" and "product."

---

## 2. 2026 trends → how Kudlit should apply them

The market signal is consistent: **AI personalization + on-device AI + calm, accessible, feedback-rich UX + gamified retention**, and for heritage apps specifically, **camera/AR + storytelling + pedagogy**. Kudlit is unusually well-positioned because it already *has* the hard parts (on-device Gemma, YOLO OCR, a mascot, a design system).

| 2026 trend (evidence) | How Kudlit applies it | Effort | Store caveat | Portfolio impact |
|---|---|---|---|---|
| **On-device AI is now production-ready** (Gemma 4, 1B-class models, <1.5GB, privacy/offline) | Lean into "your AI tutor runs *on your phone*, offline & private." Add an explicit **Offline AI** badge + a settings explainer; gate cloud vs local clearly. Fix the Gemma concurrency gate so it's reliable. | M | None | **High** — "offline on-device LLM tutor" is a standout 2026 resume line |
| **AI personalization / adaptive learning** (30–50% better outcomes vs static) | Use the existing Butty *memory facts* to drive an **adaptive review queue**: surface glyphs the user fails most; personalize the daily lesson. | M–L | None | High — shows ML product thinking, not just a chatbot |
| **Gamification: streaks, leagues, loss-aversion** (Duolingo: +36% DAU, churn ↓) | Make **streaks real + locally persisted** (currently remote-only, shows 0 for guests/offline). Add milestones, a monthly **streak-freeze**, XP, and a lightweight weekly goal. | M | None | High — the #1 retention lever; demonstrably "product," not toy |
| **Microinteractions & "alive" feedback** | Haptics on tab/toggle/submit (currently only Scan), spring transitions, skeletons over spinners, a celebratory glyph-mastery animation. | S–M | None | Medium — polish reviewers and recruiters feel instantly |
| **Calm, accessible, transparent UI** (a11y front-and-center; high-contrast, text resize, reduced-motion) | Wire the **dead Reduced-Motion + High-Contrast toggles** (they're stored but inert), honor `MediaQuery.disableAnimations`, fix the WCAG contrast misses (splash, AI pill, topbar). | M | A11y gaps are a soft review risk | High — accessibility is a credibility signal in a portfolio |
| **Camera/AR + storytelling for heritage scripts** (Baybayin named explicitly) | Evolve Scan from "detect glyph" to **AR overlay**: live romanization labels on the camera feed + a one-tap "Butty, explain this" with cultural notes. | L | Camera perms (done) | **Very high** — the demo-video money shot |
| **Voice UI / TTS + real-time speech** (live AI calls becoming standard) | TTS service is in (wire the buttons). Next: **pronunciation practice** — record the user saying a glyph's sound, score it. | M–L | Mic permission strings needed | High — multimodal learning |
| **Live AI roleplay / conversation** (Duolingo Max Video Call) | Butty already chats; add **guided conversation scenarios** in Tagalog that weave in Baybayin. | M | On-device free; cloud = cost (see monetization) | High |
| **Flutter 2026 consensus: feature-first + Clean Arch + Riverpod codegen + Crashlytics + Shorebird code-push** | You already nail the architecture — finish the prod-eng layer: Crashlytics/Sentry, analytics, a signed-AAB CI, and consider **Shorebird** OTA. | M | — | High — "shipped with observability + CI/CD" is what separates senior portfolios |

---

## 3. The portfolio thesis (the standout narrative)

> **"Kudlit revives an endangered ancestral script with an on-device AI tutor and a camera that reads Baybayin in real time — private, offline-first, and gamified."**

That single sentence hits **four** 2026 trends at once (on-device AI · AI personalization · camera/AR heritage · gamified retention) on a **culturally meaningful, non-generic** problem. For a portfolio, that beats "another Duolingo clone" or "another to-do app." Lead the case study with: the offline on-device LLM, the YOLO→TFLite OCR pipeline, the Clean Architecture + RLS security story, and the **"Living Script"** personal-handwriting-font idea as the signature wow.

---

## 4. Production-readiness blueprint (superpowers acceptance criteria → status)

| Criterion | Status | Action |
|---|---|---|
| No secrets in bundle | ✅ done | — |
| Account deletion (in-app + web URL) | ✅ done | deploy the Edge fn |
| Global error handling | ✅ hooks in | wire **Crashlytics/Sentry** DSN |
| Crash-free visibility | ❌ | add reporter (hooks ready) |
| Analytics on core funnel | ❌ | scan→detect→translate, lesson-complete, sign-in (behind consent) |
| Secure token storage | ❌ | `flutter_secure_storage` Keychain/Keystore |
| Network timeouts/retries | ❌ | `.timeout()` + `connectivity_plus` + backoff |
| On-device inference reliability | ❌ | implement the documented `InferenceGate` |
| Every screen loading/empty/error | 🟡 partial | finish skeletons + empty-state CTAs |
| Signed release CI (AAB/IPA) + symbols | ❌ | GitHub Actions + fastlane/upload-google-play; consider Shorebird OTA |
| Staged rollout + rollback | ❌ | Play staged rollout; remote kill-switch/feature flags |

---

## 5. Prioritized roadmap

### P0 — finish "production" (ship-grade)
1. Crash reporting (Sentry/Crashlytics) wired to the existing hooks.
2. `InferenceGate` for on-device Gemma; network timeouts + offline awareness.
3. Local streak persistence; wire the TTS buttons + in-app-review (services already added).
4. Mobile release CI → signed AAB + symbol upload.

### P1 — portfolio-grade polish (trend-aligned, high ROI)
5. Wire Reduced-Motion + High-Contrast; fix WCAG contrast misses; haptics everywhere.
6. Skeletons + designed empty-state CTAs across history/gallery/quiz.
7. Gamification: milestones, streak-freeze, weekly goal, XP.
8. Analytics + consent gate (make the existing toggle real).
9. Real i18n (English + Tagalog) — market fit + a11y.

### P2 — the "wow" that differentiates (demo-video features)
10. **AR Scan overlay** (live romanization on the camera feed + "explain this").
11. **Adaptive review queue** driven by Butty memory facts.
12. **Pronunciation practice** (record + score).
13. **"Living Script"** — earn a personal Baybayin handwriting font through practice, share as a branded card (reuses the stroke recorder + export sheet already in the repo).

---

## 6. Monetization (store-safe, for completeness)
Free core; a **"Kudlit Pro"** subscription for cloud AI roleplay + premium lesson packs + the Living Script export — **via Apple IAP / Google Play Billing only** (never an external/web checkout for digital goods: Apple 3.1.1 / Google Payments). On-device AI features are billing-neutral. Avoid ads in an education/cultural app.

---

## Sources
- [12 Mobile App UI/UX Design Trends 2026 — The Brands Bureau](https://thebrandsbureau.com/mobile-app-design-trends-2026/)
- [UX/UI trends 2026: calm interfaces, transparent AI — Envato](https://elements.envato.com/learn/ux-ui-design-trends)
- [Duolingo gamification explained — StriveCloud](https://www.strivecloud.io/blog/gamification-examples-boost-user-retention-duolingo)
- [Best AI Language Learning Apps 2026 — Upskillist](https://www.upskillist.com/blog/best-ai-language-learning-apps/)
- [Bring agentic skills to the edge with Gemma 4 — Google Developers](https://developers.googleblog.com/bring-state-of-the-art-agentic-skills-to-the-edge-with-gemma-4/)
- [Run an LLM on Your Phone (2026) — Local AI Master](https://localaimaster.com/blog/run-llm-on-phone)
- [A review of digitalization of endangered scripts (incl. Baybayin) — npj Heritage Science](https://www.nature.com/articles/s40494-026-02522-7)
- [Gamified AR for Cultural Heritage (CompARe) — ACM JOCCH](https://dl.acm.org/doi/10.1145/3703917)
- [Top Flutter Trends 2026 — ASAP Studio](https://asappstudio.com/top-flutter-trends-2026/)
- [Clean Architecture in Flutter 2026 — DEV](https://dev.to/techwithsam/clean-architecture-in-flutter-2026-practical-implementation-guide-1dfb)
