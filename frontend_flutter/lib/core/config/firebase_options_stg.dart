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
    apiKey: 'YOUR-STAGING-API-KEY',
    appId: 'YOUR-STAGING-APP-ID',
    messagingSenderId: 'YOUR-STAGING-SENDER-ID',
    projectId: 'cadife-smart-travel-staging',
    authDomain: 'cadife-smart-travel-staging.firebaseapp.com',
    storageBucket: 'cadife-smart-travel-staging.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR-STAGING-API-KEY',
    appId: 'YOUR-STAGING-APP-ID-ANDROID',
    messagingSenderId: 'YOUR-STAGING-SENDER-ID',
    projectId: 'cadife-smart-travel-staging',
    storageBucket: 'cadife-smart-travel-staging.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-STAGING-API-KEY',
    appId: 'YOUR-STAGING-APP-ID-IOS',
    messagingSenderId: 'YOUR-STAGING-SENDER-ID',
    projectId: 'cadife-smart-travel-staging',
    storageBucket: 'cadife-smart-travel-staging.appspot.com',
    iosBundleId: 'com.cadife.cadife_smart_travel.stg',
  );
}
