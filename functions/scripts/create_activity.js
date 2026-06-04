/**
 * Create a sample volunteer activity in PROD, attributed to Strayfriends NGO
 * (the admin@strayfriends.com account), so the Volunteer flow has data to
 * walk through. Idempotent — fixed doc id, safe to re-run.
 *
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   node functions/scripts/create_activity.js
 */
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const {Timestamp} = admin.firestore;

async function main() {
  const user = await admin.auth().getUserByEmail("admin@strayfriends.com");
  const createdBy = user.uid;
  const dateTime = Timestamp.fromDate(new Date(Date.now() + 7 * 864e5)); // +7d

  await db.collection("activities").doc("ngo_feeding_round").set({
    title: "Weekend feeding round — KTR colony",
    description:
      "Join Strayfriends NGO to feed and check on the stray cats around " +
      "Kolej Tun Razak. Water provided; bring comfortable shoes.",
    location: "Kolej Tun Razak (KTR), UTM",
    dateTime,
    slots: 8,
    slotsRemaining: 8,
    status: "upcoming",
    createdBy,
    createdAt: Timestamp.now(),
  });

  console.log(`Activity 'ngo_feeding_round' created (createdBy=${createdBy}).`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
