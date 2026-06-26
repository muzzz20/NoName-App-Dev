/* Read-only snapshot of PROD Firestore + Auth for demo readiness. No writes. */
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

async function listUsers() {
  const out = [];
  let res = await admin.auth().listUsers(1000);
  out.push(...res.users);
  while (res.pageToken) { res = await admin.auth().listUsers(1000, res.pageToken); out.push(...res.users); }
  return out;
}

async function roleOf(uid) {
  const d = await db.collection("users").doc(uid).get();
  return d.exists ? (d.data().role || "user") : "(no profile)";
}

async function main() {
  console.log("=== AUTH USERS ===");
  const users = await listUsers();
  for (const u of users) {
    const role = await roleOf(u.uid);
    console.log(`  ${u.email || "(no email)"}  | role=${role} | uid=${u.uid.slice(0,8)}`);
  }
  console.log(`  total: ${users.length}`);

  const cols = ["reports", "campaigns", "donations", "allocations", "activities", "signups"];
  console.log("\n=== COLLECTIONS ===");
  for (const c of cols) {
    const snap = await db.collection(c).get();
    console.log(`  ${c}: ${snap.size}`);
  }

  console.log("\n=== CAMPAIGNS (detail) ===");
  const camps = await db.collection("campaigns").get();
  camps.forEach((d) => {
    const x = d.data();
    console.log(`  [${x.status}] ${x.title} | goal=${x.goalAmount} cur=${x.currentAmount}`);
  });

  console.log("\n=== ACTIVITIES (detail) ===");
  const acts = await db.collection("activities").get();
  acts.forEach((d) => {
    const x = d.data();
    console.log(`  [${x.status}] ${x.title} | slots=${x.slotsRemaining}/${x.slots}`);
  });

  console.log("\n=== REPORTS (status tally) ===");
  const reps = await db.collection("reports").get();
  const tally = {};
  reps.forEach((d) => { const s = d.data().status || "?"; tally[s] = (tally[s]||0)+1; });
  console.log("  ", JSON.stringify(tally));
}

main().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
