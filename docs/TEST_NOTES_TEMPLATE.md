# Test Notes Template — Sprint 2

> Use this template to record test cases **as you build**. Khalisha
> (QA) will consolidate everyone's notes into the official Sprint 2
> TRD at sprint close. Filling rows consistently here means **zero
> rework** at sprint close.
>
> On day 1 of Sprint 2, **one person** copies this file to
> `docs/TEST_NOTES_sprint2.md`. Everyone then appends rows to that
> shared file. Do **not** edit this template file itself.

---

## How to use this template

1. Find your assigned Use Case IDs in the **Jira board** (NAD
   project) — open your ticket, the UC reference is in the
   description. Don't guess from `BACKLOG.md` planning IDs; pull
   the live UCs from Jira.
2. For every Acceptance Criterion in your story, write **at least
   one test case row** below.
3. Fill **all 9 columns** — leave `—` only if truly N/A.
4. If a test fails, set Actual Result to the failure description,
   pick a Severity, and either (a) fix it and update the row, or
   (b) file a new Jira ticket and link it in Root Cause.
5. Commit your rows in the same PR as the feature
   (`docs: NAD-N add UC-XX test notes`).

---

## Severity codes (per lecturer template — DO NOT change)

| Code | Label | Meaning |
|---|---|---|
| **1** | Fatal | Blocks core flow, data loss, security hole, crash |
| **2** | Serious | Feature partially broken, workaround exists |
| **3** | Minor | Cosmetic, edge case, validation polish |
| **—** | N/A | Test passed — no defect found |

---

## Test Case Table

> Copy a row, fill it in, leave the header + this sentence intact.

| Use Case ID | Test Case ID | Description | Procedure / Steps | Expected Result | Actual Result | Severity | Date Resolved | Root Cause |
|---|---|---|---|---|---|---|---|---|
| UC-XX | TC001-UCXX | <short test purpose> | 1. <step><br>2. <step><br>3. <step> | <what should happen> | <Pass — verified on X> *or* <Fail — what broke> | — *or* 1/2/3 | — *or* DD/MM/YYYY | — *or* <commit hash / Jira ID / one-line cause> |

---

## Filled example (taken from Sprint 1 TRD — for reference)

| Use Case ID | Test Case ID | Description | Procedure / Steps | Expected Result | Actual Result | Severity | Date Resolved | Root Cause |
|---|---|---|---|---|---|---|---|---|
| UC-05 | TC001-UC05 | Submit valid report — happy path | 1. Tap "Report a Cat" FAB<br>2. Take photo<br>3. Tap "Use my location"<br>4. Pick Condition: Injured<br>5. Tap Submit | Loading spinner → Success screen; Firestore `reports/{id}` created; photo URL in Supabase public bucket | Pass — full end-to-end verified on Pixel 9 emulator | — | 14/5/2026 | BR-001 (initial RLS denial fixed by Supabase anon sign-in, commit ecefbe6) |
| UC-05 | TC005-UC05 | Geolocation fallback when GPS unavailable | 1. On laptop without GPS, tap "Use my location"<br>2. Wait for error | "Could not get location" + "Use UTM campus instead" fallback button appears; tap fallback sets pin at (1.5599, 103.6418) | Pass — reproduced and fallback verified | 2 | 14/5/2026 | BR-002 (geolocator web limitation; UTM fallback added commit 89b8c1a) |

---

## Per-developer ownership (fill at sprint start)

| Developer | Assigned UCs | Story tickets |
|---|---|---|
| Faiz | UC-XX, UC-XX | NAD-XX, NAD-XX |
| Baqir | UC-XX | NAD-XX |
| Ahmad | UC-XX | NAD-XX |
| Khalief | UC-XX | NAD-XX |
| Khalisha | All — consolidates into final TRD | — |

> Confirm this table with Baqir (PM) at Sprint 2 planning before
> anyone starts writing rows.

---

## Formatting rules (so consolidation is painless)

- **Date format:** DD/MM/YYYY (matches lecturer template — e.g.
  `23/4/2026`)
- **Procedure / Steps:** numbered, use `<br>` for line breaks inside
  the cell (Markdown table doesn't support real newlines)
- **Test Case ID format:** `TC<NNN>-UC<NN>` zero-padded —
  e.g. `TC001-UC09`, `TC012-UC09`
- **Pass row:** Actual Result starts with `Pass — <evidence>` and
  Severity is `—`
- **Fail row:** Actual Result starts with `Fail — <what broke>` and
  Severity is `1`, `2`, or `3`
- **Pending row** (code exists but not manually exercised): Actual
  Result starts with `Pending — <reason>`
- **Root Cause for resolved defects:** link the fixing commit hash
  **or** the Jira ticket ID. One-line explanation, not a paragraph.

---

**Template version:** 1.0 · **Source format:** matches the lecturer-provided TRD template (`SCSJ3104/GROUP-NoName/Test/00x` v1.0) — Faiz/Khalisha hold the canonical TRD file outside this repo.
