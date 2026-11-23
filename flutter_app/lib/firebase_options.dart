// Generated template — run `flutterfire configure` to populate with your Firebase project values.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAacgvJP530687cOHzjeJ_5shNmQuXecBs',
    appId: '1:1447270188:web:030ae263e780775031fe89',
    messagingSenderId: '1447270188',
    projectId: 'truckflow-4fccd',
    authDomain: 'truckflow-4fccd.firebaseapp.com',
    storageBucket: 'truckflow-4fccd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAacgvJP530687cOHzjeJ_5shNmQuXecBs',
    appId: '1:1447270188:android:030ae263e780775031fe89',
    messagingSenderId: '1447270188',
    projectId: 'truckflow-4fccd',
    storageBucket: 'truckflow-4fccd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAacgvJP530687cOHzjeJ_5shNmQuXecBs',
    appId: '1:1447270188:ios:030ae263e780775031fe89',
    messagingSenderId: '1447270188',
    projectId: 'truckflow-4fccd',
    storageBucket: 'truckflow-4fccd.firebasestorage.app',
    iosBundleId: 'com.truckflow.app',
  );
}