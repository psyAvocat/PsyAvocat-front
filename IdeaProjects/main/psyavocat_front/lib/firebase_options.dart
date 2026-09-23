// File generated for PsyAvocat multi-platform Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyCcKHezpJ89Z4uMwLwIxUYLEMsWyQ4hA',
    appId: '1:434795703982:web:831984cce60ce32b25073f',
    messagingSenderId: '434795703982',
    projectId: 'psyavocat',
    authDomain: 'psyavocat.firebaseapp.com',
    storageBucket: 'psyavocat.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgoLxwfPJ1cXA3QmGVbOhJCZgwYhx4VF8',
    appId: '1:434795703982:android:bed067525aeed62625073f',
    messagingSenderId: '434795703982',
    projectId: 'psyavocat',
    storageBucket: 'psyavocat.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA47dJa_znkSJJtMknX6JEEEPxjXLr2MtY',
    appId: '1:434795703982:ios:aee60f4d5b8f06b525073f',
    messagingSenderId: '434795703982',
    projectId: 'psyavocat',
    storageBucket: 'psyavocat.firebasestorage.app',
    iosBundleId: 'com.example.psyavocatFront',
  );
}
