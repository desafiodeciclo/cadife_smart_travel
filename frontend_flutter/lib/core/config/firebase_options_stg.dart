import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class StagingFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDk850eqZIuPJYHFdg6Ylj2IwXjc2xITZE',
    appId: '1:260275090433:web:your-web-id', // Placeholder se precisar de web
    messagingSenderId: '260275090433',
    projectId: 'cadife-smart-travel-staging',
    authDomain: 'cadife-smart-travel-staging.firebaseapp.com',
    storageBucket: 'cadife-smart-travel-staging.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDk850eqZIuPJYHFdg6Ylj2IwXjc2xITZE',
    appId: '1:260275090433:android:9baf2e65d15390ef3cfc00',
    messagingSenderId: '260275090433',
    projectId: 'cadife-smart-travel-staging',
    storageBucket: 'cadife-smart-travel-staging.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDk850eqZIuPJYHFdg6Ylj2IwXjc2xITZE',
    appId: 'YOUR-STAGING-APP-ID-IOS',
    messagingSenderId: '260275090433',
    projectId: 'cadife-smart-travel-staging',
    storageBucket: 'cadife-smart-travel-staging.firebasestorage.app',
    iosBundleId: 'com.cadife.cadife_smart_travel.stg',
  );
}
