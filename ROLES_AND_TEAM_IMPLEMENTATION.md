# Roles & Team Management — Implementation Plan

**Branch:** `feature/roles-and-team`  
**Created:** 2024  
**Status:** 🚧 In Progress

---

## Overview

Add a full multi-user, role-based access system to TruckFlow. Any number of people can
join a company from different devices using role-specific join codes. Each role sees a
tailored experience with appropriate access controls enforced both in the UI and in
Firestore security rules.

---

## Roles

| Role | Description |
|---|---|
| **Owner** | Full access. Creates the company. Manages team, settings, all data. |
| **Manager** | Operational access. Creates/edits orders, customers, fleet, invoices. No settings, no team management, no delete. |
| **Accountant** | Financial access. Views all data. Creates invoices. Cannot create orders, manage fleet or team. Read-only on operational data. |
| **Driver** | Personal access. Sees only their assigned trips, personal stats, leaderboard rank, and heatmap. |

---

## Join Code Design

Each company has **4 role-specific codes**, one per role (excluding Owner — the first
signup always becomes Owner).

```
Company.joinCodes: {
  'manager':    'MGR-XXXX',
  'accountant': 'ACC-XXXX',
  'driver':     'DRV-XXXX',
}
```

- Codes are **permanent by default** — share once, works forever for new joins
- Owner can **regenerate any code independently** from Settings → Team
- Regenerating a code does not remove existing members — only blocks new joins with the old code
- Codes are **4-digit alphanumeric** after the prefix, uppercased, e.g. `DRV-K3P9`
- Generated on company creation, stored on the Company Firestore document

---

## Data Model Changes

### AppUser (existing — extended)
```dart
class AppUser {
  // existing fields ...
  final String role;        // 'owner' | 'manager' | 'accountant' | 'driver'
  final String? driverId;   // only set when role == 'driver', links to Driver profile
}
```

### Company (existing — extended)
```dart
class Company {
  // existing fields ...
  final Map<String, String> joinCodes; // {'manager': 'MGR-K3P9', ...}
  final List<TeamMember> members;      // denormalised list for team management UI
}

class TeamMember {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime joinedAt;
}
```

---

## New Screens

### 1. Company Setup Screen (post-signup gate)
**File:** `lib/features/setup/company_gate_screen.dart`

Shown after first login if `currentUser.companyId` is empty.
Two options:
- **Create a Company** → goes to existing SetupWizardScreen, user becomes Owner
- **Join with a Code** → text field for code entry, resolves role and company automatically

### 2. Join Company Screen
**File:** `lib/features/setup/join_company_screen.dart`

- Text input for join code (auto-formats as user types: `MGR-XXXX`)
- Looks up the code across all companies in Firestore
- Shows company name and role they're joining as for confirmation
- On confirm: sets `companyId` and `role` on their AppUser document
- Driver role: after joining, shows "Select your driver profile" dropdown from existing drivers

### 3. Team Management Screen (Owner only)
**File:** `lib/features/settings/team_screen.dart`

Accessible from Settings → Manage Team (Owner only).
- Lists all members with name, role, and joined date
- Owner can change any member's role via dropdown
- Owner can remove a member (sets their companyId to empty)
- Shows each role's join code with a copy button and a regenerate button
- Regenerate shows a confirmation dialog before changing the code

### 4. Driver Dashboard Screen
**File:** `lib/features/driver/driver_dashboard_screen.dart`

Shown as the home screen when `role == 'driver'`.
Sections:
- **My Trips** — list of orders where `driverId == currentUser.driverId`, filterable by status
- **My Stats** — total trips, total km, total revenue generated, this month vs last month
- **Leaderboard** — ranks all drivers in the company by selected metric
  - Filter: Trips / Distance / Revenue
  - Podium display for top 3 (gold/silver/bronze)
  - Current driver's rank highlighted even if outside top 3
- **My Heatmap** — Zimbabwe heatmap showing routes they've driven (pickup/dropoff coordinates)

---

## Modified Screens

### AppRouter (`lib/shared/navigation/app_router.dart`)
- After auth check, also check `role`
- `role == 'driver'` → redirect to `DriverDashboardScreen`
- All other roles → existing scaffold with nav, but nav items filtered by role

### ScaffoldWithNav (`lib/shared/navigation/scaffold_with_nav.dart`)
- Hide **Settings** tab for Manager, Accountant, Driver
- Hide **Fleet** tab for Accountant, Driver
- Hide **Expenses** tab for Driver

### SettingsScreen (`lib/features/settings/settings_screen.dart`)
- Add **Manage Team** tile (Owner only) → navigates to TeamScreen
- Add **My Profile** section — editable name, phone, password change for all roles

### OrderFormScreen (`lib/features/orders/order_form_screen.dart`)
- Guard: only Owner and Manager can access. Accountant and Driver see read-only.

### CustomersScreen (`lib/features/customers/customers_screen.dart`)
- **Fix double-save bug**: disable Save button after first tap, re-enable only on error

### All delete actions
- Guard with `role == 'owner'` check before showing delete buttons

---

## Access Matrix

| Feature | Owner | Manager | Accountant | Driver |
|---|---|---|---|---|
| Dashboard | ✅ | ✅ | ✅ | ❌ (own dashboard) |
| View Orders | ✅ | ✅ | ✅ | own only |
| Create/Edit Orders | ✅ | ✅ | ❌ | ❌ |
| Delete Orders | ✅ | ❌ | ❌ | ❌ |
| Customers | ✅ | ✅ | view only | ❌ |
| Fleet | ✅ | ✅ | view only | ❌ |
| Expenses | ✅ | ✅ | ✅ | ❌ |
| Create Invoices | ✅ | ✅ | ✅ | ❌ |
| Insights/Reports | ✅ | ✅ | ✅ | own stats |
| Settings | ✅ | ❌ | ❌ | ❌ |
| Team Management | ✅ | ❌ | ❌ | ❌ |
| Leaderboard | ✅ | ✅ | ✅ | ✅ |

---

## Firestore Security Rules Changes

```
// AppUser — user can only read/write their own document
match /users/{uid} {
  allow read, write: if request.auth.uid == uid;
}

// Company — any member of the company can read
// Only owner can write settings and joinCodes
match /companies/{companyId} {
  allow read: if isMember(companyId);
  allow write: if isOwner(companyId);
}

// Orders — members can read, owner/manager can write
match /companies/{companyId}/orders/{orderId} {
  allow read: if isMember(companyId);
  allow write: if isOwnerOrManager(companyId);
}

// Drivers — members can read, owner/manager can write  
match /companies/{companyId}/drivers/{driverId} {
  allow read: if isMember(companyId);
  allow write: if isOwnerOrManager(companyId);
}
```

---

## Implementation Order

Steps are ordered to keep the app working at every stage:

1. **Extend data models** — `AppUser` (role, driverId), `Company` (joinCodes, members)
2. **Fix double-save bug** — customers screen (quick win, independent)
3. **Add profile editing** — settings screen personal section
4. **Update FirestoreService** — add team member methods, join code lookup, role update
5. **Company gate** — post-login redirect logic based on companyId empty check
6. **Join company screen** — code entry, company lookup, role assignment, driver linking
7. **Team management screen** — member list, role change, code regeneration
8. **Role-based nav** — filter nav items and guard screens by role
9. **Driver dashboard** — trips, stats, leaderboard, heatmap
10. **Commit + push branch**

---

## Bug Fixes Included

### Double-save on Customer creation
**Root cause:** Save button in `_showAddCustomerDialog` has no loading state — 
tapping twice fires two Firestore writes before the dialog closes.  
**Fix:** Add `bool _isSaving` state to the dialog, disable the button after first tap.

### Profile editing missing
**Root cause:** Settings screen only edits Company document, not the AppUser document.  
**Fix:** Add a "My Profile" card to settings with name, phone fields that write to 
`/users/{uid}` and a "Change Password" option via `FirebaseAuth.updatePassword`.

---

## Notes

- Driver heatmap reuses the existing `ZimbabweHeatmap` component from the web app
- Leaderboard is computed client-side from the existing `ordersProvider` stream —
  no new Firestore queries needed
- Join codes are generated with `uuid` package already in pubspec, shortened to 4 chars
- All role checks use a single `currentRoleProvider` derived from `currentUserProfileProvider`
  so there's one source of truth throughout the app
