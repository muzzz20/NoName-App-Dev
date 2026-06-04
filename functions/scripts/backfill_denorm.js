/**
 * One-time backfill for denormalized fields introduced with the
 * visitor-access fixes:
 *
 *   1. reports/{id}.reporterName  ← users/{userId}.fullName
 *      So the public Report Detail (UC-07) can show the reporter without
 *      reading the private users collection.
 *
 *   2. campaigns/{id}.donorCount + .donationCount  ← successful donations
 *      Plus a campaigns/{id}/donors/{donorId} marker per unique donor
 *      (matches what onDonationCreate now maintains going forward).
 *      So the public Campaign Detail (UC-11) + dashboards can show counts
 *      without reading the private donations collection.
 *
 * Idempotent: re-running recomputes campaign counts authoritatively and
 * only fills reporterName where missing.
 *
 * Usage (from the functions/ directory):
 *   # Dry run — prints what WOULD change, writes nothing:
 *   node scripts/backfill_denorm.js
 *   # Commit — actually writes:
 *   node scripts/backfill_denorm.js --commit
 *
 * Auth: uses Application Default Credentials. Either
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 * or run in an environment already authenticated to the project.
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const COMMIT = process.argv.includes("--commit");

function log(...args) {
  console.log(COMMIT ? "[commit]" : "[dry-run]", ...args);
}

async function backfillReporterNames() {
  console.log("\n=== reports.reporterName ===");
  const reports = await db.collection("reports").get();
  const nameCache = new Map();
  let filled = 0;
  let skipped = 0;

  for (const doc of reports.docs) {
    const data = doc.data();
    if (data.reporterName && String(data.reporterName).trim() !== "") {
      skipped++;
      continue;
    }
    const userId = data.userId;
    if (!userId) {
      skipped++;
      continue;
    }
    let name = nameCache.get(userId);
    if (name === undefined) {
      const userSnap = await db.collection("users").doc(userId).get();
      name = userSnap.exists ? userSnap.data().fullName || null : null;
      nameCache.set(userId, name);
    }
    if (!name) {
      skipped++;
      continue;
    }
    log(`report ${doc.id} → reporterName="${name}"`);
    if (COMMIT) await doc.ref.update({reporterName: name});
    filled++;
  }
  console.log(`reports: filled=${filled}, skipped=${skipped}`);
}

async function backfillCampaignDonorCounts() {
  console.log("\n=== campaigns.donorCount / donationCount ===");
  const campaigns = await db.collection("campaigns").get();

  for (const camp of campaigns.docs) {
    const donations = await db
        .collection("donations")
        .where("campaignId", "==", camp.id)
        .where("status", "==", "success")
        .get();

    const donorIds = new Set();
    let donationCount = 0;
    for (const d of donations.docs) {
      donationCount++;
      const donorId = d.data().donorId;
      if (donorId) donorIds.add(donorId);
    }
    const donorCount = donorIds.size;

    log(
        `campaign ${camp.id} → donorCount=${donorCount}, ` +
        `donationCount=${donationCount}`,
    );
    if (COMMIT) {
      await camp.ref.update({donorCount, donationCount});
      // Recreate donor markers so future onDonationCreate de-dupes correctly.
      const batch = db.batch();
      for (const donorId of donorIds) {
        batch.set(
            camp.ref.collection("donors").doc(donorId),
            {firstDonationAt: admin.firestore.FieldValue.serverTimestamp()},
            {merge: true},
        );
      }
      await batch.commit();
    }
  }
  console.log(`campaigns processed: ${campaigns.size}`);
}

(async () => {
  try {
    await backfillReporterNames();
    await backfillCampaignDonorCounts();
    console.log(
        COMMIT ? "\nBackfill complete." : "\nDry run complete — no writes.",
    );
    process.exit(0);
  } catch (err) {
    console.error("Backfill failed:", err);
    process.exit(1);
  }
})();
