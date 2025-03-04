// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBl9YcGjfApYvkTcVDfudLjNSsRaLQTz-Y',
    appId: '1:732413251106:web:5c22aba680fa88f114c47b',
    messagingSenderId: '732413251106',
    projectId: 'mememates1',
    authDomain: 'mememates1.firebaseapp.com',
    databaseURL: 'https://mememates1-default-rtdb.firebaseio.com',
    storageBucket: 'mememates1.firebasestorage.app',
    measurementId: 'G-5NMXSLHCYE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbCc4sx_possVwCnIEnwVJS0DrO3YI7KY',
    appId: '1:732413251106:android:0f674052976b7aa114c47b',
    messagingSenderId: '732413251106',
    projectId: 'mememates1',
    databaseURL: 'https://mememates1-default-rtdb.firebaseio.com',
    storageBucket: 'mememates1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC9ileZ41OTbTx5U1sL-ZwMlB_pqu8ZsRs',
    appId: '1:732413251106:ios:ab70684173e7c0a314c47b',
    messagingSenderId: '732413251106',
    projectId: 'mememates1',
    databaseURL: 'https://mememates1-default-rtdb.firebaseio.com',
    storageBucket: 'mememates1.firebasestorage.app',
    androidClientId: '732413251106-5ksk6v45b9kku1ccbpn03abjmkjvv0o7.apps.googleusercontent.com',
    iosClientId: '732413251106-21e8iqa18b6fagsqvpmde2dfitpj364m.apps.googleusercontent.com',
    iosBundleId: 'com.example.mememates',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC9ileZ41OTbTx5U1sL-ZwMlB_pqu8ZsRs',
    appId: '1:732413251106:ios:ab70684173e7c0a314c47b',
    messagingSenderId: '732413251106',
    projectId: 'mememates1',
    databaseURL: 'https://mememates1-default-rtdb.firebaseio.com',
    storageBucket: 'mememates1.firebasestorage.app',
    androidClientId: '732413251106-5ksk6v45b9kku1ccbpn03abjmkjvv0o7.apps.googleusercontent.com',
    iosClientId: '732413251106-21e8iqa18b6fagsqvpmde2dfitpj364m.apps.googleusercontent.com',
    iosBundleId: 'com.example.mememates',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBl9YcGjfApYvkTcVDfudLjNSsRaLQTz-Y',
    appId: '1:732413251106:web:5c22aba680fa88f114c47b',
    messagingSenderId: '732413251106',
    projectId: 'mememates1',
    authDomain: 'mememates1.firebaseapp.com',
    databaseURL: 'https://mememates1-default-rtdb.firebaseio.com',
    storageBucket: 'mememates1.firebasestorage.app',
    measurementId: 'G-5NMXSLHCYE',
  );

}