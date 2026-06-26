/**
 * Demo reset + seed for Strayfriends PROD (strayfriends-utm).
 *
 * PREVIEW by default (no writes). To actually apply:
 *   export GOOGLE_APPLICATION_CREDENTIALS=~/Downloads/strayfriends-utm-...json
 *   APPLY=1 node demo_reset.js
 *
 * Phases:
 *   1. Capture existing photo URLs (to reuse for seeded reports/campaigns)
 *   2. Create/upsert demo accounts (volunteer, ngo) + reset admin password
 *   3. DELETE all docs in reports/campaigns/donations/allocations/activities/signups
 *   4. Seed campaigns, allocations, activities, signups, reports
 *
 * Money is integer sen (1 RM = 100 sen). currentAmount/donorCount are set
 * directly on campaigns (no donation docs seeded) so onDonationCreate does
 * not double-count. Allocation sums stay well under goalAmount.
 */
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();
const { Timestamp, GeoPoint, FieldValue } = admin.firestore;

const APPLY = process.env.APPLY === "1";
const PW = process.env.DEMO_PW || (() => { throw new Error("Set DEMO_PW env to the demo password before running with APPLY=1"); })();
const tag = APPLY ? "APPLY" : "PREVIEW";
const log = (...a) => console.log(`[${tag}]`, ...a);

// UTM Johor Bahru campus center
const UTM = { lat: 1.5587, lng: 103.6370 };
const near = (dLat, dLng) => new GeoPoint(UTM.lat + dLat, UTM.lng + dLng);
const days = (n) => Timestamp.fromDate(new Date(Date.now() + n * 864e5));
const ago = (n) => Timestamp.fromDate(new Date(Date.now() - n * 864e5));

const COLLECTIONS = ["reports", "campaigns", "donations", "allocations", "activities", "signups"];

async function ensureUser(email, fullName, role) {
  let uid;
  try {
    const u = await auth.getUserByEmail(email);
    uid = u.uid;
    if (APPLY) await auth.updateUser(uid, { password: PW, displayName: fullName });
    log(`account exists: ${email} (uid=${uid.slice(0, 8)}) -> password reset, role=${role}`);
  } catch (e) {
    if (APPLY) {
      const u = await auth.createUser({ email, password: PW, displayName: fullName });
      uid = u.uid;
    } else {
      uid = `NEW_${email}`;
    }
    log(`account create: ${email} -> role=${role}`);
  }
  if (APPLY) {
    await db.collection("users").doc(uid).set(
      { email, fullName, role, createdAt: Timestamp.now() },
      { merge: true }
    );
  }
  return uid;
}

async function wipe() {
  for (const c of COLLECTIONS) {
    const snap = await db.collection(c).get();
    log(`wipe ${c}: ${snap.size} docs`);
    if (APPLY) {
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
  }
}

async function main() {
  // --- Phase 1: capture reusable photo URLs from current data ---
  const repSnap = await db.collection("reports").get();
  const campSnap = await db.collection("campaigns").get();
  const photoUrls = repSnap.docs.map((d) => d.data().photoUrl).filter(Boolean);
  const campImgs = campSnap.docs.map((d) => d.data().imageUrl).filter(Boolean);
  log(`captured ${photoUrls.length} report photoUrls, ${campImgs.length} campaign imageUrls`);
  const FALLBACK_CAT =
    "https://images.unsplash.com/photo-1574158622682-e40e69881006?w=800&q=80";
  const photo = (i) => photoUrls[i % photoUrls.length] || FALLBACK_CAT;
  const campImg = (i) => campImgs[i % (campImgs.length || 1)] || FALLBACK_CAT;

  // --- Phase 2: accounts ---
  const volunteerUid = await ensureUser("volunteer@strayfriends.com", "Aisha Rahman", "user");
  const ngoUid = await ensureUser("ngo@strayfriends.com", "PAWS Johor", "ngo");
  const adminUid = await ensureUser("admin@strayfriends.com", "Strayfriends Admin", "admin");

  // For roster realism, find two existing smoke users (don't fail if missing)
  const extras = [];
  for (const em of ["john.doe@smoke.test", "jane.doe@smoke.test"]) {
    try { const u = await auth.getUserByEmail(em); extras.push({ uid: u.uid, name: em.split("@")[0].replace(".", " ") }); } catch {}
  }

  // --- Phase 3: wipe ---
  await wipe();

  // --- Phase 4: seed ---
  const set = async (col, id, data) => {
    log(`seed ${col}/${id}: ${data.title || data.purpose || data.description?.slice(0, 40) || ""}`);
    if (APPLY) await db.collection(col).doc(id).set(data);
  };

  // Campaigns (money in sen)
  const campaigns = [
    { id: "vet_injured_kittens", title: "Emergency Vet Fund: Injured Kittens at KTR",
      description: "Three kittens found injured near Kolej Tun Razak need urgent vet care — X-rays, antibiotics, and recovery food. Every ringgit goes to their treatment.",
      goalAmount: 300000, currentAmount: 115000, donorCount: 14, status: "active" },
    { id: "tnr_sterilisation", title: "Sterilisation Drive: UTM Cat Colony (TNR)",
      description: "Trap-Neuter-Return for the UTM campus colony. Humane population control keeps the cats healthy and reduces strays long-term.",
      goalAmount: 500000, currentAmount: 234000, donorCount: 31, status: "active" },
    { id: "food_stations", title: "Monthly Food & Water Stations",
      description: "Keep the campus feeding stations stocked. Funds buy quality cat food and fresh water refills across 6 colony points.",
      goalAmount: 150000, currentAmount: 88000, donorCount: 22, status: "active" },
    { id: "recovery_oyen", title: "Recovery Fund: Oyen the Rescued Tomcat",
      description: "Oyen was hit by a car at the FKE walkway. Thanks to donors, his surgery and rehab are fully funded. He is now recovering well!",
      goalAmount: 120000, currentAmount: 120000, donorCount: 18, status: "completed" },
  ];
  for (let i = 0; i < campaigns.length; i++) {
    const c = campaigns[i];
    await set("campaigns", c.id, {
      title: c.title, description: c.description,
      goalAmount: c.goalAmount, currentAmount: c.currentAmount, donorCount: c.donorCount,
      imageUrl: campImg(i), status: c.status, createdBy: ngoUid,
      createdAt: ago(20 - i * 3), endsAt: days(30),
    });
  }

  // Allocations for vet_injured_kittens (sum 83000 <= currentAmount 115000 <= goalAmount 300000)
  const allocs = [
    { purpose: "Vet consultation & X-ray — 3 kittens", amount: 40000 },
    { purpose: "Antibiotics & wound dressing", amount: 25000 },
    { purpose: "Special recovery food (2 weeks)", amount: 18000 },
  ];
  for (let i = 0; i < allocs.length; i++) {
    await set("allocations", `vet_alloc_${i + 1}`, {
      campaignId: "vet_injured_kittens", amount: allocs[i].amount, purpose: allocs[i].purpose,
      createdBy: ngoUid, createdAt: ago(5 - i),
    });
  }

  // Activities (upcoming, NGO-owned)
  const activities = [
    { id: "feeding_ktr", title: "Weekend Feeding Round — KTR Colony",
      description: "Join PAWS Johor to feed and health-check the strays around Kolej Tun Razak. Water provided; wear comfortable shoes.",
      location: "Kolej Tun Razak (KTR), UTM", when: 5, slots: 8, taken: 3 },
    { id: "tnr_catch_day", title: "TNR Catch Day — Arked Cengal",
      description: "Help humanely trap colony cats for the sterilisation drive. Training given on the day; no experience needed.",
      location: "Arked Cengal, UTM", when: 9, slots: 12, taken: 0 },
    { id: "adoption_day", title: "Cat Adoption & Awareness Day @ DSI",
      description: "Booth duty, cat handling, and visitor guidance at our adoption fair. Help rescued cats find forever homes.",
      location: "Dewan Sultan Iskandar (DSI), UTM", when: 14, slots: 20, taken: 0 },
  ];
  for (const a of activities) {
    await set("activities", a.id, {
      title: a.title, description: a.description, location: a.location,
      dateTime: days(a.when), slots: a.slots, slotsRemaining: a.slots - a.taken,
      imageUrl: FALLBACK_CAT, createdBy: ngoUid, status: "upcoming", createdAt: ago(3),
    });
  }
  // Signups for feeding_ktr roster (Aisha + up to 2 smoke users) = 3 taken
  const roster = [{ uid: volunteerUid, name: "Aisha Rahman" }, ...extras].slice(0, 3);
  for (const r of roster) {
    await set("signups", `feeding_ktr_${r.uid}`, {
      volunteerId: r.uid, activityId: "feeding_ktr", volunteerName: r.name, signedAt: ago(1),
    });
  }

  // Reports (around UTM; reporter = Aisha)
  const reports = [
    { id: null, condition: "injured", status: "pending", dLat: 0.0008, dLng: -0.0010,
      label: "Perpustakaan Sultanah Zanariah (PSZ), main entrance",
      desc: "Ginger cat limping badly on its front-right leg near the library steps. Seems in pain, not putting weight on the paw." },
    { id: null, condition: "sick", status: "pending", dLat: -0.0006, dLng: 0.0009,
      label: "Kolej Tun Razak (KTR) cafeteria",
      desc: "Small kitten with crusty, swollen eyes — looks like an untreated eye infection. Still eating but lethargic." },
    { id: null, condition: "healthy", status: "pending", dLat: 0.0012, dLng: 0.0006,
      label: "Arked Meranti food court",
      desc: "Friendly tabby colony of about 5 cats, all look well-fed and active. Logging for the colony map." },
    { id: null, condition: "injured", status: "resolved", dLat: -0.0011, dLng: -0.0007,
      label: "FKE walkway",
      desc: "Cat injured by a passing car — rescued, treated, and now recovering (see Oyen recovery campaign)." },
  ];
  for (let i = 0; i < reports.length; i++) {
    const r = reports[i];
    await set("reports", `demo_report_${i + 1}`, {
      userId: volunteerUid, reporterName: "Aisha Rahman", photoUrl: photo(i),
      location: near(r.dLat, r.dLng), locationLabel: r.label,
      condition: r.condition, description: r.desc, status: r.status,
      createdAt: ago(reports.length - i),
    });
  }

  log("DONE.", APPLY ? "Data applied to PROD." : "Preview only — re-run with APPLY=1 to write.");
}

main().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
