# Android Setup Guide for TruckFlow

The Android platform structure has been created successfully! Follow these steps to complete the setup.

## ✅ What's Been Done

- Complete `android/` directory structure created
- Gradle 8.3 with AGP 8.1.0 and Kotlin 1.8.22 configured
- AndroidManifest.xml with all required permissions (location, camera, internet)
- MainActivity.kt entry point created
- All resource files (styles, launch backgrounds, icons) added
- Build configuration files properly set up

## 🔧 Required Manual Steps

### 1. Firebase Configuration

You need to generate the actual Firebase configuration:

```bash
# Option 1: Use FlutterFire CLI (recommended)
cd flutter_app
dart pub global activate flutterfire_cli
flutterfire configure

# Option 2: Manual configuration
# Download google-services.json from Firebase Console:
# Project Settings → Your Apps → Android → Download google-services.json
# Place it at: flutter_app/android/app/google-services.json
```

After running `flutterfire configure`, your `lib/firebase_options.dart` will be automatically updated with real values.

### 2. Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Maps SDK for Android**
3. Create an API key with Android restrictions
4. Replace `YOUR_GOOGLE_MAPS_API_KEY` in:
   - `android/app/src/main/AndroidManifest.xml` (line 35)

### 3. Add SHA Fingerprints to Firebase

For Google Sign-In to work, add your SHA-1 and SHA-256 fingerprints:

```bash
cd flutter_app/android
./gradlew signingReport
```

Copy the SHA-1 and SHA-256 from the debug/release variants and add them in:
**Firebase Console → Project Settings → Your Apps → Android → Add Fingerprint**

### 4. First Build

```bash
cd flutter_app
flutter pub get
flutter run
```

## 📁 Project Structure

```
flutter_app/
├── android/
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── kotlin/com/truckflow/app/MainActivity.kt
│   │   │   │   ├── res/
│   │   │   │   │   ├── drawable/
│   │   │   │   │   ├── drawable-v21/
│   │   │   │   │   ├── values/
│   │   │   │   │   ├── values-night/
│   │   │   │   │   └── mipmap-*/
│   │   │   │   └── AndroidManifest.xml
│   │   │   ├── debug/AndroidManifest.xml
│   │   │   └── profile/AndroidManifest.xml
│   │   ├── build.gradle
│   │   └── .gitignore
│   ├── gradle/
│   │   └── wrapper/
│   │       ├── gradle-wrapper.jar
│   │       └── gradle-wrapper.properties
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   └── .gitignore
├── lib/
├── pubspec.yaml
└── README.md
```

## 🎯 Next Steps

1. **Run `flutterfire configure`** to set up Firebase
2. **Add your Google Maps API key** to AndroidManifest.xml
3. **Open project in Android Studio**: `File → Open → flutter_app/`
4. **Let Gradle sync** (first time may take a few minutes)
5. **Connect device/emulator and run**: `flutter run`

## 🐛 Troubleshooting

### Gradle sync fails
- Ensure you have internet connection (Gradle downloads dependencies)
- Check Android Studio → Settings → Build Tools → Gradle → Use Gradle JDK 17+

### Google Maps not showing
- Verify API key is added to AndroidManifest.xml
- Ensure Maps SDK for Android is enabled in Google Cloud Console
- Check API key restrictions allow your app's package name

### Firebase authentication fails
- Verify SHA-1 and SHA-256 fingerprints are added to Firebase Console
- Ensure google-services.json is in `android/app/`
- Check firebase_options.dart has real values (not placeholders)

### Build fails with "Execution failed for task"
- Run: `cd android && ./gradlew clean`
- Then: `flutter clean && flutter pub get`

## 📖 Reference

Your setup is based on the working configuration from:
`C:\Users\PC\AndroidStudioProjects\mymoney`

All Gradle versions, SDK levels, and configurations match the tested working project.
