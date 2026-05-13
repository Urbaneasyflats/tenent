import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYc03x04xoZ6ND6NE4x_d4FhDibA6Q9BM',
    appId: '1:403657963841:android:70aae2cb4e4c73055d49c0',
    messagingSenderId: '403657963841',
    projectId: 'urbaneasyflats-e9af3',
    storageBucket: 'urbaneasyflats-e9af3.firebasestorage.app',
  );
}
