/**
 * Configure CORS on the Firebase Storage bucket so Flutter **Web** can
 * display images via Image.network.
 *
 * Why this is needed: in a browser, Image.network fetches the file over XHR,
 * which is subject to CORS. If the bucket has no CORS config, the browser
 * blocks the response and the app shows a broken-image icon plus:
 *   "No 'Access-Control-Allow-Origin' header is present on the requested
 *    resource" (net::ERR_FAILED, even when the GET itself is 200 OK).
 * Native iOS/Android are NOT affected (no CORS in native HTTP).
 *
 * We only need read (GET) access — uploads go through the SDK, not XHR. The
 * images served here are already public (the visitor feed shows them), so a
 * wildcard origin for GET does not widen access; storage.rules still govern
 * *who* may read. Tighten `origin` to specific hosts if you prefer.
 *
 * Run from the functions/ directory (gcloud / gsutil NOT required):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   node scripts/set_cors.js
 *
 * (Same service-account key as scripts/backfill_denorm.js — one download
 * unlocks both.)
 *
 * gcloud alternative, if you ever install it:
 *   gsutil cors set cors.json gs://strayfriends-utm.firebasestorage.app
 */

const admin = require("firebase-admin");

admin.initializeApp();

const BUCKET = "strayfriends-utm.firebasestorage.app";

const CORS = [
  {
    origin: ["*"], // GET-only on already-public images; tighten if desired
    method: ["GET"],
    responseHeader: ["Content-Type"],
    maxAgeSeconds: 3600,
  },
];

async function main() {
  const bucket = admin.storage().bucket(BUCKET);
  await bucket.setCorsConfiguration(CORS);
  console.log("✓ CORS configured on", bucket.name);
  console.log(JSON.stringify(CORS, null, 2));
}

main().catch((e) => {
  console.error("Failed to set CORS:", e);
  process.exit(1);
});
