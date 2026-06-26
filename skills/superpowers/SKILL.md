---
name: superpowers
description: Process discipline for shipping high-quality software — brainstorm, plan to a file, implement in small verified steps, test-first where practical, verify by running, then review. Use for any non-trivial feature, refactor, bug fix, or audit in this repo.
user-invocable: true
---

# Superpowers (process skill)

Adapted from the obra/superpowers methodology for this repo. Use this for *process*;
use `ui-ux-promax` and `flutter-frontend` for execution.

## The loop
1. **Brainstorm** — restate the goal, list options, name trade-offs, pick an approach. Ask before assuming when a choice changes the outcome.
2. **Plan to a file** — write a short plan (steps, files touched, risks, acceptance criteria) to `docs/` before large work. A plan you can review beats one in your head.
3. **Decompose** — smallest valuable steps; one logical change per commit; conventional commit prefixes (`feat:`/`fix:`/`refactor:`/`docs:`…).
4. **Test-first where practical** — for domain logic + use cases, write/extend tests first (`test/`); keep the `domain` layer pure Dart.
5. **Implement** — match surrounding code; reuse design-system tokens; keep `build()` < 40 lines; explicit types, single quotes.
6. **Verify by running** — `flutter analyze` (zero issues) → `flutter test` → run the app / golden checks. Never claim done without verification; if a step was skipped, say so.
7. **Review** — re-read the diff for correctness, reuse/simplification, accessibility, and security before pushing.

## Defaults & guardrails
- **Branch off `dev`**; never push to `main` without explicit permission.
- **Run the linter before committing** (`flutter analyze`) and resolve all issues.
- **Root-cause over patch** — when debugging, find *why* it broke, not just a symptom mask.
- **Defense in depth** — validate on the client *and* server (RLS / Edge Functions); never trust the client.
- **Report faithfully** — failing tests, skipped steps, and unverified code are stated plainly.
- **Subagents for breadth** — fan out parallel agents for audits/research/multi-file sweeps; keep the conclusion, not the file dumps.

## Acceptance for "production-ready"
Crash reporting wired · global error handling · no secrets in the bundle · account
deletion (in-app + web URL) · secure token storage · timeouts/retries on network ·
every screen has loading/empty/error states · analytics on the core funnel · CI builds
a signed AAB/IPA with symbol upload · staged rollout + rollback.
