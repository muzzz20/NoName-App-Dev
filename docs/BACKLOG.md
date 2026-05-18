# Strayfriends — Product Backlog

> Project: **Strayfriends** · Course: SCSJ3104 · Group: NoName
> Total: **70 stories** across **4 sprints** (~306 story points)
> Last updated: 2026-05-14

> ⚠️ **READ FIRST — ID numbering:**
> The `STRAY-1` ... `STRAY-70` IDs in this document are **planning
> labels** from the original backlog draft. The **live Jira tickets
> are `NAD-N`** on https://noname1.atlassian.net and the numbers
> **do NOT match 1:1** (e.g., `STRAY-10` in this file is not the
> same ticket as `NAD-10` on Jira). When working on a story, always
> verify the live `NAD-N` ID by searching the story title in the
> Jira board. For commit messages, branch names, and PRs, use the
> live `NAD-N` ID — never the planning `STRAY-N` ID.

---

## Table of Contents

1. [Team & Roles](#team--roles)
2. [Epic Structure](#epic-structure)
3. [Schedule](#schedule)
4. [Definition of Done](#definition-of-done)
5. [Sprint 1 — Reporting + Auth](#sprint-1--reporting--auth)
6. [Sprint 2 — Fundraising](#sprint-2--fundraising)
7. [Sprint 3 — Volunteer + Dashboards](#sprint-3--volunteer--dashboards)
8. [Sprint 4 — Testing & Release](#sprint-4--testing--release)
9. [Use Case Master List](#use-case-master-list)
10. [Workload Distribution](#workload-distribution)

---

## Team & Roles

| Name | Role | Jira Username (TBD) |
|---|---|---|
| Baqir Tsaqib Hakim | Project Manager | `baqir` |
| Faiz Syuhada | Lead Developer | `faiz` |
| Ahmad Muzhaffar Prihantony | UI/UX Designer | `ahmad` |
| Khalief Zamzam Mahendra | UI/UX Designer | `khalief` |
| Khalisha Afifah Sekarbyovi | QA Engineer | `khalisha` |

> ⚠️ The submitted SPP has Khalisha/Khalief swapped — update the SPP to match this table.

---

## Epic Structure

| Key | Epic | Sprint | Owner |
|---|---|---|---|
| STRAY-E1 | User & Auth Foundation | 1 | Faiz |
| STRAY-E2 | Cat Reporting Module | 1 | Faiz |
| STRAY-E3 | Fundraising Module | 2 | Faiz |
| STRAY-E4 | Volunteer Coordination Module | 3 | Faiz |
| STRAY-E5 | Stakeholder Dashboards | 3-4 | Ahmad |
| STRAY-E6 | Testing, Hardening & Release | 4 | Khalisha |

---

## Schedule

| Milestone | Sprint | Focus | Target Date | Release |
|---|---|---|---|---|
| M0-M1 | Pre-Sprint | Proposal + Project Planning | Apr 12 | — |
| M2 | Sprint 1 | Reporting + Auth | Apr 16 | v0.1.0 |
| M3 | Sprint 2 | Fundraising | Apr 23 | v0.2.0 |
| M4 | Sprint 3 | Volunteer + Dashboards | Apr 30 | v0.3.0 |
| M5 | Sprint 4 | Testing & Hardening | May 7 | v1.0.0 |
| M6 | Release | Final demo + presentation | Jun 11 | — |

---

## Definition of Done

Every story is "Done" only when ALL of these are true:

1. Code merged to `main` via PR; **PR linked to Jira issue** (commit message contains `STRAY-X`)
2. All acceptance criteria met (verified by QA)
3. Test case written in TRD with status (pass/fail) recorded
4. Demo-able from Jira Board's DONE column
5. At least one discussion comment in Jira from another team member

---

# Sprint 1 — Reporting + Auth

**Sprint Goal:** A UTM student can install Strayfriends, register, log in, and submit a cat sighting (photo + map + condition) — then see that report appear in the public feed.

**Release:** v0.1.0 · **Items:** 20 · **Points:** 88

## Stories

### STRAY-1 — Firebase + Flutter + GitHub project init
- **Epic:** STRAY-E1 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest
- **Description:** Set up the foundational project skeleton.
- **Acceptance Criteria:**
  - Given a new project setup, when I clone the repo and run `flutter run`, then the app launches on Android/iOS/Web
  - Firebase project connected (Auth + Firestore enabled)
  - Supabase project connected for object storage (free tier, no card required)
  - `.gitignore` excludes `google-services.json` and secrets
  - README documents setup steps

### STRAY-2 — Jira board setup + GitHub-Jira commit linking
- **Epic:** — · **Assignee:** Baqir · **SP:** 3 · **Priority:** Highest
- **Description:** Establish project management infrastructure.
- **Acceptance Criteria:**
  - Jira project exists with columns: Backlog / To Do / In Progress / In Review / Done
  - Sprint 1 created with start/end dates
  - GitHub commits referencing `STRAY-X` appear in that issue's Development panel

### STRAY-3 — Design system + style guide in Figma
- **Epic:** STRAY-E2 · **Assignee:** Khalief · **SP:** 5 · **Priority:** High
- **Description:** Define visual foundation for the entire app.
- **Acceptance Criteria:**
  - Color palette, typography, spacing, button states defined
  - Logo and app icon present
  - Components (Button, Input, Card) documented with variants

### STRAY-4 — Sprint 1 wireframes (auth + reporting)
- **Epic:** STRAY-E2 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** High
- **Description:** Low-fidelity flow design for Sprint 1 screens.
- **Acceptance Criteria:**
  - Wireframes for: Register, Login, Profile, Feed, Submit Report, Report Detail, My Reports
  - User flow arrows connect screens

### STRAY-5 — Sprint 1 hi-fi mockups
- **Epic:** STRAY-E2 · **Assignee:** Khalief · **SP:** 5 · **Priority:** High
- **Description:** Production-ready visual designs for Sprint 1.
- **Acceptance Criteria:**
  - Every Sprint 1 screen has a hi-fi mockup using the design system
  - Mockups reviewed and approved by at least one teammate in Figma comments

### STRAY-6 — Firebase Auth backend
- **Epic:** STRAY-E1 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-01, 02, 03
- **Description:** Implement register/login/logout backend.
- **Acceptance Criteria:**
  - `registerUser(email, password)` creates Firebase Auth user + `users/{uid}` doc
  - `loginUser(email, password)` returns valid session
  - `logoutUser()` clears the session
  - Invalid credentials return clear error codes

### STRAY-7 — Auth UI screens (Register/Login/Profile)
- **Epic:** STRAY-E1 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-01, 02, 04
- **Description:** Flutter screens for authentication.
- **Acceptance Criteria:**
  - Register screen has email, password, confirm password, full name fields
  - Login screen has email + password + forgot password link
  - Profile screen shows current user info
  - Screens follow Figma mockups

### STRAY-8 — Auth integration (wire UI to Firebase)
- **Epic:** STRAY-E1 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest · **UC:** UC-01 to 04
- **Description:** Connect auth UI to Firebase backend.
- **Acceptance Criteria:**
  - Valid registration redirects to Reports Feed
  - Invalid input shows inline validation errors
  - Wrong password shows "Invalid email or password"
  - Logged-in users skip login screen on app restart

### STRAY-9 — Reports backend (Firestore CRUD)
- **Epic:** STRAY-E2 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-05
- **Description:** Backend data layer for reports.
- **Acceptance Criteria:**
  - `reports/{id}` doc has: userId, photoUrl, geopoint, condition, description, createdAt
  - List all reports ordered by createdAt desc
  - Filter reports by userId (for My Reports)
  - Firestore security rules prevent unauthenticated writes

### STRAY-10 — Photo upload + geolocation services
- **Epic:** STRAY-E2 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-05
- **Description:** Media upload and location capture services.
- **Acceptance Criteria:**
  - Photo uploads to Supabase Storage (bucket `cat-photos`), returns public URL
  - Images compressed to under 2MB before upload
  - `getCurrentLocation()` accurate to within 50m
  - Users can pick location manually on map

### STRAY-11 — Submit Report screen UI
- **Epic:** STRAY-E2 · **Assignee:** Khalief · **SP:** 5 · **Priority:** Highest · **UC:** UC-05
- **Description:** Form for submitting cat sighting.
- **Acceptance Criteria:**
  - Fields: Photo (camera/gallery), Location (auto/manual), Condition (Healthy/Injured/Sick), Description
  - Submit button disabled until photo + location + condition are set
  - Loading spinner shows during submission

### STRAY-12 — Reports Feed screen UI
- **Epic:** STRAY-E2 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-06
- **Description:** Browse all submitted reports.
- **Acceptance Criteria:**
  - Scrollable list of cards (photo, condition badge, location, time ago)
  - Pull-to-refresh reloads
  - Empty state shows when no reports
  - Newest first

### STRAY-13 — Report Detail screen UI
- **Epic:** STRAY-E2 · **Assignee:** Khalief · **SP:** 3 · **Priority:** High · **UC:** UC-07
- **Description:** View a single report in detail.
- **Acceptance Criteria:**
  - Shows full photo, condition, description, map pin, reporter name, timestamp
  - Back button returns to Feed

### STRAY-14 — My Reports screen UI
- **Epic:** STRAY-E2 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** High · **UC:** UC-08
- **Description:** View user's own submitted reports.
- **Acceptance Criteria:**
  - Shows only my submitted reports
  - Each shows status badge if applicable
  - Empty state when no submissions

### STRAY-15 — Reporting integration
- **Epic:** STRAY-E2 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest · **UC:** UC-05 to 08
- **Description:** Wire reporting UIs to backend.
- **Acceptance Criteria:**
  - Submitted report appears in Feed within 5 seconds
  - Same report appears in My Reports
  - Tapping opens Report Detail correctly

### STRAY-16 — Sprint 1 test plan + Auth test cases
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Description:** Test infrastructure and Auth test coverage.
- **Acceptance Criteria:**
  - TRD has test plan section with all Auth test cases
  - Test cases cover: register valid/invalid, login valid/invalid, logout, session persistence

### STRAY-17 — Reporting test cases + execution
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Description:** Test the Reporting module.
- **Acceptance Criteria:**
  - Each test case has ID, description, steps, expected, actual, severity, pass/fail
  - At least one negative test per UC

### STRAY-18 — Sprint 1 TRD + BRD compilation
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 3 · **Priority:** Highest
- **Description:** Finalize Sprint 1 testing documentation.
- **Acceptance Criteria:**
  - TRD signed off by Prepared-by / Tested-by / Approver
  - BRD lists every defect with severity and status

### STRAY-19 — Sprint 1 planning + standups + NODs
- **Epic:** — · **Assignee:** Baqir · **SP:** 5 · **Priority:** Highest
- **Description:** Sprint coordination and documentation.
- **Acceptance Criteria:**
  - NOD folder has: Sprint Planning, 2× weekly standup, Sprint Retrospective
  - Each NOD has date, attendees, decisions, action items

### STRAY-20 — Sprint 1 Report Rev A1 + Release v0.1.0
- **Epic:** — · **Assignee:** Baqir · **SP:** 5 · **Priority:** Highest
- **Description:** Sprint 1 closeout deliverables.
- **Acceptance Criteria:**
  - Jira Release `v0.1.0` exists with all Sprint 1 issues attached
  - Release notes describe what shipped
  - SPP/FS updated to Rev A1
  - Sprint 1 Report PDF exported and ready to submit

---

# Sprint 2 — Fundraising

**Sprint Goal:** A user can browse fundraising campaigns, see transparent donation totals, donate via payment gateway (sandbox), and view donation history. NGOs/admins can create and manage campaigns.

**Release:** v0.2.0 · **Items:** 18 · **Points:** 81

### STRAY-21 — Payment gateway sandbox integration
- **Epic:** STRAY-E3 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Test payment with sandbox card succeeds, returns transaction ID
  - Failed cards return clear error codes
  - API keys stored in `.env`, not committed

### STRAY-22 — Admin/NGO role + security rules
- **Epic:** STRAY-E3 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - User doc with `role: "admin"` or `"ngo"` can create/edit campaigns
  - Regular users denied by Firestore rules
  - Rules unit-tested with Firebase emulator

### STRAY-23 — Sprint 2 wireframes
- **Epic:** STRAY-E3 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** High
- **Acceptance Criteria:**
  - Wireframes for: Campaigns List, Campaign Detail, Donation Flow, My Donations, Receipt, Admin Manage Campaign
  - User flow arrows connect screens

### STRAY-24 — Sprint 2 hi-fi mockups
- **Epic:** STRAY-E3 · **Assignee:** Khalief · **SP:** 5 · **Priority:** High
- **Acceptance Criteria:**
  - All Sprint 2 screens mocked with design system
  - Progress bar, donation amount selector, payment success states designed

### STRAY-25 — Campaigns backend
- **Epic:** STRAY-E3 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-09, 10, 15
- **Acceptance Criteria:**
  - `campaigns/{id}` doc has: title, description, goalAmount, currentAmount, imageUrl, status, createdBy, createdAt, endsAt
  - List active campaigns ordered by createdAt
  - Read single campaign by ID

### STRAY-26 — Donations backend + payment processing
- **Epic:** STRAY-E3 · **Assignee:** Faiz · **SP:** 8 · **Priority:** Highest · **UC:** UC-11
- **Acceptance Criteria:**
  - On payment success, `donations/{id}` doc created with donorId, campaignId, amount, transactionId, status
  - Campaign's currentAmount incremented atomically
  - Failed payments record status: "failed" and don't update campaign

### STRAY-27 — Transparent allocation tracking
- **Epic:** STRAY-E3 · **Assignee:** Faiz · **SP:** 3 · **Priority:** High · **UC:** UC-13
- **Acceptance Criteria:**
  - Campaign transparency report shows total raised, donor count, allocations array
  - Sum of allocations never exceeds currentAmount

### STRAY-28 — Campaigns list screen
- **Epic:** STRAY-E3 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-09
- **Acceptance Criteria:**
  - Scrollable list with image, title, progress bar, raised/goal
  - Completed campaigns visually distinct
  - Pull-to-refresh works

### STRAY-29 — Campaign detail screen
- **Epic:** STRAY-E3 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-10, 13
- **Acceptance Criteria:**
  - Shows full description, image, progress bar, raised/goal, donor count, days remaining
  - "Where the money goes" section shows allocation breakdown
  - "Donate Now" button visible

### STRAY-30 — Donation flow screen
- **Epic:** STRAY-E3 · **Assignee:** Khalief · **SP:** 5 · **Priority:** Highest · **UC:** UC-11
- **Acceptance Criteria:**
  - Select amount (preset or custom)
  - Payment form with validation
  - On success, confirmation screen with receipt option

### STRAY-31 — My Donations history screen
- **Epic:** STRAY-E3 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** High · **UC:** UC-12
- **Acceptance Criteria:**
  - List of donations sorted newest first
  - Shows campaign, amount, date, status
  - Total donated shown at top
  - Empty state when none

### STRAY-32 — Donation receipt
- **Epic:** STRAY-E3 · **Assignee:** Khalief · **SP:** 5 · **Priority:** High · **UC:** UC-14
- **Acceptance Criteria:**
  - Receipt shows donor name, donation ID, campaign, amount, date, transaction ID
  - Export as PDF or share

### STRAY-33 — Admin: Create/Manage Campaign
- **Epic:** STRAY-E3 · **Assignee:** Khalief · **SP:** 5 · **Priority:** Highest · **UC:** UC-15
- **Acceptance Criteria:**
  - Admin/NGO can create campaign with all schema fields
  - Edit/end own campaigns
  - Add allocation entries

### STRAY-34 — Fundraising integration
- **Epic:** STRAY-E3 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest · **UC:** UC-09 to 15
- **Acceptance Criteria:**
  - Donation updates campaign total within 5 seconds
  - Donation appears in My Donations
  - Receipt generated correctly

### STRAY-35 — Sprint 2 test plan + test cases
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Test cases cover all fundraising UCs (success + failure)
  - At least one negative test per UC

### STRAY-36 — Sprint 2 TRD + BRD
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - TRD signed off
  - BRD lists all defects with severity

### STRAY-37 — Sprint 2 planning + NODs
- **Epic:** — · **Assignee:** Baqir · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Sprint Planning + 2× standup + Retrospective NODs exist

### STRAY-38 — Sprint 2 Report Rev A2 + Release v0.2.0
- **Epic:** — · **Assignee:** Baqir · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - Jira Release `v0.2.0` with all Sprint 2 issues
  - FS updated to Rev A2

---

# Sprint 3 — Volunteer + Dashboards

**Sprint Goal:** Volunteers can browse and sign up for activities; NGOs/admins can create activities; stakeholders can view dashboards aggregating reports, donations, and volunteer engagement.

**Release:** v0.3.0 · **Items:** 18 · **Points:** 78

### STRAY-39 — Push notifications (FCM)
- **Epic:** STRAY-E4 · **Assignee:** Faiz · **SP:** 5 · **Priority:** High
- **Acceptance Criteria:**
  - FCM configured
  - Activity publication triggers push within 1 minute
  - Notification tap opens activity detail

### STRAY-40 — Sprint 3 wireframes
- **Epic:** STRAY-E4 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** High
- **Acceptance Criteria:**
  - Wireframes for: Activities List, Activity Detail, My Activities, Admin Manage Activity, Stakeholder Dashboard, Public Stats

### STRAY-41 — Sprint 3 hi-fi mockups
- **Epic:** STRAY-E4 · **Assignee:** Khalief · **SP:** 5 · **Priority:** High
- **Acceptance Criteria:**
  - All Sprint 3 screens mocked with design system
  - Dashboard chart/stat components designed

### STRAY-42 — Activities backend
- **Epic:** STRAY-E4 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-16, 19
- **Acceptance Criteria:**
  - `activities/{id}` doc has: title, description, location, dateTime, slots, createdBy, status
  - List upcoming activities ordered by dateTime
  - Mark as `completed`

### STRAY-43 — Sign-ups backend
- **Epic:** STRAY-E4 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-17
- **Acceptance Criteria:**
  - `signups/{id}` doc with volunteerId, activityId, signedAt
  - slotsRemaining decrements atomically
  - Rejected when slotsRemaining = 0
  - Cannot sign up twice

### STRAY-44 — Activities list screen
- **Epic:** STRAY-E4 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-16
- **Acceptance Criteria:**
  - Cards with title, date, location, slots remaining
  - "Signed Up" badge for already-signed activities
  - Past activities filtered by default

### STRAY-45 — Activity detail + Sign Up
- **Epic:** STRAY-E4 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-17
- **Acceptance Criteria:**
  - Shows full description, date/time, location, total/remaining slots, volunteer count
  - "Sign Up" enabled if not signed and slots remain
  - After sign-up, button becomes "Cancel Sign-up"

### STRAY-46 — My Activities screen
- **Epic:** STRAY-E4 · **Assignee:** Khalief · **SP:** 3 · **Priority:** High · **UC:** UC-18
- **Acceptance Criteria:**
  - Upcoming activities with cancel option
  - Separate section for past activities
  - Empty state when none

### STRAY-47 — Admin: Create/Manage Activity
- **Epic:** STRAY-E4 · **Assignee:** Khalief · **SP:** 5 · **Priority:** Highest · **UC:** UC-19
- **Acceptance Criteria:**
  - Admin can create activity with all schema fields
  - Edit/cancel own activities
  - See list of signed-up volunteers

### STRAY-48 — Mark Activity Complete
- **Epic:** STRAY-E4 · **Assignee:** Khalief · **SP:** 3 · **Priority:** High · **UC:** UC-20
- **Acceptance Criteria:**
  - Admin marks past-date activity complete
  - Status changes to `completed`
  - Volunteers receive thank-you notification

### STRAY-49 — Volunteer integration
- **Epic:** STRAY-E4 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest · **UC:** UC-16 to 20
- **Acceptance Criteria:**
  - Sign-up appears in My Activities within 5 seconds
  - Admin sees new volunteer in their list
  - Notification flow works end-to-end

### STRAY-50 — Dashboard aggregation backend
- **Epic:** STRAY-E5 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest · **UC:** UC-21, 22
- **Acceptance Criteria:**
  - Returns total reports, total funds, total volunteers, active campaigns
  - Time-series data for last 30 days available
  - Latency under 2 seconds

### STRAY-51 — Stakeholder Dashboard screen
- **Epic:** STRAY-E5 · **Assignee:** Ahmad · **SP:** 5 · **Priority:** Highest · **UC:** UC-21
- **Acceptance Criteria:**
  - Admin sees KPI cards (reports, donations, volunteers, campaigns)
  - 30-day time-series charts
  - "Top campaigns" and "Recent reports" panels

### STRAY-52 — Public Stats Dashboard
- **Epic:** STRAY-E5 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** High · **UC:** UC-22
- **Acceptance Criteria:**
  - Any visitor sees total cats helped, funds raised, volunteers
  - Updates at least daily
  - No PII visible

### STRAY-53 — Sprint 3 test plan + test cases
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Covers all volunteer flows + dashboard data correctness
  - At least one negative test per UC

### STRAY-54 — Sprint 3 TRD + BRD
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - TRD signed off
  - All defects in BRD

### STRAY-55 — Sprint 3 planning + NODs
- **Epic:** — · **Assignee:** Baqir · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Sprint Planning + 2× standup + Retrospective NODs exist

### STRAY-56 — Sprint 3 Report Rev A3 + Release v0.3.0
- **Epic:** — · **Assignee:** Baqir · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - Jira Release `v0.3.0` with all Sprint 3 issues
  - FS updated to Rev A3

---

# Sprint 4 — Testing & Release

**Sprint Goal:** Complete end-to-end testing, fix critical bugs from Sprints 1-3, harden security and performance, conduct UAT, ship v1.0.0 with final documentation and demo.

**Release:** v1.0.0 · **Items:** 14 · **Points:** 59

### STRAY-57 — E2E integration test plan
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Covers cross-module flows (register→report→dashboard; donate→campaign→stats)
  - Test environments specified
  - v1.0.0 release pass criteria defined

### STRAY-58 — Execute E2E test suite
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 8 · **Priority:** Highest
- **Acceptance Criteria:**
  - Each test case has recorded status + evidence
  - Results summarized in E2E report

### STRAY-59 — UAT with stakeholders
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - At least 5 testers (students + 1 NGO contact)
  - Feedback recorded with severity + category
  - Blockers filed as Jira bugs

### STRAY-60 — Performance testing
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 3 · **Priority:** High
- **Acceptance Criteria:**
  - Load test (~50 concurrent users)
  - Targets: startup <3s, feed <2s, donation <5s
  - Results in performance report

### STRAY-61 — Bug-fix sweep
- **Epic:** STRAY-E6 · **Assignee:** Faiz · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - All critical/high bugs from Sprints 1-3 fixed
  - Medium/low either fixed or explicitly deferred
  - Every fix linked to its bug ticket

### STRAY-62 — Security review
- **Epic:** STRAY-E6 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - All Firestore rules audited and tested
  - Auth tokens validated server-side
  - No secrets in repo
  - Findings documented

### STRAY-63 — UI polish + accessibility
- **Epic:** STRAY-E6 · **Assignee:** Khalief · **SP:** 5 · **Priority:** High
- **Acceptance Criteria:**
  - WCAG AA contrast on all key screens
  - Form fields have proper labels
  - Touch targets ≥44pt
  - Polish checklist tracked

### STRAY-64 — Final design audit
- **Epic:** STRAY-E6 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** Medium
- **Acceptance Criteria:**
  - Discrepancies vs Figma listed and resolved
  - All screens use design system components

### STRAY-65 — User documentation / in-app help
- **Epic:** STRAY-E6 · **Assignee:** Ahmad · **SP:** 3 · **Priority:** Medium
- **Acceptance Criteria:**
  - Getting-started guide + FAQs in Help
  - Key flows have step-by-step screenshots

### STRAY-66 — Production Firebase config + deployment
- **Epic:** STRAY-E6 · **Assignee:** Faiz · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - Separate prod Firebase project deployed
  - Prod Firestore rules tested
  - Deployment checklist signed off

### STRAY-67 — Final test report compilation + sign-off
- **Epic:** STRAY-E6 · **Assignee:** Khalisha · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - Consolidates Sprints 1-4 test results + E2E summary
  - Signed off (Prepared/Tested/Approver)
  - Overall Result recorded

### STRAY-68 — Final Report PDF Rev A4
- **Epic:** — · **Assignee:** Baqir · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Includes SPP, full FS (all UCs), UML diagrams, test summary, screenshots
  - Rev A4 ready for submission

### STRAY-69 — Demo video + final presentation
- **Epic:** — · **Assignee:** Baqir · **SP:** 5 · **Priority:** Highest
- **Acceptance Criteria:**
  - Video covers all 9 rubric sections
  - Slide deck for final stakeholder review

### STRAY-70 — Release v1.0.0 + Jira closeout
- **Epic:** — · **Assignee:** Baqir · **SP:** 3 · **Priority:** Highest
- **Acceptance Criteria:**
  - Jira Release `v1.0.0` with all final issues
  - Sprint 4 closed in Jira
  - Full release notes

---

## Use Case Master List

| UC ID | Use Case | Sprint | Actor |
|---|---|---|---|
| UC-01 | Register Account | 1 | New User |
| UC-02 | Login | 1 | Registered User |
| UC-03 | Logout | 1 | Registered User |
| UC-04 | View/Edit Profile | 1 | Registered User |
| UC-05 | Submit Cat Sighting Report | 1 | Registered User |
| UC-06 | View Reports Feed | 1 | Any User |
| UC-07 | View Report Details | 1 | Any User |
| UC-08 | View My Submitted Reports | 1 | Registered User |
| UC-09 | Browse Active Campaigns | 2 | Any User |
| UC-10 | View Campaign Details | 2 | Any User |
| UC-11 | Make Donation | 2 | Registered User |
| UC-12 | View Donation History | 2 | Registered User |
| UC-13 | View Transparent Tracking | 2 | Any User |
| UC-14 | Receive Donation Receipt | 2 | Donor |
| UC-15 | Admin Create/Manage Campaign | 2 | NGO/Admin |
| UC-16 | Browse Volunteer Activities | 3 | Any User |
| UC-17 | Sign Up for Activity | 3 | Volunteer |
| UC-18 | View My Activities | 3 | Volunteer |
| UC-19 | Admin Create/Manage Activity | 3 | NGO/Admin |
| UC-20 | Mark Activity Complete | 3 | NGO/Admin |
| UC-21 | View Stakeholder Dashboard | 3 | NGO/Admin |
| UC-22 | View Public Stats Dashboard | 3 | Any User |

---

## Workload Distribution

### Per Sprint

| Sprint | Faiz | Ahmad | Khalief | Khalisha | Baqir | Total SP |
|---|---|---|---|---|---|---|
| Sprint 1 | 26 | 18 | 18 | 13 | 13 | 88 |
| Sprint 2 | 27 | 16 | 20 | 10 | 8 | 81 |
| Sprint 3 | 23 | 21 | 16 | 10 | 8 | 78 |
| Sprint 4 | 11 | 6 | 5 | 24 | 13 | 59 |
| **Total** | **87** | **61** | **59** | **57** | **42** | **306** |

### Per Member

| Member | Total Stories | Total SP | Notes |
|---|---|---|---|
| Faiz (Lead Dev) | 20 | 87 | Backend across all modules |
| Ahmad (UI/UX) | 15 | 61 | Wireframes + key screens |
| Khalief (UI/UX) | 13 | 59 | Hi-fi mockups + admin screens |
| Khalisha (QA) | 12 | 57 | Testing every sprint + leads E6 |
| Baqir (PM) | 10 | 42 | Coordination, NODs, reports |
