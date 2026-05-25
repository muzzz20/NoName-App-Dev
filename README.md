# Strayfriends

> A mobile + web application for the well-being of stray cats at
> Universiti Teknologi Malaysia (UTM) — connecting feeders, donors, and
> volunteers into one coordinated platform.
> Course: SCSJ3104 Application Development · Group: NoName · Jira: `NAD`
> Status: **v1.0.0 — feature-complete** · integration suite green (17 E2E tests)

## Stack

- **Frontend:** Flutter (Dart SDK `^3.11.4`) — **Android · iOS · Web**
- **Backend:** Firebase — Auth · Firestore · Cloud Storage · Cloud
  Functions (Node.js) · Cloud Messaging (FCM)
- **Payments:** Stripe Checkout (**test mode**) — hosted redirect flow, no
  secret key on the client
- **State:** no state-management library (`StatefulWidget` + service classes
  + `StreamBuilder`)
- **PM:** Jira (project `NAD`) + GitHub (linked commits)

> Photo/image storage uses **Firebase Cloud Storage** (the project migrated
> off Supabase once it moved to the Blaze plan).

## Features by module

### 🐾 Reporting
- Submit a cat **sighting**: photo (Cloud Storage), **location** via map pin
  + "use my location" (GPS), **condition** (Healthy / Injured / Sick), and
  description.
- Public **feed** + full **All Reports** list with search, condition filter,
  and a **list ⇄ map** toggle.
- **Report detail** with a status timeline and "Open in Maps".
- **My Reports** for the signed-in user.
- **Cat profiles** (`cats/{id}`): every sighting links to a cat, so a cat's
  **care status is tracked over time** across multiple sightings; "report
  another sighting" attaches a new report to the same cat.
- **Admin/NGO:** update a sighting's status and a cat's care status
  (Pending → In progress → Resolved → Rejected).

### 💰 Fundraising
- **Per-case campaigns** — each donation is tied to a specific campaign, not
  a single generic pool.
- **Transparent allocations** ("where the money goes" with proportion bars),
  live progress, donor count, donation history (**My Donations**), receipt.
- **Stripe Checkout** (test mode) — donation records are written
  server-side only by a signature-verified webhook.
- **Admin/NGO:** create a campaign + allocations; close a campaign.

### 🙌 Volunteer coordination
- **Activities** — browse, detail, capacity-managed **sign-up / cancel**.
- **My Activities** history.
- **Admin/NGO:** create an activity, view its volunteers, **mark complete**.

### Cross-cutting
- **Urgent surfacing** — an "Urgent first" sort floats injured/sick + still-
  pending sightings to the top of All Reports.
- **Map view** of reports (OpenStreetMap; pins colour-coded by condition).
- **Stakeholder dashboard** (admin/NGO) — aggregate KPIs + 30-day donation
  trend, reachable from the Profile menu.
- **Public Stats** — aggregate impact for anyone, no PII.
- **Roles** — Visitor / Registered User / Admin·NGO, with role-gated routes.

## Prerequisites

| Tool | Min Version | Install |
|---|---|---|
| Flutter SDK | 3.x (Dart `^3.11.4`) | https://docs.flutter.dev/get-started/install |
| Firebase CLI | 14+ | `npm install -g firebase-tools` |
| FlutterFire CLI | latest | `dart pub global activate flutterfire_cli` |
| Node.js | 20 (Cloud Functions runtime) | for `functions/` only |
| Android Studio / Xcode | latest | platform SDKs for mobile builds |

## Setup & run

The client boots on a fresh clone with **zero local config** — Firebase
config is committed in `lib/firebase_options.dart`. No `.env` is required to
run the app.

```bash
git clone <repo-url>
cd strayfriends
flutter pub get

flutter run -d chrome        # web
flutter run -d <device-id>   # android / ios — list: flutter devices
```

### Build / lint / test

```bash
flutter analyze              # static analysis (flutter_lints)
flutter test                 # unit + widget tests (test/)
flutter build web --release  # web bundle → build/web
flutter build apk --release  # demo APK
```

## Testing

- **Unit + widget tests:** `flutter test` (in `test/`).
- **Integration / end-to-end (`integration_test/`):** two suites that run
  against the **Firebase Emulator Suite** — never prod:
  - `walkthrough_test.dart` — read / navigation / UI / gating (visitor,
    registered, admin).
  - `write_paths_test.dart` — input/write paths (submit report, validation,
    admin status change, donation boundary; image picking is mocked).

  The app connects to the emulators in-test; for manual runs use
  `flutter run --dart-define=USE_EMULATOR=true`.

  **Run the full suite (start emulators → seed → test):**

  ```bash
  firebase emulators:exec --only auth,firestore,storage \
    'node functions/seed_emulator.js && flutter test integration_test/ -d <device-id>'
  ```

  `functions/seed_emulator.js` seeds a known state (test accounts + sample
  campaigns/reports/activities) and is idempotent. Native targets (iOS
  Simulator / Android emulator) work out of the box; web needs `chromedriver`.
  Requires Java (Firestore emulator) + the Firebase CLI.

## Backend (Firebase)

The backend is already deployed to the `strayfriends-utm` project. To
re-deploy (full setup + secrets in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)):

```bash
firebase deploy --only firestore:rules     # security rules
firebase deploy --only firestore:indexes   # composite indexes
firebase deploy --only storage             # storage rules
firebase deploy --only functions           # Cloud Functions
```

**Cloud Functions** (`functions/index.js`): `onDonationCreate`,
`onAllocationCreate`, `createCheckoutSession`, `stripeWebhook`,
`onActivityCreate`.

### One-time maintenance scripts (`functions/scripts/`)

Each is idempotent and run with a service-account key (Firebase console →
Project settings → Service accounts → Generate key):

```bash
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json

node scripts/backfill_cats.js          # dry run: link legacy reports to cats
node scripts/backfill_cats.js --commit # apply

node scripts/backfill_denorm.js --commit   # reporterName + campaign donor counts
node scripts/set_cors.js                   # Storage CORS (web Image.network)
```

> `backfill_cats.js` only touches reports with no `catId`, so it is safe to
> re-run.

## Billing note

Cloud Functions and Stripe Checkout require the Firebase **Blaze**
(pay-as-you-go) plan. In **test mode** the app stays within the free tier —
Stripe test cards process no real money, and function invocation volume is
well under the free quota, so there are **no real charges** in normal
development and demo use.

## Project structure

Feature-first: each feature owns its `models/`, `screens/`, `services/`
(and `widgets/` where it has reusable UI). Cross-cutting code is in
`lib/core/`.

```
strayfriends/
├── lib/
│   ├── main.dart                  # entry: Firebase init → notifications → app
│   ├── firebase_options.dart      # generated by flutterfire configure (committed)
│   ├── core/                      # router · theme · notifications · shared widgets
│   └── features/                  # auth · reporting · fundraising · volunteer · dashboard · help
├── functions/                     # Cloud Functions (Node.js) + maintenance scripts
├── firestore.rules                # Firestore security rules
├── firestore.indexes.json         # composite indexes
├── storage.rules                  # Cloud Storage rules
├── android/ · ios/ · web/         # platform config
├── integration_test/              # end-to-end suite (walkthrough_test.dart)
├── test/                          # unit + widget tests
└── docs/                          # architecture, design, deployment, backlog…
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full technical
map (data model, routing, security, Cloud Functions, conventions).

## Commit convention

Every commit references its Jira issue: `NAD-<n>: <subject>`

```
NAD-11: submit report form validation
NAD-21: wire Stripe checkout redirect
```

GitHub–Jira integration auto-links commits to issues' Development panel.

## Team

| Role | Member | Jira |
|---|---|---|
| Project Manager | Baqir Tsaqib Hakim | `@baqir` |
| Lead Developer | Faiz Syuhada | `@faiz` |
| UI/UX Designer | Ahmad Muzhaffar Prihantony | `@ahmad` |
| UI/UX Designer | Khalief Zamzam Mahendra | `@khalief` |
| QA Engineer | Khalisha Afifah Sekarbyovi | `@khalisha` |

## Documentation

- **Architecture:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — canonical technical reference
- **Design system:** [`docs/DESIGN.md`](docs/DESIGN.md)
- **Deployment:** [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)
- **Security review:** [`docs/SECURITY_REVIEW.md`](docs/SECURITY_REVIEW.md)
- **Backlog + ACs:** [`docs/BACKLOG.md`](docs/BACKLOG.md)
- **Contributing:** [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md)
- **AI context:** [`CLAUDE.md`](CLAUDE.md) (app) · [`../CLAUDE.md`](../CLAUDE.md) (course/process)
</content>
