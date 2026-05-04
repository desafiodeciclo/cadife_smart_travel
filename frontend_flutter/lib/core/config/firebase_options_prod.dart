import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class ProdFirebaseOptions {
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
    apiKey: 'YOUR-PROD-API-KEY',
    appId: 'YOUR-PROD-APP-ID',
    messagingSenderId: 'YOUR-PROD-SENDER-ID',
    projectId: 'cadife-smart-travel-prod',
    authDomain: 'cadife-smart-travel-prod.firebaseapp.com',
    storageBucket: 'cadife-smart-travel-prod.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR-PROD-API-KEY',
    appId: 'YOUR-PROD-APP-ID-ANDROID',
    messagingSenderId: 'YOUR-PROD-SENDER-ID',
    projectId: 'cadife-smart-travel-prod',
    storageBucket: 'cadife-smart-travel-prod.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-PROD-API-KEY',
    appId: 'YOUR-PROD-APP-ID-IOS',
    messagingSenderId: 'YOUR-PROD-SENDER-ID',
    projectId: 'cadife-smart-travel-prod',
    storageBucket: 'cadife-smart-travel-prod.appspot.com',
    iosBundleId: 'com.cadife.cadife_smart_travel',
  );
}
