# Sprint 2 Handoff — Read Me First

> **This file covers Sprint-2-specific onboarding.** For the general
> Git workflow, commit conventions, branch naming, and Definition of
> Done, read **`CONTRIBUTING.md`** — that is the authoritative
> source. This file adds **3 things** on top:
>
> 1. The `.env` onboarding trap (Section 1)
> 2. How to drive your AI assistant productively (Section 2)
> 3. Sprint-2-only scope and tracking (Sections 3–4)

---

## 1. One-time setup (after `git clone`)

⚠️ **Without this step, the web build is a blank page and the
Android build crashes on first Supabase upload.** This is the #1
reason a teammate cannot run the app locally.

1. **Get the `.env` from Faiz via private DM** (NOT WhatsApp group —
   the file contains the Supabase anon key). Drop it at
   `strayfriends/.env` (next to `pubspec.yaml`).
2. `cd strayfriends && flutter pub get`
3. Verify Android emulator: `flutter run` (or `-d emulator-5554`)
4. Verify Chrome: `flutter run -d chrome`
5. If either fails, **stop and DM Faiz a screenshot of the
   terminal**. Don't `flutter clean` repeatedly or rewrite files
   trying to "fix" it — the failure mode is usually missing `.env`
   or a wrong Flutter SDK version, not a code bug.

> Flutter SDK target: `sdk: ^3.11.4` (per `pubspec.yaml`). If your
> `flutter --version` reports an older Dart SDK, run
> `flutter upgrade` first.

---

## 2. Working with your AI assistant

Everyone on the team is using AI (ChatGPT, Claude, Cursor, etc.) to
help write code. To keep the codebase coherent across 5 people, you
**must** give your AI the same context every session.

### 2.1 Required context to paste/upload to your AI

Always feed these **before** describing your ticket:

| File (in this repo) | Why |
|---|---|
| `CLAUDE.md` (root) | Project rules, rubric, team |
| `docs/CONTRIBUTING.md` | Git workflow + commit rules + anti-patterns |
| `docs/BACKLOG.md` | Full story list with ACs |
| `docs/DESIGN.md` | UI tokens, colors, components |
| `docs/SPRINT2_HANDOFF.md` | This file |

### 2.2 Codebase context (pick whichever applies to your ticket)

Your AI **cannot guess** how the codebase is wired. Paste the
relevant existing files as reference so the AI matches the pattern
instead of inventing a new one.

| If you are working on... | Paste these files first |
|---|---|
| Anything UI | `lib/core/theme/app_colors.dart`, `app_text.dart`, `app_spacing.dart` |
| A new screen / route | `lib/core/router/app_router.dart`, plus one similar existing screen |
| Anything reading config / keys | `lib/core/env.dart` |
| A new Firestore feature | one existing service from `lib/features/reporting/` |
| Anything with photos / Supabase storage | the photo-upload code path in `lib/features/reporting/` |

> **Strongest recommendation:** use Claude Code or Cursor running on
> your local clone — it reads the codebase automatically. If you
> stick with a web chat (ChatGPT, Claude.ai), you'll be copy-pasting
> a lot. That's fine, just be disciplined about it.

### 2.3 Hard rules to paste at the start of every AI session

Copy this verbatim into your AI prompt:

```
Hard rules for this Strayfriends codebase:
1. Do NOT install new dependencies without telling me first.
2. Do NOT run flutter clean, git push, git commit, or any
   destructive command. I will run all Git commands myself.
3. Do NOT create files outside lib/features/<my-feature>/ unless
   you ask first.
4. Match the existing patterns in app_colors.dart, app_router.dart,
   env.dart — do not invent new conventions.
5. Cite the Jira ticket ID (NAD-N) in every suggestion.
6. Don't reintroduce Sprint 1 anti-patterns (see
   docs/CONTRIBUTING.md §8 — BR-001..006).
```

---

## 3. Sprint 2 scope

- **Module:** Fundraising
- **Owner (epic):** Faiz (`NAD-E3`)
- **Target release:** **v0.2.0** on **23 April 2026**
- **Your assigned tickets:** check the **NAD** board on Jira →
  Sprint 2 backlog. The Use Case IDs (UC-XX) for your stories live
  inside the Jira ticket description and in `docs/BACKLOG.md`.

> ⚠️ **Don't guess your UC range.** Pull it from Jira at sprint
> start and confirm with Baqir (PM) before you start writing test
> cases. The numbers in `BACKLOG.md` are planning labels and may
> not match the live Jira IDs.

Faiz will tag **v0.2.0** on `main` once every Sprint 2 ticket is in
the **Done** column on Jira **and** every PR is merged. Do not tag
your own commits.

---

## 4. Testing — every developer is also a tester

You don't have to wait for QA to test your own work. During or
right after building your feature, fill in your test cases using
**`docs/TEST_NOTES_TEMPLATE.md`**.

Where to write them:

1. On day 1 of Sprint 2, **one person** copies
   `docs/TEST_NOTES_TEMPLATE.md` → `docs/TEST_NOTES_sprint2.md`
2. Each developer appends their rows to that single shared file
3. Khalisha (QA) consolidates everything into the official Sprint 2
   TRD at the end of the sprint

If you find a bug while testing, **do not fix it silently**. Add a
row with `Actual Result = <what broke>` + severity, and create a
follow-up Jira ticket if it's blocking. We need the paper trail for
the rubric.

---

## 5. When to escalate to Faiz

Stop and DM Faiz immediately if:

- The app won't build after a fresh `flutter pub get`
- Your AI is suggesting changes to files in `lib/core/` (theme,
  router, env) — those are shared and risky
- You hit a Firestore Security Rules denial
- You hit a Supabase RLS denial on photo upload
- Your branch has > 5 conflicts with `main`
- Your AI is proposing a new dependency
- Anything touching `firebase_options.dart` or `.env`

Default rule: if you'd hesitate to merge it yourself, ask.

---

**Last updated:** 2026-05-18 · Maintained by Faiz (Lead Dev) ·
For Git workflow + DoD see `docs/CONTRIBUTING.md`.
