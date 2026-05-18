# CLAUDE.md — Strayfriends Project Context

> Project context for Claude CLI. Drop this file at the root of your repo — Claude Code reads it automatically.

---

## Quick Reference

- **Project:** Strayfriends — mobile + web app for stray cat welfare at UTM
- **Course:** SCSJ3104 Application Development
- **Group:** NoName (5 members)
- **Stack:** Flutter, Firebase (Auth/Firestore/FCM), Supabase (object storage), GitHub, Jira, Figma
- **Sprints:** 4 sprints (1 week each per SPP) + Pre-Sprint
- **Backlog:** 70 stories, ~306 story points
- **Jira project key:** `NAD` (NoName App Dev) — all live tickets are `NAD-N` on https://noname1.atlassian.net
- **Companion file:** `docs/BACKLOG.md` — full backlog with ACs (planning IDs; live IDs are in Jira)

---

## 1. Project Overview

Strayfriends addresses the well-being of stray cats at Universiti Teknologi Malaysia (UTM). Target users: students, faculty, NGOs, donors, veterinarians.

**Three core modules (all committed in SPP):**

1. **Reporting** — submit cat sightings with location + condition
2. **Fundraising** — transparent donation tracking
3. **Volunteer management** — coordinate welfare activities

Plus stakeholder dashboards aggregating data across all modules.

---

## 2. Team & Roles

| Name | Role | Jira Username |
|---|---|---|
| Baqir Tsaqib Hakim | Project Manager | `baqir` |
| Faiz Syuhada | Lead Developer | `faiz` |
| Ahmad Muzhaffar Prihantony | UI/UX Designer | `ahmad` |
| Khalief Zamzam Mahendra | UI/UX Designer | `khalief` |
| Khalisha Afifah Sekarbyovi | QA Engineer | `khalisha` |

> ⚠️ **SPP correction needed:** the submitted SPP swaps Khalisha and Khalief's roles. Update the SPP to match this table.

---

## 3. Schedule

| Milestone | Sprint | Focus | Target | Release |
|---|---|---|---|---|
| M0–M1 | Pre-Sprint | Proposal + Project Planning | Apr 12 | — |
| M2 | Sprint 1 | Reporting + Auth | Apr 16 | v0.1.0 |
| M3 | Sprint 2 | Fundraising | Apr 23 | v0.2.0 |
| M4 | Sprint 3 | Volunteer + Dashboards | Apr 30 | v0.3.0 |
| M5 | Sprint 4 | Testing & Hardening | May 7 | v1.0.0 |
| M6 | Final | Release + presentation | Jun 11 | — |

---

## 4. Epic Structure

| Key | Epic | Sprint | Owner |
|---|---|---|---|
| NAD-E1 | User & Auth Foundation | 1 | Faiz |
| NAD-E2 | Cat Reporting Module | 1 | Faiz |
| NAD-E3 | Fundraising Module | 2 | Faiz |
| NAD-E4 | Volunteer Coordination Module | 3 | Faiz |
| NAD-E5 | Stakeholder Dashboards | 3-4 | Ahmad |
| NAD-E6 | Testing, Hardening & Release | 4 | Khalisha |

---

## 5. Sprint Review Rubric (10% per sprint)

Aim for **"Very Good [5]"** on every criterion.

| Criterion | Very Good [5] requires | Weight |
|---|---|---|
| Issues Completeness | All clearly defined **AND assigned** | 3 |
| Prototype/Demo | Demo all **In Progress AND Done** items | 3 |
| Code Versioning | GitHub/GitLab **AND** Jira (linked) | 2 |
| Functional Specification | All backlog items in FS **and complete** | 2 |
| Bug Tracking/Testing | All tested **AND recorded in BRD** | 2 |
| Software Release | Defined in Jira **with version number** | 2 |
| Discussion | Active in Jira **AND well organized** | 2 |
| Task Distribution | **Balanced AND well distributed** | 2 |
| Problem Solving | Discussed in Jira **AND recorded in NOD** | 2 |

**Total: /100**

### To hit "Very Good [5]" every sprint:

- Every issue in Jira **defined AND assigned**
- Demo covers both In Progress and Done items
- Commits linked to Jira (`NAD-X` in message)
- FS fully covers all sprint backlog items
- Test results in BRD (Bug Report Document)
- Jira release with proper semver (v0.1.0 → v1.0.0)
- All members commenting in Jira
- Workload balanced across members
- Problems recorded in **NOD (Notes of Discussion)** documents, not just Jira

---

## 6. Sprint Submission Checklist

Every sprint submission requires:

1. **ONE link** to presentation video (YouTube/GDrive) — covers all 9 rubric sections
2. **ONE Report PDF** (Rev Ax draft for Sprint x)
3. **ONE Test Report PDF** (Rev Ax for Sprint x)
4. **ONE logbook per group member** (5 total)

### Presentation video must show (in order):

| # | Section | Source |
|---|---|---|
| 1 | Issues/Features Completeness | Jira **Backlog tab** with assignees |
| 2 | Prototype/Demo | Jira **Board tab** — Done column |
| 3 | Code Versioning | GitHub commit history |
| 4 | Functional Specification | Report draft Section 4 |
| 5 | Bug Tracking/Testing | TRD with test results |
| 6 | Software Release | Jira **Release tab** with version |
| 7 | Discussion | Jira issue comments |
| 8 | Task Distribution | Jira Board grouped by Assignee |
| 9 | Problem Solving | Jira + NOD document |

---

## 7. Definition of Done

Every story is Done only when ALL of these are true:

1. Code merged to `main` via PR; PR linked to Jira (`NAD-X` in message)
2. All acceptance criteria met (verified by QA)
3. Test case written in TRD with status recorded
4. Demo-able from Jira Board's DONE column
5. At least one Jira comment from another team member

---

## 8. Test Report (TRD) Template

> Use this template (`SCSJ3104/GROUP-NoName/Test/00x`, v1.0) for every sprint's test deliverable.

### Header

- **Project Name:** Strayfriends
- **Project Owner:** Group NoName
- **Project Code:** SCSJ3104
- **Project Sub-Module:** (per sprint: Reporting / Fundraising / Volunteer / E2E)

### Test Type (check applicable)

- [ ] Unit Test
- [ ] Integration Test
- [ ] System Test
- [ ] Acceptance Test

### Test Case Table

| Use Case ID | Test Case ID | Description | Procedure / Steps | Expected Result | Actual Result | Severity | Date Resolved | Root Cause |
|---|---|---|---|---|---|---|---|---|
| UC01 | TC001-UC01 | | | | | | | |
| UC01 | TC002-UC01 | | | | | | | |

**Severity:** Fatal = 1 · Serious = 2 · Minor = 3

### Sign-off

- **Prepared by:** ___ · Date: ___
- **Tested by:** ___ · Date: ___
- **Overall Result:** ☐ Passed ☐ Failed ☐ Passed with Concession
- **Signature of Approver:** ___ · Date: ___

---

## 9. Working with Claude CLI + Jira MCP

### Creating the backlog in Jira

This project uses Claude CLI with Jira MCP. Two ways to populate Jira:

> **Historical note:** the backlog has already been imported to Jira
> as project `NAD`. The instructions below are retained as reference
> for how it was set up.

**Option A — Use Claude CLI to read BACKLOG.md and create issues:**

```
claude "Read docs/BACKLOG.md. For the Jira project NAD, create:
1. The 6 Epics from the Epic Structure section
2. All 70 stories with their description, acceptance criteria, assignee (use the Jira Username column), epic link, sprint, story points, and priority
3. Sprints 1-4 with the dates from the Schedule section
Confirm before creating each batch."
```

**Option B — Use Jira's built-in CSV import:**

1. In Jira: Project Settings → Import → CSV
2. Upload your CSV export of `BACKLOG.md`
3. Map columns to Jira fields (Summary, Description, Issue Type, Assignee, Story Points, etc.)
4. Create Epics first, then run a second import for Stories with Epic Link populated

### Project Rules for Claude

When helping with this project, prioritize:

1. **Sprint hygiene over feature volume** — the rubric rewards documentation, assignment, and tracking. Small well-documented sets score higher than many half-documented ones.
2. **Dual-track everything**:
   - Code goes in **both** GitHub **and** Jira (commits reference `NAD-X`)
   - Discussions go in **both** Jira **and** a NOD document
   - Bugs go in **both** test runs **and** the BRD
3. **Use semantic versioning** in Jira releases (v0.1.0, v0.2.0, v0.3.0, v1.0.0)
4. **Map every backlog item to a use case** in the FS before sprint start
5. **Demo In-Progress items too**, not just Done — the rubric's top tier requires both
6. **Update NOD documents** after every meeting (Sprint Planning, standups, Retrospective)
7. **Acceptance criteria are not optional** — they are the contract between Dev and QA, and they feed directly into test cases

---

## 10. Glossary

| Term | Definition |
|---|---|
| BRD | Bug Report Document |
| TRD | Test Report Document |
| NOD | Notes of Discussion (meeting minutes) |
| FS | Functional Specification |
| UC | Use Case |
| AC | Acceptance Criteria |
| DoD | Definition of Done |
| SP | Story Points |
| SPP | Software Project Plan |
| QA | Quality Assurance |
| PLO | Programme Learning Outcome |
| CLO | Course Learning Outcome |
| FCM | Firebase Cloud Messaging |

---

## 11. References

- `PROPOSAL/UTM/2026 (01)` — Project Proposal for Strayfriends
- `SPP-SCSJ3104-001 Rev 01` — Software Project Plan (needs Rev 02 with role + schedule corrections)
- `SCSJ3104 Sprint Review Rubric` — Semester I 2025/2026
- `docs/BACKLOG.md` — Full backlog with 70 stories and acceptance criteria (planning IDs)
- `docs/CONTRIBUTING.md` — How to take a Jira issue from To Do → Done
- `docs/SPRINT2_HANDOFF.md` — Sprint 2 working agreement (.env onboarding + AI workflow)
- `docs/TEST_NOTES_TEMPLATE.md` — Test notes template for developers (consolidates into TRD)
- `docs/DESIGN.md` — UI design system / theme tokens / components
