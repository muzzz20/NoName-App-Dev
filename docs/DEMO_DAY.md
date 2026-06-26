# DEMO_DAY — Strayfriends Final Presentation

> Self-contained demo pack: how to run it on any Mac, the spoken script,
> the Q&A, and how to reset the demo data. Pull this branch on the demo
> machine and you have everything.

---

## 0. Run it on a fresh MacBook (zero config)

The app boots with **no local config** — `lib/firebase_options.dart` is
committed, so a clean clone connects to the live Firebase project
(`strayfriends-utm`). The demo data + accounts already live in the cloud;
nothing data-related is tied to a specific machine.

**Prerequisites on the MacBook:** Flutter SDK + Chrome. (Android Studio +
an emulator only if you want the Android target.)

```bash
# 1. clone (or pull if already cloned)
git clone git@github.com:muzzz20/NoName-App-Dev.git
cd NoName-App-Dev/strayfriends
git checkout demo-day        # this branch (or develop for the graded code)

# 2. deps
flutter pub get

# 3a. WEB — most reliable, best for the Stripe redirect
flutter run -d chrome --web-port 5599

# 3b. ANDROID (primary target) — boot the emulator from Android Studio
#     first ("Cold Boot Now"), then:
flutter run -d emulator-5554
```

`flutter analyze` should report **No issues found**.

---

## 1. Demo accounts

| Email | Role | Persona | Use for |
|---|---|---|---|
| `volunteer@strayfriends.com` | user | Aisha Rahman | report, donate, volunteer |
| `admin@strayfriends.com` | admin | Coordinator | report triage + dashboard |
| `ngo@strayfriends.com` | ngo | PAWS Johor | (owns campaigns/activities) |

**Password:** the team's standard demo password (same one used by the
accounts in `integration_test/`). Not written here — this repo is public.
Ask Faiz if unsure.

> ⚠️ **Security:** this repo is public. **After the presentation, disable
> or rotate these prod accounts** in the Firebase console (especially the
> admin) — and ideally change the shared demo password, since it already
> appears in the committed test files.

**Stripe test card:** `4242 4242 4242 4242`, any future expiry, any CVC.
Minimum donation RM5.

---

## 2. Spoken demo script (~8 min)

Stage directions in `[brackets]`. Talk while you click — narration covers
the loading gaps.

### Opening `[app open at public feed, NOT logged in]`
> "I'll walk through Strayfriends as a real user would. Notice I'm **not
> logged in** — anyone can browse, but actions require an account."

### 1. Visitor browsing `[scroll feed → Campaigns → tap Donate]`
> "This is the public sighting feed. Visitors can also browse campaigns
> and volunteer activities. But the moment I try to act, the app asks me
> to sign in. Nothing sensitive is exposed to anonymous users — that's
> enforced by Firestore security rules, not just hidden in the UI."

### 2. Login `[volunteer@strayfriends.com]`
> "Let me log in as Aisha, a student volunteer. Auth runs on Firebase, and
> the session persists across restarts."

### 3. Report a sighting `[Submit Report]`
> "Aisha spots an injured cat near the library. A photo `[pick]`, the
> location — auto-detected by GPS and adjustable on the map `[pin]` — and
> the condition `[Injured]`. Because it's Injured, it's flagged as a
> **priority case**." `[submit → appears in feed]`
> "Live in the feed instantly, streamed straight from Firestore."

### 4. Donate — transparency `[Campaigns → "Emergency Vet Fund: Injured Kittens at KTR"]`
> "Here's a campaign with progress and donor count. What sets us apart is
> **transparency** `[open allocations]` — donors see exactly how the money
> was spent: vet consult, antibiotics, recovery food."
> `[Donate → RM10 → Checkout → 4242… → pay]`
> "Payment goes through **Stripe Checkout** in test mode — no card data
> ever touches our app. A Cloud Function verifies it server-side and
> records the donation `[receipt]`. The campaign total updated
> automatically."
> ⏳ *If the receipt is slow:* "It's confirming with the server through a
> secure webhook — takes a second."

### 5. Volunteer — atomic sign-up `[Activities → "Weekend Feeding Round — KTR Colony"]`
> "5 of 8 slots left. `[Sign Up]` Slot count drops to 4. This uses an
> **atomic database transaction**, so the activity can never be
> over-booked, even under simultaneous sign-ups."

### 6. Admin — triage + dashboard `[logout → admin@strayfriends.com]`
> "The coordinator side. `[open the injured report]` Admins triage reports
> — Pending to Resolved. `[change status]` Regular users can't; the role
> is checked server-side. `[Dashboard]` The stakeholder dashboard
> aggregates everything — reports, campaigns, funds raised, a 30-day
> donation trend — in under two seconds. There's also a public stats page
> with zero personal data."

### Closing
> "That's Strayfriends end-to-end — report, fundraise, volunteer, oversee
> — one Flutter codebase on Android, iOS, and web, backed by Firebase.
> Thank you — happy to take questions."

---

## 3. Q&A — likely lecturer questions

### Architecture & tech
- **Why Flutter?** One codebase for Android, iOS, web — a 5-person team
  couldn't maintain three apps. Native performance, single Dart codebase.
- **Why Firebase, not a custom backend?** Auth, real-time DB, storage,
  serverless functions, push — out of the box. Real-time Firestore streams
  are why feeds and dashboards update live.
- **What state management?** Deliberately none — `StatefulWidget` +
  service classes + `StreamBuilder`. Firestore already pushes live data;
  a state library would be complexity for no benefit at this scale.
- **Routing?** `go_router` with a redirect guard tied to auth state — it
  enforces the public-vs-protected visitor model.

### Security
- **Stop a user self-promoting to admin?** Rules force `role = user` on
  registration and forbid changing your own role. Admin/NGO are seeded
  manually in the console. No in-app self-promotion path.
- **Where's the Stripe secret?** In Google Secret Manager, used only
  inside Cloud Functions. Never on the client; payment is on Stripe's
  hosted page.
- **Fake a donation by writing to the DB?** No — donations are
  server-write-only (client create/update/delete = `false`). Only the
  signature-verified Stripe webhook writes them.
- **Public feed leaking private data?** Read rules are per-collection.
  Reports/campaigns are public; who-donated-what is donor/admin only. We
  denormalize just the display name so visitors never read the user doc.

### Data & money
- **Floating-point errors?** Money is integer *sen* (1 RM = 100 sen).
  Never a float; format to RM only at display. Matches Stripe's minor unit.
- **Concurrent donations corrupting the total?** A Cloud Function updates
  the total in an atomic transaction, and is idempotent on the Stripe
  session ID — no double-counting on webhook retries.
- **10 people, 8 slots?** Atomic transaction decrements remaining slots;
  zero rejects further sign-ups. Deterministic doc ID blocks double
  sign-ups.
- **Transparency?** Admins record allocations; a Cloud Function enforces
  total allocations ≤ funds raised and rolls back violators. Donors see
  the breakdown publicly.

### Testing & QA
- **How tested?** Unit + widget tests, an end-to-end integration suite
  driving real journeys, and manual acceptance recorded in the TRD. Final
  E2E: 29 pass, 1 skip.
- **Why one skip?** It touches Stripe's hosted page + the camera —
  external systems a test driver can't reliably automate. Verified
  manually and documented instead of writing a flaky test.
- **Bug tracking?** Logged in the TRD with severity/root-cause/resolution
  and cross-referenced in Jira; QA verifies against the ACs before Done.

### Process & teamwork
- **Work split?** Four sprints, four releases. I led dev (backend,
  integration, security); two designers on the design system + screens; a
  QA engineer on testing + reports; a PM on Jira, releases, coordination.
  Traceable in Jira + GitHub.
- **Hardest part?** The payment + transparency flow — making donations
  tamper-proof (server-only, signature-verified, atomically aggregated).
- **Why migrate Supabase → Firebase Storage?** We only used Supabase for
  object storage. Once everything else was on Firebase, two platforms
  added config/CORS overhead for no benefit. Consolidating simplified
  deploy and auth.

### Traps / follow-ups
- **Offline?** Firestore caches loaded data and queues writes until
  reconnect. Not full offline-first — sufficient for a connected campus
  use case.
- **Push didn't fire on web?** Server-side push works (Cloud Function →
  FCM on new activity). Web push needs a VAPID key + service worker,
  scoped post-v1.0. Mobile works.
- **Scale to more universities?** Add a campus identifier to scope data;
  Firebase scales horizontally; aggregation is server-side so the client
  doesn't get heavier.
- **Do differently / next?** Activate web push, NGO-volunteer chat, admin
  analytics export. If restarting: set up the E2E suite from Sprint 1, not
  Sprint 4.
- **Real product or class project?** A functional MVP on live Firebase
  with real payment rails in test mode. To go live: flip Stripe to live
  keys, finish the security review (started + documented), onboard a real
  NGO.

**If you don't know an answer:** "That's a great point — we handled the
core case; that specific scenario would be a next step." Honest > made up.
Tie answers back to *deliberate decisions* ("we deliberately…").

---

## 4. Reset the demo data to a clean state

If practice runs dirty the data (extra donations, sign-ups, submitted
reports), reset to the curated demo state. Needs the Firebase **service
account key** (NOT in the repo — copy it to the demo machine or
re-download from Firebase console → Project Settings → Service accounts).

```bash
cd strayfriends/functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/strayfriends-utm-...json
export DEMO_PW='<the team demo password>'   # only needed for APPLY

# preview (no writes):
node scripts/demo_reset.js

# apply:
APPLY=1 node scripts/demo_reset.js

# verify:
node scripts/inspect_prod.js
```

`demo_reset.js` wipes the 6 demo collections and reseeds 4 campaigns,
3 allocations, 3 activities (one with a 3-person roster), and 4 reports,
plus (re)creates the demo accounts. Money is integer sen; `currentAmount`
/`donorCount` are set directly so the donation Cloud Function doesn't
double-count.
