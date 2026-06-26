# Kudlit — Virality & "Make It Famous" Strategy

**Date:** 2026-06-26 · Companion to the production/portfolio upgrade plan. Lens here is narrow on purpose: **what makes Kudlit spread and get famous once deployed**, grounded in infra that already exists in the repo (so most of it is wiring, not greenfield).

---

## 1. The fame thesis

> **Kudlit isn't a learning app that happens to be shareable — it's a "see your identity in your ancestors' script" machine that happens to teach.**

Niche cultural apps don't go famous by adding features; they go famous by producing **identity-driven artifacts people want to post.** Baybayin is uniquely suited to this: it's an *ancestral Filipino script*, and "my name / my words in our ancestors' writing" is a deeply resonant, infinitely repeatable, shareable moment for ~115M Filipinos + a huge diaspora.

Every Kudlit output should pass one test: **would someone screenshot/share this?**

---

## 2. The shareable infra already exists (why this is cheap)

| Asset in repo | What it gives us for free |
|---|---|
| `lib/features/home/presentation/widgets/translate/export_sheet.dart` | Branded, multi-theme **PNG share card** (Baybayin glyph + Butty + watermark) via `share_plus` — a ready-made viral surface |
| transliterator (translate feature) | Filipino ↔ Baybayin conversion (the engine behind "your name") |
| `lib/features/admin/.../stroke_pattern.dart` + `timed_point.dart` | **Stroke-order + timing data** — the raw material for animated "name reveal" videos and a personal handwriting font |
| `lib/core/audio/tts_service.dart` (added) | Pronunciation — a second shareable dimension (audio) |
| on-device Gemma + YOLO OCR | Privacy/offline AI angle + live camera reading (AR demo) |
| persisted streaks + Butty memory | Retention loops + personalization |

The point: the **viral features below mostly reuse `export_sheet.dart` + the transliterator + stroke data** — low effort, high ceiling.

---

## 3. Highest-virality features (ranked)

| # | Feature | Why it goes viral | Reuses | Effort | Store caveat |
|---|---|---|---|---|---|
| 1 | **"Your name in Baybayin" as the first-run hero** (not a buried chat tip) | The single most-wanted Baybayin moment; instant identity hook; works for every user on day one | transliterator + `export_sheet.dart` | **S–M** | none |
| 2 | **Stroke-by-stroke "name reveal" VIDEO export** (vertical, TikTok/Reels) | Short-form auto-generated reels are *the* 2026 virality format; a name being written glyph-by-glyph is mesmerizing and re-postable | `StrokePattern`/`TimedPoint` + a renderer + `share_plus` | **M–L** | none (own content) |
| 3 | **Baybayin tattoo / wall-art design mode** | Baybayin tattoos are a real, persistent search trend; people actively want clean, *correct* name art for ink/prints | transliterator + export with style presets | **M** | physical prints → external payment OK; digital style packs → IAP |
| 4 | **"Living Script" — your handwriting becomes a personal Baybayin font** | Genuinely novel (no competitor does it); earned-through-practice + your own hand = identity moat; every share is unique | `StrokePattern`/`TimedPoint` + export | **L (assembly)** | none |
| 5 | **AR live-scan overlay** ("point at any Baybayin, read it live") | The press/PR "heritage-meets-tech" demo shot | YOLO OCR + camera | **L** | camera perms (specced in followups §8) |
| 6 | **Shareable streak / milestone cards** | Loss-aversion + social proof (Duolingo's engine); turns dopamine into distribution | persisted streaks + `export_sheet.dart` | **S** | none |
| 7 | **"Hear your name"** pronunciation | Multimodal + accessible; adds audio as a shareable layer | `TtsService` | **S** | none |

---

## 4. The single 10x bet — **name → stroke-by-stroke vertical video**

Image cards get likes; **a 5–8s clip of your name being written in Baybayin, with the sound, lightly branded** gets *shares and installs.* It turns Kudlit into a content engine that feeds TikTok/Reels — exactly how niche cultural apps actually break out in 2026.

You already have the two hard pieces: **stroke-timing data** (`TimedPoint`) and an **export pipeline**. The work is a frame renderer (paint strokes over time → encode) + a vertical template. **Effort: M–L**, but it's assembly of existing parts, and it's the highest-ceiling differentiator you have.

---

## 5. Amplify EXISTING features for reach (cheap, do first)

- **Bake an install/referral link + `kudlit.app` watermark into every shared card.** Today `export_sheet` shares content with **no attribution** → the viral loop leaks. One change, compounding return.
- **Move "Continue as guest → type your name" to the very first screen.** Deliver the wow in <10 seconds; don't gate the hook behind sign-up.
- **Add a "Share" CTA to lesson-complete + streak-milestone moments** (reuse `export_sheet.dart`).
- **Wire the TTS buttons everywhere** (gallery, quiz, translate) so "hear it" is always one tap.
- **Smart App Banner / deep link** on the landing page so web shares convert to installs.

---

## 6. The "make it spreadable" sprint (≈1 week, no new infra)

1. **Name-in-Baybayin first-run hero** wired to the existing share card. *(S–M)*
2. **Attribution + referral link baked into every share.** *(S)*
3. **Share CTAs on streak milestones + lesson complete.** *(S)*

This trio makes the app *spreadable* purely by wiring `export_sheet.dart` into more moments — no new systems.

---

## 7. Store-safe monetization (so fame can pay)

- Free core + shareables (keeps the loop frictionless).
- **"Kudlit Pro"** (subscription via **Apple IAP / Google Play Billing only**): premium art/style packs, the Living-Script font export, cloud AI roleplay, advanced lessons.
- **Physical** Baybayin prints/merch *may* use external payment (Apple 3.1.1 / Google: digital goods must use platform billing; physical goods may not).
- Avoid ads in an education/cultural app (brand + data-policy risk).
- UGC/community features trigger Apple 1.2 / Google UGC moderation rules — defer until there's a moderation + report/block path.

---

## 8. Make "famous" measurable (instrument before launch)

Wire these into the analytics layer (still to be added — see production plan):
- **Share rate** = shares ÷ active users (the virality KPI).
- **k-factor** = installs attributed to referral links ÷ sharers.
- **Time-to-first-share** (target: first session).
- Activation (name generated / first scan) → D1/D7 retention → share.

If share-rate and k-factor aren't instrumented, you can't tell what's working — wire them with the first analytics drop.

---

## 9. Recommended sequence

1. **Sprint §6** (spreadability wiring) — cheapest path to a working viral loop.
2. **Tattoo/wall-art mode** (#3) — real demand, real monetization, reuses export.
3. **Stroke-by-stroke name video** (#2 / the 10x bet) — the breakout content engine.
4. **Living Script** (#4) — the long-term moat.

AR overlay (#5) is the best *press* asset but the most effort + needs device work — schedule it when the toolchain's in the loop.
