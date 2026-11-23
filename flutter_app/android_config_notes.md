# Android Configuration Notes for TruckFlow

## 1. `android/app/src/main/AndroidManifest.xml`

Add required permissions above `<application>` and the Google Maps API key inside `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Network & Location Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Camera / Photo Picker for Truck Photos & Expense Receipts -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

    <!-- Required on Android 11+ to launch WhatsApp / Tel / Mailto via url_launcher -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
    </queries>

    <application
        android:label="TruckFlow"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Google Maps SDK API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY" />

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## 2. `android/app/build.gradle` (or `build.gradle.kts`)

Ensure `minSdk` is at least `23` (required by `firebase_auth` & `google_maps_flutter`):

```groovy
android {
    defaultConfig {
        applicationId "com.truckflow.app"
        minSdk = 23
        targetSdk = 34
        multiDexEnabled true
    }
}
```

## 3. `google-services.json`

1. Run `flutterfire configure` OR download `google-services.json` from **Firebase Console → Project Settings → Your Apps → Android**.
2. Place it at `android/app/google-services.json`.
3. Add your debug and release **SHA-1** and **SHA-256** fingerprints in Firebase Console so Google Sign-In works seamlessly:
   ```bash
   cd android && ./gradlew signingReport
   ```
