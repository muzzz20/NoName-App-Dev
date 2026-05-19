# Fundraising UI Handoff — Sprint 2

> **Audience:** Ahmad + Khalief working on the Fundraising module UI
> screens (NAD-28..33). This doc is the contract between Faiz's
> backend services (just shipped — commit `133060c` on `main`) and
> the screens you need to build.
>
> **How to use:** copy **the entire "AI Prompt — Bootstrap" section
> verbatim** into your AI assistant (ChatGPT / Claude / Cursor) at the
> start of every coding session. Then drop your Jira ticket + the
> per-ticket recipe below for whichever screen you're building.

---

## 1. What just landed (backend you can call)

Branch `main` now has — under `lib/features/fundraising/`:

| Service | File | What it does |
|---|---|---|
| `CampaignsService` | `services/campaigns_service.dart` | Read / list / create campaigns |
| `DonationsService` | `services/donations_service.dart` | Orchestrates payment + persists donation; stream donation lists |
| `PaymentService` | `services/payment_service.dart` | Simulated gateway (Sprint 2). Returns success / failure codes |
| `AllocationsService` | `services/allocations_service.dart` | Admin spend records per campaign |
| `TransparencyService` | `services/transparency_service.dart` | One-shot snapshot: campaign + donor count + allocations |

Models — under `lib/features/fundraising/models/`:

- `Campaign` (id, title, description, **goalAmountSen**, **currentAmountSen**, imageUrl?, status, createdBy, createdAt, endsAt?)
- `Donation` (id, donorId, campaignId, **amountSen**, transactionId?, status, failureCode?, createdAt, donorName?)
- `Allocation` (id, campaignId, **amountSen**, purpose, evidenceUrl?, createdBy, createdAt)

⚠️ **All money is stored as `int sen` (1 RM = 100 sen).** Format for
display by dividing by 100. E.g. `5000 → "RM 50.00"`.

Cloud Functions deployed (server-side, you don't call them — they
fire automatically):

- `onDonationCreate` → when a donation with `status='success'` is
  written, campaign's `currentAmountSen` is incremented atomically.
  Verified live: end-to-end latency < **3.5 seconds**.
- `onAllocationCreate` → if `sum(allocations) > campaign.currentAmount`,
  the new allocation is rolled back. Sum invariant enforced server-side.

---

## 2. AI Prompt — Bootstrap (paste at the start of every session)

```
You are my coding pair for the Strayfriends Flutter app — UTM stray
cat welfare project. I'm building UI screens for the FUNDRAISING
module (Sprint 2). The backend was shipped by Faiz and lives at
lib/features/fundraising/. You DO NOT need to design the backend —
you only consume the services below.

Project context files already loaded:
  - CLAUDE.md            (project rules, NAD ticket prefix)
  - docs/CONTRIBUTING.md (10-step workflow, commit format)
  - docs/DESIGN.md       (UI tokens, colors)
  - docs/BACKLOG.md      (story ACs — planning IDs, not live NAD-N)
  - docs/SPRINT2_HANDOFF.md (.env trap + AI hard rules)
  - docs/FUNDRAISING_UI_HANDOFF.md (this file)

HARD RULES (memorize):
1. Match existing patterns. Read lib/features/reporting/screens/
   and lib/features/auth/screens/ as your reference templates.
2. Theme: all colors / text styles from lib/core/theme/app_colors.dart
   / app_text.dart / app_spacing.dart. NEVER hardcode hex / TextStyle.
3. Router: add new routes in lib/core/router/app_router.dart.
   Use context.push() for sub-screens. context.go() ONLY for
   terminal redirects (sign-out, auth state flips). This was a
   Sprint 1 bug — do NOT regress.
4. Money: ALL amounts are int sen. Display divides by 100.
   Use NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ',
   decimalDigits: 2) and pass amountSen / 100 to it.
5. Services: import from package:strayfriends/features/fundraising/.
   Instantiate via const constructor (e.g. CampaignsService()).
   Do NOT introduce a DI framework.
6. Sprint 1 anti-patterns to avoid:
   - BR-001: Don't bypass anon Supabase sign-in if uploading images
   - BR-002: Geolocator: always provide a fallback button
   - BR-003: context.go for sub-screens (use context.push)
   - BR-004: BoxFit.cover for full-image previews (use contain)
   - BR-005: Custom AppBar without explicit back button
   - BR-006: Coordinates-as-text where AC says map widget
7. Cite the Jira NAD-N ID in every code suggestion.
8. Don't run git commands. I run those myself.
9. Don't install new dependencies without asking first.
10. After writing code, list every file you changed + a one-line
    reason. Don't generate code I can't audit.

Workflow per ticket:
A. I send you a Jira NAD-N ticket (screenshot + AC).
B. You restate the AC in your own words. Wait for my confirmation.
C. You propose a file-by-file plan. Wait for my "go".
D. You write code. One file at a time, ask before moving on.
E. After all files done, list the test scenarios I should manually
   verify on emulator + Chrome before I commit.

Backend services available (READ-ONLY for you — consume, don't modify):

  CampaignsService
    - createCampaign({createdBy, title, description, goalAmountSen,
                      imageUrl?, endsAt?}) -> Future<Campaign>
      (admin/ngo only — rules enforce; throws CampaignFailure on
       title empty / goal <= 0 / endsAt in past)
    - watchActiveCampaigns({limit = 50}) -> Stream<List<Campaign>>
      (powers UC-09 Browse Active Campaigns feed)
    - watchCampaignsByCreator({createdBy, limit = 50})
      (admin "my campaigns" management list)
    - getCampaign(id) -> Future<Campaign?>  (one-shot)
    - watchCampaign(id) -> Stream<Campaign?>  (live updates — use
      for UC-10 detail so progress bar moves as donations come in)
    - updateCampaign({campaignId, title?, description?, imageUrl?,
                      status?, endsAt?})  (admin/ngo)
    - throws CampaignFailure (typed exception with .message)

  DonationsService
    - donate({donorId, campaignId, amountSen, donorName?})
        -> Future<Donation>
      INTERNALLY calls PaymentService.processPayment then writes
      donations/{id}. Returns persisted Donation. Status is success
      or failed — UI branches on result.status to show receipt or
      retry screen. Throws DonationFailure on amount <= 0.
    - watchDonationsByDonor({donorId, limit = 50})
        -> Stream<List<Donation>>
      (powers UC-12 "My Donations" history)
    - watchDonationsForCampaign({campaignId, limit = 100,
                                  successOnly = false})
        -> Stream<List<Donation>>
      (transparency / admin reconciliation)
    - getDonation(id) -> Future<Donation?>  (for receipts)

  PaymentService   (mostly used via DonationsService — direct use rare)
    - processPayment({amountSen, donorId, campaignId})
        -> Future<PaymentResult>
    - PaymentResult: { isSuccess, transactionId?, failureCode?,
                       message? }
    - Simulation triggers — use these for QA testing:
      RM 100.00 (10000 sen)  -> success
      RM 100.08 (10008 sen)  -> cardDeclined
      RM 100.09 (10009 sen)  -> insufficientFunds
      RM 100.77 (10077 sen)  -> expiredCard

  AllocationsService
    - createAllocation({campaignId, amountSen, purpose, createdBy,
                        evidenceUrl?})  (admin/ngo)
    - watchAllocationsForCampaign({campaignId, limit = 100})
        -> Stream<List<Allocation>>
    - attachEvidence({allocationId, evidenceUrl})

  TransparencyService
    - getReport({campaignId, donationLimit = 500,
                 allocationLimit = 200})
        -> Future<TransparencyReport>
    - TransparencyReport: { campaign, donorCount, totalAllocatedSen,
                            allocations[], recentSuccessfulDonations[],
                            unallocatedSen, invariantViolated }

DONATION FLOW (UC-11):
   user fills amount + taps "Donate"
   -> show loading spinner
   -> await DonationsService().donate(...)
   -> on result.isSuccess  -> navigate to Receipt screen with donation
   -> on result.status==failed -> show error banner with message + retry CTA
   The donation is persisted EITHER WAY (failed donations are recorded
   for audit). Campaign currentAmountSen updates via Cloud Function
   within ~3 seconds — UC-10 should use watchCampaign() to show live.

Confirm you understand by:
  1. Naming the 5 backend services and one thing you'd call each for
  2. Stating the money unit rule
  3. Stating which navigation method to use for sub-screens
Then wait for my first ticket.
```

---

## 3. AI Prompt — Per-Ticket (paste each time you start a new ticket)

```
Here is my next Jira ticket. Follow workflow steps A–E from the
bootstrap rules.

----- HOW TO READ THIS TICKET -----
I'm giving you TWO sources. Cross-reference:
1. JIRA SCREENSHOT (below) — authoritative for the live NAD-N ID,
   AC, sprint, priority.
2. docs/BACKLOG.md (already in your context) — match by TITLE; the
   STRAY-N IDs in BACKLOG.md don't correspond to NAD-N live IDs.

If AC in Jira and BACKLOG disagree, Jira wins.
If you can't find a matching BACKLOG entry, STOP and tell me.

----- JIRA SCREENSHOT / TEXT -----
<paste screenshot OR ticket title + description + AC>

----- END TICKET -----

Now:
1. State which BACKLOG entry you matched by title.
2. Restate the AC in your own words (workflow step B).
3. List which backend services from FUNDRAISING_UI_HANDOFF.md §2
   you'll call.
4. Wait for my "go" before writing any code.
```

---

## 4. Per-ticket recipes (quick reference)

| Jira | Screen | Backend you'll call | UC |
|---|---|---|---|
| NAD-28 | Campaigns list (browse feed) | `CampaignsService.watchActiveCampaigns()` | UC-09 |
| NAD-29 | Campaign detail | `CampaignsService.watchCampaign(id)` + `TransparencyService.getReport(id)` | UC-10 + UC-13 |
| NAD-30 | Donation flow (amount entry + payment) | `DonationsService().donate(...)` (which wraps `PaymentService`) | UC-11 |
| NAD-31 | My Donations history | `DonationsService.watchDonationsByDonor(donorId)` | UC-12 |
| NAD-32 | Donation receipt | `DonationsService.getDonation(id)` — pass donation through navigation | UC-13 |
| NAD-33 | Admin: Create/Manage Campaign | `CampaignsService.createCampaign(...)` + `watchCampaignsByCreator(uid)` + `updateCampaign(...)` | UC-14 + UC-15 |

### NAD-28 — Campaigns list

- Mirror: `lib/features/reporting/screens/feed_screen.dart`
- Each item card: hero image (`Image.network(campaign.imageUrl ?? placeholder, fit: BoxFit.cover)`), title, progress bar (`campaign.progress`), "RM X / RM Y" label
- Empty state: "No active campaigns yet" + (admin-only) "Create campaign" CTA
- Pull-to-refresh: re-emit via stream

### NAD-29 — Campaign detail

- Mirror: `lib/features/reporting/screens/report_detail_screen.dart`
- Hero image, title, description, **live progress** (use `watchCampaign(id).snapshots()` to update as donations stream in)
- "Donate" FAB / button → push to NAD-30 donation flow
- "Where the money goes" section: call `TransparencyService.getReport(id)` on screen load; show donorCount, totalAllocatedSen / unallocatedSen, allocations list
- Pull-to-refresh re-fetches the transparency report

### NAD-30 — Donation flow

- 3 sub-screens or 1 stepper:
  1. Enter amount (NumberFormat input, validate amountSen > 0)
  2. Confirm + simulated card form (UI only — PaymentService is sim)
  3. Loading spinner while `await DonationsService().donate(...)` resolves
- On `result.isSuccess`: `context.push('/donation/receipt', extra: donation)`
- On `result.status == DonationStatus.failed`: show error banner with `failureCode` lookup + retry button (stays on screen, doesn't navigate)
- Auth gate: redirect to login if not signed in (router guard already exists)

### NAD-31 — My Donations

- Mirror: `lib/features/reporting/screens/my_reports_screen.dart`
- StreamBuilder on `DonationsService().watchDonationsByDonor(donorId: FirebaseAuth.instance.currentUser!.uid)`
- Each row: status pill (Success / Failed), campaign title (cached or look up), amount, date
- Tap → push to donation receipt (NAD-32) for that donation
- Empty state: "You haven't donated yet" + "Browse campaigns" CTA → push to NAD-28

### NAD-32 — Donation receipt

- One-shot read or pass `Donation` via route extra
- Show: transactionId (or "—" for failed), amount (formatted), campaign title (look up via `CampaignsService.getCampaign(donation.campaignId)`), donor name, date, status
- "Download PDF" CTA (Could-Have; defer to Sprint 4 if time short — the data is already in the model)
- Receipt screen reachable from My Donations OR from Donation flow success

### NAD-33 — Admin: Create/Manage Campaign

- **Hidden behind admin role check**: read `UserProfile.role`; if not in `['admin', 'ngo']`, redirect to home with a snackbar.
- Create form: title, description, goalAmount (RM input — multiply by 100 before passing), endsAt date picker (optional), imageUrl (upload via existing Supabase pattern in `lib/features/reporting/services/photo_upload_service.dart`)
- On submit → `CampaignsService().createCampaign(...)` → catch `CampaignFailure` → show banner
- Manage list: `watchCampaignsByCreator(createdBy: currentUid)` — show your own campaigns with status pill + edit / archive actions
- Edit dialog → `updateCampaign(...)` with diffed fields

---

## 5. Common gotchas

- **`amountSen` is int, not double.** Don't pass `5000.0` — type error.
- **`watchCampaign(id)` returns `Stream<Campaign?>`** — nullable because doc might not exist. Handle the null case in StreamBuilder.
- **`donate()` does NOT throw on payment failure.** It throws only on caller validation (amount ≤ 0). Gateway declines return `Donation(status: failed)`. Branch on `result.status`, don't wrap in try/catch expecting decline exceptions.
- **Donation list filter logic for "successful donations"** is client-side when you pass `successOnly: true` to `watchDonationsForCampaign`. The composite Firestore index supports campaign+createdAt, not status. Don't add a new index without asking.
- **Cloud Function aggregation has ~3 sec latency.** UI shows live updates via `watchCampaign(id)`. If you want immediate UI feedback before the Function fires, do an optimistic local state increment + reconcile when stream emits.
- **Admin role check happens both client-side (UX) AND server-side (rules).** Don't rely on client-only checks — rules will reject non-admin writes anyway.

---

## 6. Format helpers (write these in `lib/core/format/`)

You'll need these everywhere — write them ONCE, import everywhere:

```dart
// lib/core/format/money.dart
import 'package:intl/intl.dart';

String formatRM(int amountSen) {
  return NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
    decimalDigits: 2,
  ).format(amountSen / 100);
}
```

Add `intl` to pubspec dependencies if not already there:
```yaml
dependencies:
  intl: ^0.20.2
```

(Faiz — check pubspec; `intl` may already be a transitive dep via
Flutter framework. If not, this is the one new pubspec addition this
sprint needs your approval for.)

---

## 7. Definition of Done (per UI ticket)

Copy this checklist into your Jira ticket:

```
- [ ] All Acceptance Criteria from BACKLOG.md / Jira met
- [ ] flutter analyze passes (no warnings on changed files)
- [ ] Manually tested on Android emulator
- [ ] Manually tested on Chrome (unless mobile-only screen)
- [ ] All money displayed via formatRM helper (no raw "RM 5000" bugs)
- [ ] Loading + empty + error states for all StreamBuilders
- [ ] Sub-navigation uses context.push() (not context.go())
- [ ] No hardcoded hex colors or TextStyles — all from app_theme tokens
- [ ] Screenshots attached to Jira ticket
- [ ] Code committed on a feat/nad-XX-short-desc branch via PR
- [ ] Jira ticket commented with PR link + 1 commit from another member
```

---

## 8. Smoke test verification (done by Faiz on 2026-05-19)

Backend was verified live on prod Firestore before you started UI work. Reference for Khalisha's Sprint 2 TRD:

| Scenario | Outcome | Latency |
|---|---|---|
| Campaign create | ✅ | — |
| Success donation → currentAmount += amount | ✅ | 3.3 s |
| Failed donation → currentAmount unchanged | ✅ | 5 s window |
| Goal reached → auto-flip status='completed' | ✅ | 1.1 s |
| Over-budget allocation → auto-deleted | ✅ | 3.2 s |
| Valid allocation → persists | ✅ | 5 s window |

All 6 scenarios passed via Firebase Admin SDK script against
`strayfriends-utm` prod project. Test docs cleaned up after run.

---

**Last updated:** 2026-05-19 · Maintained by Faiz (Lead Dev) · For
backend questions, ping Faiz in WhatsApp DM. For Jira-related
workflow, see `docs/CONTRIBUTING.md`.
