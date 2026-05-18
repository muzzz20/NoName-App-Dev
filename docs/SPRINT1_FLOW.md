# Sprint 1 User Flow & Screen Inventory

> Companion to `DESIGN.md` (visual system) + `mockup-screens/` (hi-fi PNGs).
> Tracks NAD-4 (wireframes / user flow) and NAD-5 (hi-fi mockups) deliverables.

## Sprint 1 Screen Coverage

| Required screen (NAD-4 AC) | Hi-fi mockup file | Source story | Status |
|---|---|---|---|
| Splash | `mockup-screens/splash_screen.png` | bootstrap | ✅ hi-fi |
| Login | `mockup-screens/login_screen.png` | NAD-7 | ✅ hi-fi |
| Register | `mockup-screens/registration_screen.png` | NAD-7 | ✅ hi-fi |
| Profile | `mockup-screens/user_profile_screen.png` | NAD-7 | ✅ hi-fi |
| Reports Feed | `mockup-screens/home_dashboard.png` | NAD-12 | ✅ hi-fi (home dashboard combines feed + stats) |
| Submit Report | `mockup-screens/report_cat_screen.png` | NAD-11 | ✅ hi-fi |
| Report Submitted (success) | `mockup-screens/report_success_screen.png` | NAD-11 | ✅ hi-fi |
| Report Detail | — | NAD-13 | ⏳ derive from Submit Report + DESIGN.md card spec |
| My Reports | — | NAD-14 | ⏳ derive from Feed layout filtered by user |
| Interactive Map (location picker) | `mockup-screens/interactive_map_screen.png` | NAD-10 / NAD-11 | ✅ hi-fi |
| Emergency Alert | `mockup-screens/emergency_alert_page.png` | bonus (Sprint 3 candidate) | ✅ hi-fi |
| Notifications | `mockup-screens/notifications_screen.png` | Sprint 3 | ✅ hi-fi (pre-built for NAD-39+) |

**5 of 7 NAD-4 required screens have direct hi-fi mockups.** Report Detail
and My Reports inherit structure from existing screens (Submit Report card +
Feed card respectively) and will be built directly in Flutter per
DESIGN.md tokens — no separate mockup blocks Sprint 1.

## User Flow

```
                          [Splash 2s]
                              │
                              ▼
                    auth state restored?
                       ┌──────┴──────┐
                      yes            no
                       │              │
                       ▼              ▼
                   [Home/Feed]    [Login] ◄──────────┐
                       ▲              │              │
                       │              │ "Register"   │ "Forgot Password"
                       │              ▼              │   (NAD-7 stretch)
                       │         [Register]          │
                       │              │              │
                       │              ▼              │
                       └──── success: redirect to Feed
                       │
                       │
       ┌───────────────┼────────────────┬───────────────┐
       │               │                │               │
       ▼               ▼                ▼               ▼
  [Feed/Home]   [Submit Report]   [My Reports]    [Profile]
       │               │                │               │
       │ tap card      │ photo+loc+cond │ tap card      │ tap "Sign Out"
       ▼               │ submit         ▼               ▼
  [Report Detail]      ▼          [Report Detail]   [Login]
       │           [Report Success]
       │ back          │ "View Report" → [Report Detail]
       │               │ "Back to Feed" → [Feed]
       ▼
  [Feed/Home]
```

### Critical paths

**Path A — First-time user reports a cat:**
Splash → Login → Register → Feed → tap "+ Report" → Submit Report
→ enter details → Report Success → View Report → Report Detail

**Path B — Returning user checks own reports:**
Splash → auto-login → Feed → My Reports tab → tap card → Report Detail

**Path C — Sign out:**
Profile → "Sign Out" → Login

## Screen-by-screen wireframe annotations

Below = wireframe-level annotation (boxes / labels / arrows) layered on top
of the Stitch hi-fi files. Implementers (Flutter UI stories) should consult
both this doc and the PNG to understand intent.

### Splash (`splash_screen.png`)
- Centered logo placeholder (UTM Maroon "S" markmark — pending NAD-3 asset)
- 2-second timer or async-init delay
- Routes to `/login` if `FirebaseAuth.currentUser == null`, else `/feed`

### Login (`login_screen.png`)
- Header: "Welcome Back" + subtitle
- Email + Password text fields (use AppTheme InputDecorationTheme)
- "Forgot Password?" button (top-right of password field area)
- Primary CTA: "Sign In" (full-width, UTM Maroon)
- Footer: "Don't have an account? Register Now"
- Error state: inline banner above CTA, error color from theme

### Register (`registration_screen.png`)
- Fields: Full Name, UTM Email, Password, Confirm Password
- Required Terms & Conditions checkbox
- Primary CTA: "Register"
- Footer: "Already have an account? Sign In"
- Validation: client-side (NAD-7) before AuthService call (NAD-8)

### Profile (`user_profile_screen.png`)
- Maroon header card with avatar + name + email + role chip
- Stats row: # Reports, # Points (deferred), # Saved (deferred)
- Menu list: My Reports, Volunteer History, Favorites, Account Settings
- Bottom: "Sign Out" (error-tint background, error-color text)

### Reports Feed (`home_dashboard.png`)
- Top: greeting + avatar
- Bento grid (2 cols): "Active Reports" stat tile (Maroon),
  "Rescued This Month" tile (white card), "Volunteer of the Day"
  banner (Success green, span full width)
- Search bar (filter by location / cat name)
- List: cards with photo, condition badge, location, time ago
- Empty state: illustration + "Be the first to submit a report"
- Pull-to-refresh

### Submit Report (`report_cat_screen.png`)
- Header: back button + "Report Stray Cat"
- Photo upload card (camera/gallery picker — uses CatPhotoUpload component)
- Cat Label/Name (optional text input)
- Location (text input with map icon → opens Interactive Map for pick)
- Condition (dropdown: Healthy / Injured / Sick — per NAD-11 AC)
- Description (multiline textarea)
- Critical Emergency toggle (error-tint container)
- Primary CTA: "Submit Report" (disabled until required fields set)
- Loading state: spinner replaces CTA text during upload+save

### Report Detail (NAD-13, hi-fi pending Khalief)
- Photo hero (full-bleed)
- Floating back button (top-left, glass treatment)
- Bottom sheet card overlay with:
  - Title (cat label or "Unnamed Cat") + urgency chip
  - Status chip (Pending / In Progress / Resolved)
  - Condition description block
  - Map preview with pin (uses Interactive Map static render)
  - Reporter name + timestamp grid (2x1)
  - Secondary CTAs: "Comment" (outlined) + "Contact" (primary) — Sprint 3

### My Reports (NAD-14, hi-fi pending Ahmad)
- Header: "My Reports"
- Same card layout as Feed but filtered to `userId == currentUser.uid`
- Empty state: "You haven't submitted any reports yet" + CTA to Submit Report

### Interactive Map (`interactive_map_screen.png`)
- Full-screen map (google_maps_flutter — NAD-10)
- Pin draggable to set location
- "Use current location" button (top-right)
- Bottom CTA: "Confirm Location" → returns GeoPoint to Submit Report

### Report Success (`report_success_screen.png`)
- Centered success icon (UTM Maroon) + "Report Submitted!" headline
- Sub: "Volunteers in your area have been notified."
- CTAs: "View Report" (primary, to Detail) / "Back to Feed" (outlined)

## Approval

| Reviewer | Date | Comment |
|---|---|---|
| Faiz (Lead Dev) | 2026-05-14 | Approved — screens map cleanly to feature stories; Report Detail + My Reports follow obvious patterns from existing components |
| Khalief / Ahmad | _pending_ | Add Figma comments once team review session done |

Once Khalief + Ahmad sign off in standup, this doc moves to BRD as
"Sprint 1 design baseline".
