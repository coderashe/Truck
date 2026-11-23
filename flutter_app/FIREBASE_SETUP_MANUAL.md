# Firebase Setup - Manual Steps

## ✅ Prerequisites Complete
- Firebase CLI installed (v15.37.0)
- FlutterFire CLI installed

## Run These Commands (Copy-Paste One by One)

### 1. Login to Firebase
```powershell
cd C:\Users\PC\AndroidStudioProjects\Truck\Truck\flutter_app
firebase login
```
- Press `n` when asked about Gemini (optional)
- Browser will open → Login with your Google account
- Return to terminal when done

### 2. Create Firebase Project
```powershell
firebase projects:create truckflow-app --display-name="TruckFlow"
```
- Or if project exists, skip this step

### 3. Configure FlutterFire (Auto-generate all files)
```powershell
$env:Path += ";C:\Users\PC\AppData\Local\Pub\Cache\bin"
flutterfire configure
```
- Select or create project: **truckflow-app**
- Platforms: Select Android, iOS, Web (use spacebar + enter)
- It will auto-generate:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

### 4. Enable Firebase Services in Console

Open: https://console.firebase.google.com/project/truckflow-app

**a) Enable Authentication**
1. Go to Build → Authentication → Get Started
2. Click "Sign-in method" tab
3. Enable **Google** sign-in provider
4. Save

**b) Create Firestore Database**
1. Go to Build → Firestore Database → Create database
2. Choose **Production mode**
3. Select region: **us-central1** (or closest to you)
4. Click Enable

**c) Set Firestore Rules (for authenticated users)**
1. Go to Firestore Database → Rules tab
2. Replace with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Click **Publish**

**d) Enable Storage**
1. Go to Build → Storage → Get started
2. Choose **Production mode**
3. Same region as Firestore
4. Click Done

**e) Set Storage Rules**
1. Go to Storage → Rules tab
2. Replace with:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Click **Publish**

### 5. Add SHA Fingerprints (for Google Sign-In on Android)
```powershell
cd android
.\gradlew signingReport
```
Copy the **SHA-1** and **SHA-256** lines

Go to: https://console.firebase.google.com/project/truckflow-app/settings/general
- Scroll to "Your apps" → Android app (com.truckflow.app)
- Click "Add fingerprint"
- Paste SHA-1 → Add
- Paste SHA-256 → Add

### 6. Add Google Maps API Key (Optional for now)

Go to: https://console.cloud.google.com/
- Select project: **truckflow-app**
- APIs & Services → Library
- Search "Maps SDK for Android" → Enable
- APIs & Services → Credentials → Create Credentials → API Key
- Copy the key

Edit: `android/app/src/main/AndroidManifest.xml`
Replace line 35:
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY"
```
with:
```xml
android:value="YOUR_ACTUAL_KEY_HERE"
```

### 7. Rebuild and Test
```powershell
flutter clean
flutter pub get
flutter run -d R5CTB1R0SQL
```

## ✅ Verify Firebase is Working

After running the app:
1. Try Google Sign-In → Should work
2. Create a test order/truck → Check Firestore Console → Should see data
3. Upload an image → Check Storage Console → Should see files

## Firestore Structure (Auto-created on first use)

```
firestore/
├── companies/{companyId}/
│   ├── trucks/{truckId}
│   ├── drivers/{driverId}
│   ├── orders/{orderId}
│   ├── customers/{customerId}
│   └── expenses/{expenseId}
└── users/{userId}
```

## Offline Support (Already Configured)

The app already has offline support enabled in `lib/main.dart`:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

This means:
- ✅ App works without internet
- ✅ Data syncs automatically when online
- ✅ Perfect for rural trucking routes

---

## Quick Reference Commands

**Check Firebase projects:**
```powershell
firebase projects:list
```

**Switch Firebase project:**
```powershell
firebase use truckflow-app
```

**Deploy Firestore rules:**
```powershell
firebase deploy --only firestore:rules
```

**View Firestore data:**
https://console.firebase.google.com/project/truckflow-app/firestore

**View users:**
https://console.firebase.google.com/project/truckflow-app/authentication/users

---

## Done! 🎉

After completing these steps:
- ✅ Firebase authentication works
- ✅ Firestore cloud backup enabled
- ✅ Offline sync configured
- ✅ Google Sign-In functional
- ✅ Cloud storage for images ready
