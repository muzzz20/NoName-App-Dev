# Security Review — Strayfriends (NAD-62)

> Sprint 4 light hardening pass over the deployed security model after
> the Firebase migration, Stripe integration, Volunteer + Dashboard
> features, and visitor (public) access landed. Reviewer: Faiz (Lead Dev,
> via Claude CLI). Date: 2026-05-22.

## Scope

- `firestore.rules` (all collections)
- `storage.rules` (Firebase Cloud Storage)
- Cloud Functions secret handling (Stripe)
- Visitor / public-access model (router whitelist)

## Findings & status

| # | Area | Finding | Status |
|---|---|---|---|
| 1 | Donations | Client cannot create donations — only the `stripeWebhook` Cloud Function (service account) writes them after a verified Stripe payment. `donations` create rule = `if false`. **A fabricated donation is impossible from the app.** | ✅ Secure |
| 2 | Stripe secrets | `STRIPE_SECRET` + `STRIPE_WEBHOOK_SECRET` live only in Firebase Functions secrets (Google Secret Manager). Never in the client, repo, or `.env` that ships. Redirect-only Checkout means **no Stripe key is in the client at all**. | ✅ Secure |
| 3 | Webhook auth | `stripeWebhook` verifies the Stripe signature (`whsec_`) before acting; unsigned/forged POSTs are rejected with 400. | ✅ Secure |
| 4 | Storage | Public read (feed/campaign images), authenticated image-only write < 5 MB. Role gating happens at the Firestore doc level (an orphan upload is harmless). | ✅ Acceptable |
| 5 | Campaigns / Allocations | Public read; admin/ngo create+update (createdBy must equal own uid). Allocation invariant (`sum ≤ goalAmount`) enforced server-side by `onAllocationCreate` (rules can't sum cross-doc). | ✅ Secure |
| 6 | Role escalation | `users` update rule forbids a user changing their own `role`. Admin/ngo seeded manually via console. | ✅ Secure |
| 7 | Visitor access | Router whitelist exposes only public-read routes (feed, campaigns, activities, public stats, report/campaign/activity detail, help). Firestore/Storage rules already permit public read of exactly these. No write path is opened to visitors. | ✅ Secure |
| 8 | User PII to visitors | `users` read requires `isSignedIn` — visitors cannot read profile docs, so reporter names show as "Unknown" to visitors (no PII leak). Public stats page exposes aggregate counts only. | ✅ Secure |
| 9 | Activity slots | **Fixed this review.** Signed-in users may change ONLY `slotsRemaining` and only by ±1 (sign-up decrements, cancel increments) — blocks a crafted client from setting an arbitrary slot count (grief). | ✅ Tightened |

## Residual risks (accepted for academic scope)

- **R1 — Sign-up over-capacity via crafted client.** Sign-up uses a
  client-side Firestore transaction (chosen for synchronous "full" /
  "duplicate" UX). A hand-crafted client could create a `signups` doc
  without the paired slot decrement, theoretically exceeding capacity.
  Mitigations in place: deterministic signup id (`{activityId}_{uid}`)
  prevents duplicates; the ±1 rule limits slot tampering. **Full fix
  (Sprint 4+ if needed): move the decrement into an `onSignupCreate`
  Cloud Function (service account), like donations.** Risk is low in test
  context (no incentive to grief).

- **R2 — FCM web push not yet activated.** Requires a VAPID key + service
  worker wiring. `NotificationService` degrades gracefully; no security
  exposure (it only reads/writes the caller's own `users/{uid}.fcmToken`).

## Verification

- `firebase deploy --only firestore:rules` compiles + deploys clean.
- `firebase deploy --only storage` compiles + deploys clean.
- Stripe webhook signature verification confirmed live (BR/test log:
  "Donation recorded from Stripe webhook" only on signed events).
- No secrets in repo: `.env` gitignored; only `pk`/`sk` placeholders in
  `.env.example` (and even those unused — Checkout is redirect-only).
