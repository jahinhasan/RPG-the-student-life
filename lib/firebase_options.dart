import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.linux:
        return android; // Fallback to Android config for Linux prototyping
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyFWl-Wh0SVW8HtsOSzi2TtZIN_6AgZpo',
    appId: '1:916182189936:android:2f033c194529bc08c471b5',
    messagingSenderId: '916182189936',
    projectId: 'rpgthestduentlife',
    storageBucket: 'rpgthestduentlife.firebasestorage.app',
  );
}
