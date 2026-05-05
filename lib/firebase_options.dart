// ============================================================
// PLACEHOLDER — Replace this file before using push notifications
// ============================================================
//
// Steps to generate the real file:
//   1. Install FlutterFire CLI:
//        dart pub global activate flutterfire_cli
//
//   2. Log in to Firebase (if needed):
//        firebase login
//
//   3. Run from the project root:
//        flutterfire configure
//
//   4. Select your Firebase project and target platforms.
//      The CLI will overwrite this file with the correct values.
//
// Until this is done, Firebase.initializeApp() will throw and
// push notifications will be silently disabled (the rest of
// the app works normally).
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet.\n'
      'Run: flutterfire configure\n'
      'See: https://firebase.flutter.dev/docs/cli/',
    );
  }
}
