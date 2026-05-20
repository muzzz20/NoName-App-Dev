# NAD-24: Sprint 2 hi-fi mockups
# File: docs/sprint2_hifi_spec.md

## 1. Donation Flow Screen (NAD-30)

**Navigation:** Entry: `AppRoutes.donationFlow` → Exit: `AppRoutes.donationReceipt` (on success)

**Components:**
- `AppBar`: Background `AppColors.surface`, Title `AppColors.onSurface`, Leading Icon `AppColors.onSurface`
- `AmountChipSelector` (Default): Background `AppColors.surfaceContainer`, Text `AppColors.onSurface`
- `AmountChipSelector` (Selected): Background `AppColors.primaryContainer`, Text `AppColors.onPrimaryContainer`
- `PaymentForm` Inputs: Standard `TextFormField` styling, Outline `AppColors.outlineVariant`
- `CTA Button`: Fill `AppColors.primary`, Text `AppColors.onPrimary`

**States:**
- Empty: Default form fields
- Loading: `ElevatedButton` displays a `CircularProgressIndicator` sized to fit vertically.
- Error: `DonationFailure` triggers `SnackBar` with background `AppColors.error`.

## 2. Donation Receipt Screen (NAD-32)

**Navigation:** Entry: Pushed from successful payment → Exit: `context.pop()` back to flow or main menu.

**Components:**
- `AppBar`: Background `AppColors.surface`, Actions `Icons.share` & `Icons.picture_as_pdf` mapped to `AppColors.primary`.
- `SuccessIcon`: `Icons.check_circle`, size 64, color `AppColors.primary`.
- `Receipt Card`: Background `AppColors.surfaceContainerLowest`, Border `AppColors.cardBorder`, Radius 16px.
- `ReceiptDetailRow`: Labels `AppColors.onSurfaceVariant`, Values `AppColors.onSurface`. Highlighting applies `AppColors.primary` and `FontWeight.bold`.

## 3. Admin: Create/Manage Campaign Screen (NAD-33)

**Navigation:** Entry: `AppRoutes.adminCampaigns` → Sub-Exit: `AppRoutes.campaignNew`

**Components:**
- `CampaignManagementCard`: Background `AppColors.surfaceContainerLowest`, Border `AppColors.cardBorder`.
- `End Early Button`: Text `AppColors.error`.
- `Edit Button`: Fill `AppColors.primary`, Text `AppColors.onPrimary`.
- `FloatingActionButton`: Fill `AppColors.primary`, Icon `AppColors.onPrimary`.

## 4. Specific Components

**Progress Bar Component (For future rendering):**
- Track Color: `AppColors.surfaceVariant`
- Fill Color: `AppColors.primary`
- Height: 8px
- Border Radius: 4px
- Label Placement: Justified row above progress track (Amount Raised vs Goal).

**Amount Selector:**
- Default Chip: `ChoiceChip` using neutral tones.
- Selected Chip: Strong high-contrast container fill.
- Custom Input Field: Triggered actively, inline prefix "RM " added natively.
