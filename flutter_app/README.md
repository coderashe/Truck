# TruckFlow — Haulage & Trucking Operations Manager

**TruckFlow** is a production-ready Flutter 3.22+ / Dart 3 mobile application for managing day-to-day trucking and haulage operations, backed exclusively by Firebase (Firestore, Firebase Authentication, and Firebase Storage) with offline persistence enabled.

> **Phase 2 Ready:** Multi-tenant isolation (`companyId` on every document + Firestore Security Rules) and modular `core/` layers allow adding a Customer Booking Portal without redesigning the backend or data models.

---

## Features

- **Business Setup Wizard**: Company profile, logo upload to Firebase Storage, currency, default per-km rate, round-trip pricing toggle, fleet trucks, and drivers.
- **Orders & Per-Km Round-Trip Pricing**: WhatsApp/Call/Email/In-person order capture, Google Places & Distance Matrix integration with manual override, automatic `chargeableKm = distanceKm * (roundTrip ? 2 : 1)`, extras, discounts, and 7-stage status workflow (`Requested` → `Pending` → `Confirmed` → `In Transit` → `Delivered` → `Invoiced` → `Paid` / `Cancelled`).
- **On-Device Branded PDF Invoicing**: Auto-numbered invoices (`INV-2026-0001`), company logo & bank instructions, itemised haulage summary, share directly to WhatsApp/Email via `share_plus`, archival to Firebase Storage, and partial/full payment tracking.
- **Expenses & Financial Position**: 9 expense categories, optional truck linkage for per-truck profitability, receipt photo upload, period filters, monthly revenue-vs-expense bar charts, and expense category pie charts.
- **Business Intelligence & Route Heatmaps**: Recurring customers with "Loyal" badge (3+ orders), most profitable routes, peak days of month & week, top-performing trucks, Google Maps heatmap layer (`Pickups` / `Drop-offs` / `Both`) with tappable route polylines, and locally computed insight cards.
- **Customers Directory**: Order history, total billed, outstanding receivables, and one-tap Call / WhatsApp launch (`url_launcher`).
- **Seed Data Utility**: Built-in dev seeder (hidden tap in Settings) generating a realistic Zimbabwean haulage company, 5 trucks, 4 drivers, 12 customers, 60 orders across 8 routes over 6 months, mixed-state invoices, and 40 expenses.

---

## 1. Prerequisites

- Flutter SDK `>=3.22.0` (Dart `>=3.4.0 <4.0.0`)
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- Android Studio / Xcode for device builds
- A Google Cloud Project with Billing enabled (for Google Maps, Places, and Directions APIs)

---

## 2. Firebase Project Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. **Authentication**:
   - Navigate to **Build → Authentication → Sign-in method**.
   - Enable **Email/Password**.
   - Enable **Google** (add your support email and Android SHA-1 / SHA-256 fingerprints in Project Settings).
3. **Cloud Firestore**:
   - Navigate to **Build → Firestore Database → Create database**.
   - Choose your region (e.g., `eur3` or `africa-south1` Johannesburg for Southern Africa).
   - Start in production mode (we will deploy `firestore.rules` below).
4. **Firebase Storage**:
   - Navigate to **Build → Storage → Get started**.
5. **Configure FlutterFire**:
   ```bash
   flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
   ```
   This overwrites `lib/firebase_options.dart` and places `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.

---

## 3. Deploy Firestore Security Rules & Composite Indexes

```bash
firebase login
firebase use <YOUR_FIREBASE_PROJECT_ID>
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 4. Google Maps, Places & Directions API Setup

1. In [Google Cloud Console](https://console.cloud.google.com), enable:
   - **Maps SDK for Android** (and **Maps SDK for iOS**)
   - **Places API**
   - **Directions API** (or **Distance Matrix API**)
2. Create an API Key and restrict it by Android package name + SHA-1 (for Maps SDK) or HTTP/API restrictions.
3. Add the API key to `android/app/src/main/AndroidManifest.xml` (see `android_config_notes.md`).
4. Pass the Places/Directions key at build time via `--dart-define`:
   ```bash
   flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...
   ```

---

## 5. Install Dependencies & Run

```bash
flutter pub get
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY
```

---

## 6. Running the Seed Data Utility

1. Sign in and complete (or skip through) the **Business Setup Wizard**.
2. Go to **More → Settings**.
3. Tap the **"TruckFlow Version"** row at the bottom **5 times** (or open the **Developer Seed Tools** card) to unlock the hidden dev menu.
4. Tap **Seed Sample Data (60 Orders, 5 Trucks, 40 Expenses)** and confirm.
5. Navigate to **Dashboard**, **Orders**, **Expenses**, and **Insights** to explore live analytics and the route heatmap.

---

## 7. Building the Release APK

```bash
flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY
# Output: build/app/outputs/flutter-apk/app-release.apk
```

For Google Play App Bundle:
```bash
flutter build appbundle --release --dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY
```
