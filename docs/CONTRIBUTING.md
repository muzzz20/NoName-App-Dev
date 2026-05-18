# CONTRIBUTING.md — How to Contribute to Strayfriends

> **Audience:** anyone on the team who has finished `SETUP.md` and is
> ready to grab their first Jira issue.
>
> **Goal:** by the end of this guide, you know exactly how to take an
> issue from Jira "To Do" to "Done" without breaking anything for the
> rest of the team.
>
> **Read this once at the start of Sprint 2.** Re-skim at the start of
> Sprint 3 and Sprint 4 if conventions have evolved.

---

## 1. Quick reference (cheat sheet)

```
Sprint cadence:  Sprint planning Mon, Sprint demo + retro Fri (2-week sprints)
Branch naming:   nad-<issue-number>-<short-kebab-description>
Commit format:   NAD-<N>: <short description>      (or fix: / chore: / refactor:)
Before push:     flutter analyze (0 issues) + flutter test (all passing)
After merge:     Move Jira issue to Done; update docs if needed
Questions:       WA group (async) before pinging Lead Dev privately
```

---

## 2. Sprint cadence

| Day | What happens |
|---|---|
| **Monday week 1** | Sprint Planning — team meets, walks through Jira backlog, each member picks issues to grab |
| **Throughout the sprint** | Async work; status updates via WA group when blocking or unblocked |
| **Mid-sprint check-in (optional)** | Quick WA sync — anyone stuck, anyone idle, any scope changes |
| **Friday week 2** | Sprint Demo + Retrospective — show what's done; what went well / what didn't / what to change |
| **Friday week 2 (evening)** | Lead Developer compiles Sprint Report, updates SRDD Revision History, tags release in Jira |

**Important:** if you can't deliver something you committed to, **say so early**. A mid-sprint "I'm stuck on NAD-XX, can someone pair?" is far better than silence followed by missing it at demo.

---

## 3. The contribution loop (10-step workflow)

For every Jira issue you grab, follow these steps:

### Step 1 — Pick an issue

1. Open Jira (https://noname1.atlassian.net) → NAD board → **Sprint 2 / 3 / 4** sprint backlog
2. Pick a `To Do` issue assigned to **you** (or unassigned but in your area of expertise)
3. Click into it, read:
   - Description (the "what")
   - Acceptance Criteria (the "done" definition)
   - Linked issues (dependencies)
   - Comments (any context from Sprint Planning)

If the AC is unclear, **don't start coding**. Comment on the Jira issue asking the question, or raise it in WA. Avoid starting work based on guesses — half-done work that misses the AC gets reverted.

### Step 2 — Assign and move to In Progress

In Jira:

1. Set yourself as the **Assignee**
2. Drag the issue from **To Do** → **In Progress**

This signals to the team that the issue is yours and prevents duplicate work.

### Step 3 — Pull latest main

```bash
cd path/to/NoName-App-Dev/strayfriends
git checkout main
git pull origin main
```

Don't skip this. Branching from stale `main` causes painful merge conflicts later.

### Step 4 — Create a feature branch

Naming convention: `nad-<issue-number>-<short-kebab-description>`

```bash
git checkout -b nad-25-browse-campaigns
```

Keep the description short (3–5 words max) and use lowercase + hyphens.

### Step 5 — Implement

- **Read existing patterns first.** If you're adding a new screen, open 2–3 existing screens in `lib/screens/` and mirror the pattern. If you're adding a new service, look at `auth_service.dart` and `reports_service.dart`. Consistency reduces review time.
- **Use AppTheme tokens.** Never hardcode colors or text styles inline. If you need a new style, add it to `lib/app/app_theme.dart` and reference it from there.
- **Use established failure types.** If your service can fail, follow the `AuthFailure` / `LocationFailure` / `PhotoUploadFailure` pattern: typed failure class + friendly user-facing message.
- **Write tests as you go.** New model? Add round-trip test. New service? Add unit test. New screen with non-trivial state? Add widget test.

If you use AI tooling (Claude Code, Cursor, Copilot, etc.), **you are responsible** for:

- Reading and understanding every line you commit
- Ensuring tests pass
- Ensuring established patterns (services, theming, navigation, error handling) are followed
- Catching anti-patterns from Section 8 of this doc before they land in main

AI-generated code that introduces a regression of Sprint 1 bugs (BR-001..006) will be reverted and the issue reopened. Treat AI output as a draft, not a finished commit.

### Step 6 — Commit in small atomic units

A commit should represent **one logical concern**. Examples of good atomic commits:

- "NAD-25: campaign model + Firestore service"
- "NAD-25: BrowseCampaignsScreen with StreamBuilder"
- "NAD-25: campaigns/{id} read-public security rule"
- "fix: handle null campaign hero image with placeholder"

Examples of **bad** commits (avoid):

- "WIP" (uninformative; will haunt the git log)
- "Day 1 progress" (groups unrelated changes)
- "Fix everything" (impossible to revert one fix without losing others)

Commit message format strictly:

| Type | Format | Example |
|---|---|---|
| Feature | `NAD-<N>: <description>` | `NAD-25: campaign model + Firestore service` |
| Bug fix | `fix: <description>` | `fix: handle null campaign hero image` |
| Chore | `chore: <description>` | `chore: bump flutter_map to 7.0` |
| Refactor | `refactor: <description>` | `refactor: extract CampaignCard widget` |
| Docs | `docs: <description>` | `docs: update SRDD §4.4 with UC-09 description` |
| Test | `test: <description>` | `test: add CampaignModel round-trip tests` |

If your commit fixes a defect that was filed as a BR ticket, include the BR ID in the commit body:

```
fix: enable Submit button when description is empty

Resolves BR-007: AC says description is optional but Submit was
blocked when the field was empty.
```

### Step 7 — Run verification before push

From the `strayfriends/` folder:

```bash
flutter analyze          # must report 0 issues
flutter test             # all tests must pass
```

Then do a manual smoke run on the change:

```bash
flutter run              # Android emulator
flutter run -d chrome    # Web
```

Click through the AC paths. If anything is broken — **fix it before pushing**. Pushing broken code makes other team members' lives harder.

### Step 8 — Push your branch

```bash
git push origin nad-25-browse-campaigns
```

### Step 9 — Merge to main

Two paths depending on size of change:

**For small changes (< 50 lines, no security or auth impact):**

```bash
git checkout main
git pull origin main
git merge nad-25-browse-campaigns --no-ff
git push origin main
git branch -d nad-25-browse-campaigns
git push origin --delete nad-25-browse-campaigns
```

Notify the team in WA: *"Merged NAD-25 to main, ping me if anything breaks on your branches."*

**For larger changes (50+ lines, anything touching auth / security / Firestore rules):**

Open a pull request on GitHub:

1. Push your branch (Step 8)
2. On GitHub: **Pull requests** → **New pull request** → base `main`, compare `nad-25-...`
3. Title: same as the most informative commit message
4. Description: paste the AC from Jira, then a "What I did" bullet list
5. Request review from at least 1 other team member (preferably someone familiar with the affected area)
6. Wait for ✅ approval before merging
7. Use "Squash and merge" or "Create a merge commit" based on commit cleanliness
8. Delete branch after merge

PRs sit max **24 hours** before someone responds. If your PR is older than 24h with no response, ping in WA.

### Step 10 — Close out

1. **Move Jira issue to Done.** Add a brief comment with the merge commit hash.
2. **Update related docs** — see Section 5 below.
3. **Pick the next issue** and start again at Step 1.

---

## 4. Self-review checklist

Before you merge (or open a PR), tick all of these mentally:

- [ ] The AC from Jira is fully satisfied — open Jira, re-read each AC, verify each one passes
- [ ] `flutter analyze` passes with 0 issues
- [ ] `flutter test` passes (all old tests + your new ones)
- [ ] Manual smoke on Android emulator covers the happy path
- [ ] Manual smoke on Web covers the happy path (or N/A if mobile-only feature)
- [ ] All new colors / text styles come from `AppTheme`, no inline values
- [ ] Empty / loading / error states are handled for new screens
- [ ] New services use typed failure classes with friendly error messages
- [ ] New screens use `context.push()` for sub-navigation (not `context.go()`)
- [ ] New Firestore reads/writes have matching `firestore.rules` updates
- [ ] No secrets (Firebase keys, Supabase keys, `.env` content) in commits
- [ ] No `print()` statements left in production code (use `debugPrint` only if necessary)
- [ ] No `TODO` or `FIXME` comments without a Jira ticket reference

If any box is unticked, you're not done.

---

## 5. Documentation updates per change type

Different changes require different docs to be updated:

| Change type | Update SRDD | Update TRD | Update CLAUDE.md | Update BACKLOG.md |
|---|---|---|---|---|
| New use case | §4.1 (FR table), §4.2 (UC list), §4.4 (UC description) | Add test case rows | If new convention introduced | Update AC if refined |
| New service | — | Add unit test cases | If new pattern | — |
| New screen for existing UC | — | Add widget test cases | — | — |
| Bug fix | — | Add row marking BR-X resolution | — | — |
| Refactor | — | — | If pattern changed | — |
| Architecture decision | §3 (System Architecture) | — | Always | — |
| New library / dependency | §6 (System Requirement) | — | Always | — |
| New security rule | §4.5 NFR Security row | — | — | — |

**End of sprint** (Lead Developer's responsibility — but everyone should sanity check):

- SRDD Revision History: add new row (A2 for Sprint 2, etc.)
- Tag Jira Release: `v0.{N}.0` where N = sprint number
- Sprint Report: closeout summary in `/AD/docs/`

---

## 6. Sprint rituals

### Sprint Planning (Monday week 1)

- ~60 min meeting
- Walk through the prioritized backlog
- Each member picks N issues based on story point capacity
- Confirm dependencies and parallelism (e.g., "NAD-27 needs NAD-25 first")
- Note any spike work needed (e.g., "spike payment gateway library choice")

### Sprint Retrospective (Friday week 2)

- ~45 min meeting
- 3 questions:
  - **What went well?** — celebrate
  - **What didn't go well?** — diagnose
  - **What will we change?** — concrete action items, max 5
- Action items go into a NOD doc and are reviewed at the next sprint's planning

### Sprint Demo (Friday week 2)

- ~30 min meeting
- Each member shows what they shipped
- Test from a fresh emulator install (no "works on my machine" demos)
- Stakeholders (lecturer at end-of-sprint review) see this

### Async standups (anytime)

- Optional, async, via WA group
- Just type "blocked on X" or "shipped NAD-Y, taking NAD-Z next"
- Don't formalize this — pressure-free, lightweight

---

## 7. Code style + project conventions

### Dart formatting

```bash
dart format .
```

Run before every push. `dart format` is opinionated and stable — no debates needed.

### Naming

- **Files:** `snake_case.dart` — e.g., `cat_report_card.dart`
- **Classes:** `PascalCase` — e.g., `CatReportCard`
- **Variables and functions:** `lowerCamelCase` — e.g., `loadProfile()`
- **Constants:** `lowerCamelCase` (not SCREAMING_SNAKE) — e.g., `const maxPhotoMB = 2`
- **Private members:** prefix with `_` — e.g., `_friendlyError()`

### Folder structure

```
lib/
├── app/              # app-wide config: theme, router, env
├── models/           # data classes (UserProfile, CatReport, Campaign, ...)
├── services/         # business logic + Firestore/Supabase interaction
├── screens/          # full-screen widgets
├── widgets/          # reusable widgets (ReportCard, ConditionBadge, ...)
└── main.dart         # app entry point
```

Don't introduce new top-level folders without team agreement.

### Imports

Order:

1. Dart core (`dart:async`, `dart:io`)
2. Flutter framework (`package:flutter/material.dart`)
3. Third-party packages (`package:firebase_auth/firebase_auth.dart`)
4. Local project imports (`package:strayfriends/services/auth_service.dart`)

Use absolute imports (`package:strayfriends/...`), not relative (`../../services/...`).

### Logging

- `debugPrint(...)` for development-time debugging — strip before push
- No production logging in Sprint 2/3 — Sprint 4 adds proper logging if needed
- Never log secrets, tokens, or PII

---

## 8. Anti-patterns to avoid (Sprint 1 BR reference)

These 6 patterns each caused a defect in Sprint 1. **Do not introduce them again.** If you find existing code that has one, file a fix.

| BR ID | Anti-pattern | Correct pattern |
|---|---|---|
| **BR-001** | Calling Supabase Storage upload without an authenticated session | `await supabase.auth.signInAnonymously()` in `main.dart` before any Supabase upload |
| **BR-002** | Calling `Geolocator.getCurrentPosition()` without a fallback for missing/denied GPS | Always provide a manual fallback (e.g., "Use UTM campus instead" button) |
| **BR-003** | Navigating to a sub-screen with `context.go('/path')` | Use `context.push('/path')` so the back button works |
| **BR-004** | `Image.network(..., fit: BoxFit.cover)` for previews where the user needs to see the full image | Use `BoxFit.contain` for previews; `BoxFit.cover` only for tile thumbnails |
| **BR-005** | Custom AppBars or SliverAppBars without an explicit back button | Include `IconButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context))` |
| **BR-006** | Showing coordinates as text where the AC asks for a map widget | Use `flutter_map` with OpenStreetMap tiles |

Code review will flag these. Pre-empt by avoiding them in the first place.

---

## 9. Where to ask questions

In order of preference:

1. **Read the docs first** — `SETUP.md`, this file, `CLAUDE.md`, `BACKLOG.md`, `DESIGN.md`, SRDD, TRD
2. **Search the codebase** — `grep -r "pattern" lib/` often finds the answer
3. **Search the official docs** — Flutter / FlutterFire / Supabase docs are excellent
4. **Ask in WA group** — async, benefits everyone
5. **Ping Lead Developer privately** — only for blocking issues that need real-time pairing

Don't skip step 1–4 and jump to step 5. Public questions in WA create a team knowledge base over time; private DMs do not.

---

## 10. Your first contribution

If this is your first time working in the codebase after `SETUP.md`:

1. Read this entire file (you just did)
2. Read `CLAUDE.md` for project-level conventions and design philosophy
3. Open `lib/screens/feed_screen.dart` and `lib/services/reports_service.dart` — these are the cleanest reference implementations from Sprint 1
4. Pick a **small** issue first — e.g., a UI polish ticket, a refactor, or a documentation update. Don't grab the biggest feature on day 1.
5. Pair with the Lead Developer for your first PR — review the diff together over WA voice / Zoom before merging

After your first successful merge, you're full-velocity.

---

## END

> Conventions evolve. If something in this file is wrong or outdated,
> edit it and commit (`docs: clarify branch naming convention`). Don't
> wait for the Lead Developer to do it.
