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
    apiKey: 'AIzaSyCxna8YgGGwBaRnZy7vDeiAeGP4Sno1DZo',
    appId: '1:224982843189:web:e7f4129764a029e506167c',
    messagingSenderId: '224982843189',
    projectId: 'alertflow-9b044',
    authDomain: 'alertflow-9b044.firebaseapp.com',
    storageBucket: 'alertflow-9b044.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcQ_Xa5uRJUmSJlqyJKob4CLojckXU3qg',
    appId: '1:224982843189:android:7d712a685218143106167c',
    messagingSenderId: '224982843189',
    projectId: 'alertflow-9b044',
    storageBucket: 'alertflow-9b044.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAmP4kidBAuvwNTrVk8NTaCOodBKiA0ut0',
    appId: '1:224982843189:ios:6a179aa5018ad96f06167c',
    messagingSenderId: '224982843189',
    projectId: 'alertflow-9b044',
    storageBucket: 'alertflow-9b044.firebasestorage.app',
    iosBundleId: 'com.example.alertflowFrontend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAmP4kidBAuvwNTrVk8NTaCOodBKiA0ut0',
    appId: '1:224982843189:ios:6a179aa5018ad96f06167c',
    messagingSenderId: '224982843189',
    projectId: 'alertflow-9b044',
    storageBucket: 'alertflow-9b044.firebasestorage.app',
    iosBundleId: 'com.example.alertflowFrontend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCxna8YgGGwBaRnZy7vDeiAeGP4Sno1DZo',
    appId: '1:224982843189:web:8416d0f602f1c37506167c',
    messagingSenderId: '224982843189',
    projectId: 'alertflow-9b044',
    authDomain: 'alertflow-9b044.firebaseapp.com',
    storageBucket: 'alertflow-9b044.firebasestorage.app',
  );
}
