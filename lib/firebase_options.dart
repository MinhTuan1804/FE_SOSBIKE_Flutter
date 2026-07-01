import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình Firebase từ google-services.json (project sosbike-4d6dc).
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDY7Evj6Ui4JGxbGOduxUqRBOBJaOByDXI',
    appId: '1:965904830002:web:placeholder',
    messagingSenderId: '965904830002',
    projectId: 'sosbike-4d6dc',
    authDomain: 'sosbike-4d6dc.firebaseapp.com',
    storageBucket: 'sosbike-4d6dc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDY7Evj6Ui4JGxbGOduxUqRBOBJaOByDXI',
    appId: '1:965904830002:android:86b9a86cdaa582e80d762b',
    messagingSenderId: '965904830002',
    projectId: 'sosbike-4d6dc',
    storageBucket: 'sosbike-4d6dc.firebasestorage.app',
  );
}
