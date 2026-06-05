/**
 * Strayfriends Cloud Functions — NAD-26 + NAD-27.
 *
 * Trigger registry:
 *   - onDonationCreate (NAD-26):
 *       Listens to donations/{donationId} create.
 *       If status === 'success', atomically increments
 *       campaigns/{campaignId}.currentAmount and auto-flips campaign
 *       status to 'completed' once the goal is reached.
 *       Failed donations are recorded by the client but contribute
 *       nothing to the campaign total.
 *
 *   - onAllocationCreate (NAD-27):
 *       Listens to allocations/{allocationId} create. Enforces the
 *       invariant sum(allocations for campaign) <= goalAmount by
 *       reading existing allocations + the campaign in a transaction.
 *       If the invariant would be violated, the new allocation is
 *       rolled back (deleted) and an error log is emitted for admin
 *       reconciliation. (Firestore rules cannot sum cross-doc, so we
 *       enforce server-side here.)
 *
 *   - createCheckoutSession (NAD-21, onCall):
 *       Creates a Stripe Checkout Session (test mode) for a donation.
 *       Uses STRIPE_SECRET. Returns the hosted-checkout URL; the client
 *       redirects there. No Stripe key ever touches the client.
 *
 *   - stripeWebhook (NAD-21/26, onRequest):
 *       Stripe POSTs payment events here. Verifies the signature with
 *       STRIPE_WEBHOOK_SECRET, and on `checkout.session.completed`
 *       writes the donations/{id} doc (status=success) — which then
 *       triggers onDonationCreate to aggregate. Donations are therefore
 *       only ever created by a verified Stripe payment, never the client.
 *
 * Deploy: `firebase deploy --only functions`
 * Local:  `npm run serve` (uses Firebase emulator suite)
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Server-side secrets — set with:
//   firebase functions:secrets:set STRIPE_SECRET
//   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
// NEVER committed, NEVER sent to the client.
const STRIPE_SECRET = defineSecret("STRIPE_SECRET");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

// === NAD-26: Donation aggregation ===
exports.onDonationCreate = onDocumentCreated(
    "donations/{donationId}",
    async (event) => {
      const donationId = event.params.donationId;
      const donation = event.data && event.data.data();
      if (!donation) {
        logger.warn("onDonationCreate fired with no data", {donationId});
        return;
      }

      // Failed donations are recorded for audit but don't contribute.
      if (donation.status !== "success") {
        logger.info("Skipping non-success donation aggregation", {
          donationId,
          status: donation.status,
        });
        return;
      }

      const campaignId = donation.campaignId;
      const amount = donation.amount;
      if (!campaignId || typeof amount !== "number" || amount <= 0) {
        logger.error("Invalid donation payload — skipping aggregation", {
          donationId,
          campaignId,
          amount,
        });
        return;
      }

      const campaignRef = db.collection("campaigns").doc(campaignId);
      try {
        await db.runTransaction(async (tx) => {
          // All reads must precede all writes in a Firestore transaction.
          const snap = await tx.get(campaignRef);
          if (!snap.exists) {
            throw new Error(
                `Campaign ${campaignId} not found for donation ${donationId}`,
            );
          }

          // Unique-donor tracking: a marker doc per (campaign, donor) lets
          // us increment donorCount only the first time a donor gives to a
          // campaign. The markers live in a CF-only subcollection (default
          // rules deny client access); clients read the public donorCount
          // field on the campaign instead.
          const donorId = donation.donorId;
          let donorMarkerRef = null;
          let isNewDonor = false;
          if (donorId) {
            donorMarkerRef = campaignRef.collection("donors").doc(donorId);
            const donorSnap = await tx.get(donorMarkerRef);
            isNewDonor = !donorSnap.exists;
          }

          const data = snap.data();
          const current = data.currentAmount || 0;
          const goal = data.goalAmount || 0;
          const newAmount = current + amount;

          const updates = {
            currentAmount: newAmount,
            // Denormalized public aggregates for the dashboards + campaign
            // detail (so visitors/regular users never read private donations).
            donationCount: (data.donationCount || 0) + 1,
          };
          if (isNewDonor) {
            updates.donorCount = (data.donorCount || 0) + 1;
          }
          // Auto-flip to 'completed' the first time we cross the goal.
          if (newAmount >= goal && data.status === "active" && goal > 0) {
            updates.status = "completed";
          }
          tx.update(campaignRef, updates);
          if (isNewDonor && donorMarkerRef) {
            tx.set(donorMarkerRef, {
              firstDonationAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        });

        logger.info("Campaign total updated", {
          donationId,
          campaignId,
          delta: amount,
        });
      } catch (err) {
        // Do NOT rethrow — Cloud Functions would retry on throw, which
        // causes double-counting on transient errors. We log and rely
        // on manual reconciliation via the NAD-27 transparency report.
        logger.error("Failed to update campaign total", {
          donationId,
          campaignId,
          error: err.message,
        });
      }
    },
);

// === NAD-27: Allocation invariant enforcement ===
exports.onAllocationCreate = onDocumentCreated(
    "allocations/{allocationId}",
    async (event) => {
      const allocationId = event.params.allocationId;
      const allocation = event.data && event.data.data();
      if (!allocation) {
        logger.warn("onAllocationCreate fired with no data", {allocationId});
        return;
      }

      const campaignId = allocation.campaignId;
      const amount = allocation.amount;
      if (!campaignId || typeof amount !== "number" || amount <= 0) {
        logger.error("Invalid allocation payload — rolling back", {
          allocationId,
          campaignId,
          amount,
        });
        await db.collection("allocations").doc(allocationId).delete();
        return;
      }

      try {
        await db.runTransaction(async (tx) => {
          const campaignRef = db.collection("campaigns").doc(campaignId);
          const campaignSnap = await tx.get(campaignRef);
          if (!campaignSnap.exists) {
            throw new Error(`Campaign ${campaignId} not found`);
          }
          const goalAmount = campaignSnap.data().goalAmount || 0;

          // Sum existing allocations for this campaign EXCLUDING the
          // just-created one (we'll add it if the invariant holds).
          const allocationsSnap = await tx.get(
              db
                  .collection("allocations")
                  .where("campaignId", "==", campaignId),
          );
          let allocated = 0;
          allocationsSnap.docs.forEach((doc) => {
            if (doc.id === allocationId) return;
            allocated += doc.data().amount || 0;
          });

          if (allocated + amount > goalAmount) {
            throw new Error(
                `Allocation invariant violated: existing ${allocated} + ` +
                `new ${amount} > goal ${goalAmount}`,
            );
          }
          // Invariant holds — nothing to mutate, the allocation stands.
        });

        logger.info("Allocation accepted", {
          allocationId,
          campaignId,
          amount,
        });
      } catch (err) {
        // Roll back the allocation by deleting it. Admin sees nothing
        // in transparency report; error log explains why.
        logger.error(
            "Allocation rejected — deleting to preserve invariant",
            {
              allocationId,
              campaignId,
              amount,
              error: err.message,
            },
        );
        await db
            .collection("allocations")
            .doc(allocationId)
            .delete()
            .catch((deleteErr) => {
              logger.error("Failed to delete rejected allocation", {
                allocationId,
                error: deleteErr.message,
              });
            });
      }
    },
);

// === NAD-21: Stripe Checkout — create session ===
// Callable from the client. amountSen is MYR sen (min 500 = RM 5).
// Returns {url} of the Stripe-hosted checkout page.
exports.createCheckoutSession = onCall(
    {secrets: [STRIPE_SECRET], region: "asia-southeast1"},
    async (request) => {
      const uid = request.auth && request.auth.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Sign in to donate.");
      }

      const {amountSen, campaignId, donorName, origin} = request.data || {};
      if (typeof amountSen !== "number" || amountSen < 500) {
        throw new HttpsError(
            "invalid-argument", "Minimum donation is RM 5.00 (500 sen).",
        );
      }
      if (!campaignId || typeof campaignId !== "string") {
        throw new HttpsError("invalid-argument", "campaignId is required.");
      }
      if (!origin || typeof origin !== "string") {
        throw new HttpsError("invalid-argument", "origin is required.");
      }

      // Confirm the campaign exists + is active before charging.
      const campaignSnap = await db.collection("campaigns").doc(campaignId).get();
      if (!campaignSnap.exists) {
        throw new HttpsError("not-found", "Campaign not found.");
      }
      if (campaignSnap.data().status !== "active") {
        throw new HttpsError(
            "failed-precondition", "This campaign is no longer accepting donations.",
        );
      }

      const stripe = require("stripe")(STRIPE_SECRET.value());
      try {
        const session = await stripe.checkout.sessions.create({
          mode: "payment",
          line_items: [
            {
              price_data: {
                currency: "myr",
                unit_amount: amountSen,
                product_data: {
                  name: `Donation — ${campaignSnap.data().title}`,
                },
              },
              quantity: 1,
            },
          ],
          // Metadata is echoed back in the webhook → used to write the
          // donation doc with the right donor + campaign attribution.
          metadata: {
            donorId: uid,
            campaignId,
            donorName: donorName || "Anonymous Supporter",
            amountSen: String(amountSen),
          },
          success_url:
            `${origin}/#/receipt?session_id={CHECKOUT_SESSION_ID}`,
          cancel_url: `${origin}/#/campaign/${campaignId}`,
        });
        logger.info("Checkout session created", {
          sessionId: session.id, campaignId, uid, amountSen,
        });
        return {url: session.url, sessionId: session.id};
      } catch (err) {
        logger.error("Stripe session creation failed", {error: err.message});
        throw new HttpsError("internal", "Could not start payment.");
      }
    },
);

// === NAD-21/26: Stripe webhook — authoritative payment confirmation ===
// Stripe POSTs here. On checkout.session.completed we write the
// donations/{id} doc (status=success), which triggers onDonationCreate
// to aggregate. Donations are ONLY ever created by a verified Stripe
// payment — the client cannot write donations directly (firestore.rules
// deny client create; this Function uses the admin service account).
exports.stripeWebhook = onRequest(
    {secrets: [STRIPE_SECRET, STRIPE_WEBHOOK_SECRET], region: "asia-southeast1"},
    async (req, res) => {
      const stripe = require("stripe")(STRIPE_SECRET.value());
      const signature = req.headers["stripe-signature"];

      let event;
      try {
        // rawBody is required for signature verification (Firebase
        // onRequest exposes it).
        event = stripe.webhooks.constructEvent(
            req.rawBody, signature, STRIPE_WEBHOOK_SECRET.value(),
        );
      } catch (err) {
        logger.error("Webhook signature verification failed", {
          error: err.message,
        });
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
      }

      if (event.type !== "checkout.session.completed") {
        // Acknowledge other events without acting.
        res.status(200).send("ignored");
        return;
      }

      const session = event.data.object;
      const md = session.metadata || {};
      const sessionId = session.id;

      // Idempotency: skip if a donation for this session already exists
      // (Stripe may retry webhooks).
      const existing = await db
          .collection("donations")
          .where("stripeSessionId", "==", sessionId)
          .limit(1)
          .get();
      if (!existing.empty) {
        logger.info("Duplicate webhook — donation already recorded", {sessionId});
        res.status(200).send("already-processed");
        return;
      }

      try {
        await db.collection("donations").add({
          donorId: md.donorId || "unknown",
          campaignId: md.campaignId,
          amount: Number(md.amountSen) || session.amount_total,
          transactionId: session.payment_intent || sessionId,
          stripeSessionId: sessionId,
          status: "success",
          donorName: md.donorName || "Anonymous Supporter",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info("Donation recorded from Stripe webhook", {
          sessionId, campaignId: md.campaignId, amountSen: md.amountSen,
        });
        res.status(200).send("ok");
      } catch (err) {
        logger.error("Failed to write donation from webhook", {
          sessionId, error: err.message,
        });
        // 500 → Stripe will retry, giving us another chance.
        res.status(500).send("write-failed");
      }
    },
);

// === NAD-39: FCM push on new volunteer activity ===
// When an admin/ngo publishes an activity, push a notification to the
// "new-activities" topic. Clients that subscribed (NotificationService)
// receive it; tapping opens the activity detail (data.route).
exports.onActivityCreate = onDocumentCreated(
    "activities/{activityId}",
    async (event) => {
      const activityId = event.params.activityId;
      const activity = event.data && event.data.data();
      if (!activity) {
        logger.warn("onActivityCreate fired with no data", {activityId});
        return;
      }
      const message = {
        topic: "new-activities",
        notification: {
          title: "New volunteer activity",
          body: activity.title || "A new way to help stray cats at UTM.",
        },
        data: {
          activityId,
          route: `/activity/${activityId}`,
        },
      };
      try {
        await admin.messaging().send(message);
        logger.info("Activity push sent", {activityId});
      } catch (err) {
        // Non-fatal — push delivery failure shouldn't block activity
        // creation. (e.g. topic has no subscribers yet.)
        logger.error("Activity push failed", {
          activityId, error: err.message,
        });
      }
    },
);
