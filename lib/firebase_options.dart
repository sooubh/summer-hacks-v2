import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Run flutterfire configure to add desktop Firebase options.',
        );
      default:
        throw UnsupportedError('Unsupported platform for Firebase options.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDuOBft8SLoFsmBlFbYPcy0AM_ytdvqwno',
    appId: '1:106956907630:web:0c78471ed39e0648a7327f',
    messagingSenderId: '106956907630',
    projectId: 'summerhacks7',
    authDomain: 'summerhacks7.firebaseapp.com',
    storageBucket: 'summerhacks7.firebasestorage.app',
    measurementId: 'G-HHH3M576DM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrfqDW1ySaSTuiNpbWF5r0fWwouS2rYB0',
    appId: '1:106956907630:android:acd79e3d8c3be63da7327f',
    messagingSenderId: '106956907630',
    projectId: 'summerhacks7',
    storageBucket: 'summerhacks7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAW6P6P6K919km7Tneoy5f0f5mnDBPC8bI',
    appId: '1:106956907630:ios:724dae5a83868ca2a7327f',
    messagingSenderId: '106956907630',
    projectId: 'summerhacks7',
    storageBucket: 'summerhacks7.firebasestorage.app',
    iosBundleId: 'com.example.studentFinOs',
  );
}