# Deployment — Strayfriends (NAD-66)

> How to deploy the app + backend. Current setup uses ONE Firebase
> project (`strayfriends-utm`) for dev + demo. A separate production
> project is recommended before any real launch (see "Production" below).

## Backend (Firebase, Blaze plan)

```bash
cd strayfriends

# Firestore security rules + composite indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes   # indexes take ~1 min to build

# Cloud Storage rules
firebase deploy --only storage

# Cloud Functions (aggregators + Stripe + FCM)
cd functions && npm install && cd ..
firebase deploy --only functions
```

### Cloud Functions secrets (one-time, never committed)

```bash
firebase functions:secrets:set STRIPE_SECRET          # sk_test_... (sandbox)
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET  # whsec_... from the webhook
```

After deploying functions, register the Stripe webhook:
- Endpoint URL: `https://asia-southeast1-strayfriends-utm.cloudfunctions.net/stripeWebhook`
- Event: `checkout.session.completed`
- Copy the signing secret → set `STRIPE_WEBHOOK_SECRET` → redeploy functions.

## Web app

```bash
flutter build web --release
firebase deploy --only hosting   # after `firebase init hosting` points at build/web
```

(Hosting not yet initialized — `firebase init hosting`, set public dir to
`build/web`, single-page app = yes, then the deploy command above.)

## Android (demo APK)

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk — side-load for demo
```

## Admin seeding

Admin/NGO users are seeded manually (no in-app self-promotion):
Firestore console → `users/{uid}` → set `role: 'admin'` (or `'ngo'`).

## Activation still pending (optional)

- **FCM web push:** generate a VAPID key (console → Cloud Messaging →
  Web Push certificates), wire it into `getToken(vapidKey:)` and
  `web/firebase-messaging-sw.js`. Server-side topic push already works.
- **Stripe live mode:** swap sandbox keys for live keys + complete Stripe
  business verification. Test mode is sufficient for the course.

## Production (recommended before real launch — NAD-66)

The course demo runs on the single dev project. For production:
1. Create a separate Firebase project `strayfriends-prod`.
2. `flutterfire configure` → regenerate `firebase_options.dart` for prod
   (use a flavor/env switch to keep dev + prod configs).
3. Re-deploy rules / indexes / storage / functions to prod.
4. Set prod Stripe live keys as prod Functions secrets.
5. Register the prod Stripe webhook against the prod function URL.
6. Lock Firestore/Storage rules review (this doc's SECURITY_REVIEW.md).
