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
 * Deploy: `firebase deploy --only functions`
 * Local:  `npm run serve` (uses Firebase emulator suite)
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

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
          const snap = await tx.get(campaignRef);
          if (!snap.exists) {
            throw new Error(
                `Campaign ${campaignId} not found for donation ${donationId}`,
            );
          }
          const data = snap.data();
          const current = data.currentAmount || 0;
          const goal = data.goalAmount || 0;
          const newAmount = current + amount;

          const updates = {currentAmount: newAmount};
          // Auto-flip to 'completed' the first time we cross the goal.
          if (newAmount >= goal && data.status === "active" && goal > 0) {
            updates.status = "completed";
          }
          tx.update(campaignRef, updates);
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
