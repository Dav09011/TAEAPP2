import 'package:firebase_core/firebase_core.dart';
import 'package:tae_app/firebase_options.dart';

class FirebaseBootstrap {
  static Future<FirebaseApp> initialize() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
