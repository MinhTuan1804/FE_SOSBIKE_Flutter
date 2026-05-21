import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình Firebase từ google-services.json (project sosbike-7b6bb).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase chưa cấu hình cho ${defaultTargetPlatform.name}.',
        );
    }
  }

  /// Cần thêm app Web trên Firebase Console để bật Firebase Auth trên web.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDb4RZNDNs0lOIk0_3hJw5L5M8J8sULy14',
    appId: '1:835951049167:web:0000000000000000000000',
    messagingSenderId: '835951049167',
    projectId: 'sosbike-7b6bb',
    authDomain: 'sosbike-7b6bb.firebaseapp.com',
    storageBucket: 'sosbike-7b6bb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDb4RZNDNs0lOIk0_3hJw5L5M8J8sULy14',
    appId: '1:835951049167:android:f7dde8482558f70100faba',
    messagingSenderId: '835951049167',
    projectId: 'sosbike-7b6bb',
    storageBucket: 'sosbike-7b6bb.firebasestorage.app',
  );
}
