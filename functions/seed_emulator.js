/**
 * Seed the Firebase Emulator Suite with a known state for the integration
 * tests. Idempotent (fixed doc ids + set; catch user-already-exists), so it is
 * safe to re-run.
 *
 * NEVER touches prod — it refuses to run unless FIRESTORE_EMULATOR_HOST is set,
 * which `firebase emulators:exec` injects automatically:
 *
 *   firebase emulators:exec --only auth,firestore,storage \
 *     'node functions/seed_emulator.js'
 */
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error("Refusing to seed: FIRESTORE_EMULATOR_HOST not set (not an emulator).");
  process.exit(1);
}

admin.initializeApp({projectId: "strayfriends-utm"});
const db = admin.firestore();
const auth = admin.auth();
const {Timestamp, GeoPoint} = admin.firestore;

const IMG =
  "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=800";

async function ensureUser(uid, email, password, fullName, role) {
  try {
    await auth.createUser({uid, email, password, displayName: fullName});
  } catch (e) {
    if (e.code !== "auth/uid-already-exists" &&
        e.code !== "auth/email-already-exists") {
      throw e;
    }
  }
  await db.collection("users").doc(uid).set({
    email, fullName, role, createdAt: Timestamp.now(),
  });
}

async function main() {
  const now = Date.now();
  const plusDays = (d) => Timestamp.fromDate(new Date(now + d * 864e5));

  // --- Accounts (match the integration-test credentials) ---
  await ensureUser("seed_john", "john.doe@smoke.test", "Strayfriends123!", "John Doe", "user");
  await ensureUser("seed_jane", "jane.doe@smoke.test", "Strayfriends123!", "Jane Doe", "user");
  await ensureUser("seed_admin", "admin@strayfriends.com", "admin123", "Admin", "admin");

  // --- Campaigns (1 active w/ allocations summing to goal, 1 completed) ---
  await db.collection("campaigns").doc("seed_active").set({
    title: "Kucing Melana", description: "dia sakit",
    goalAmount: 100000, currentAmount: 0, status: "active",
    createdBy: "seed_admin", imageUrl: IMG,
    donorCount: 0, donationCount: 0,
    createdAt: Timestamp.now(), endsAt: plusDays(29),
  });
  await db.collection("campaigns").doc("seed_completed").set({
    title: "Smoke Test — UI Verify", description: "Completed sample",
    goalAmount: 10000, currentAmount: 10000, status: "completed",
    createdBy: "seed_admin", imageUrl: IMG,
    donorCount: 1, donationCount: 1,
    createdAt: Timestamp.now(), endsAt: plusDays(29),
  });
  await db.collection("allocations").doc("seed_alloc1").set({
    campaignId: "seed_active", amount: 50000, purpose: "Food",
    createdBy: "seed_admin", createdAt: Timestamp.now(),
  });
  await db.collection("allocations").doc("seed_alloc2").set({
    campaignId: "seed_active", amount: 50000, purpose: "Vet care",
    createdBy: "seed_admin", createdAt: Timestamp.now(),
  });

  // --- Sighting reports (standalone — no cat linkage) ---
  await db.collection("reports").doc("seed_report1").set({
    userId: "seed_admin", reporterName: "Admin", photoUrl: IMG,
    location: new GeoPoint(1.5587, 103.6386), locationLabel: "Kolej Tun Razak",
    condition: "injured", description: "Cat limping near KTR",
    status: "pending", createdAt: Timestamp.now(),
  });
  await db.collection("reports").doc("seed_report2").set({
    userId: "seed_john", reporterName: "John Doe", photoUrl: IMG,
    location: new GeoPoint(1.5601, 103.6400), locationLabel: "Arked Meranti",
    condition: "healthy", description: "Friendly tabby",
    status: "pending", createdAt: Timestamp.now(),
  });
  // John's report that is NO LONGER pending — owner edit must be denied.
  await db.collection("reports").doc("seed_report3").set({
    userId: "seed_john", reporterName: "John Doe", photoUrl: IMG,
    location: new GeoPoint(1.5610, 103.6420), locationLabel: "Library",
    condition: "injured", description: "Resolved sighting",
    status: "resolved", createdAt: Timestamp.now(),
  });

  // --- Upcoming volunteer activity ---
  await db.collection("activities").doc("seed_activity1").set({
    title: "Evening feeding round", description: "Feed the KTR colony",
    location: "Kolej Tun Razak", dateTime: plusDays(3),
    slots: 10, slotsRemaining: 10, status: "upcoming",
    createdBy: "seed_admin", createdAt: Timestamp.now(),
  });

  console.log("Seed complete: 3 users, 2 campaigns, 2 allocations, 3 reports, 1 activity.");
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
