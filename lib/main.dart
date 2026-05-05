import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase. If firebase_options.dart is still the placeholder
  // (i.e. flutterfire configure has not been run yet), this throws and push
  // notifications are silently disabled — the rest of the app is unaffected.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  runApp(const ResidentApp());
}
