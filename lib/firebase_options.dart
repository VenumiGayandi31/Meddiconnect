

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] 

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
    apiKey: 'AIzaSyCEyEXRAEyO3KZ664FPMIBGr2xy3r7Q9Yk',
    appId: '1:580464650162:web:df5d1005944df1fd8326ab',
    messagingSenderId: '580464650162',
    projectId: 'mediconnect-new-7ce7a',
    authDomain: 'mediconnect-new-7ce7a.firebaseapp.com',
    storageBucket: 'mediconnect-new-7ce7a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUWJsZI3_nfICyP68zu0DS_7VHc1sZd6g',
    appId: '1:580464650162:android:b56708d7f7796fdc8326ab',
    messagingSenderId: '580464650162',
    projectId: 'mediconnect-new-7ce7a',
    storageBucket: 'mediconnect-new-7ce7a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqt3LPDbwFV5DlUECaPFCimn5Ci1MwI94',
    appId: '1:580464650162:ios:c7b6fdc1765ae8218326ab',
    messagingSenderId: '580464650162',
    projectId: 'mediconnect-new-7ce7a',
    storageBucket: 'mediconnect-new-7ce7a.firebasestorage.app',
    iosBundleId: 'com.example.mediConnect',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDqt3LPDbwFV5DlUECaPFCimn5Ci1MwI94',
    appId: '1:580464650162:ios:c7b6fdc1765ae8218326ab',
    messagingSenderId: '580464650162',
    projectId: 'mediconnect-new-7ce7a',
    storageBucket: 'mediconnect-new-7ce7a.firebasestorage.app',
    iosBundleId: 'com.example.mediConnect',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCEyEXRAEyO3KZ664FPMIBGr2xy3r7Q9Yk',
    appId: '1:580464650162:web:c50de90cdb4fb3858326ab',
    messagingSenderId: '580464650162',
    projectId: 'mediconnect-new-7ce7a',
    authDomain: 'mediconnect-new-7ce7a.firebaseapp.com',
    storageBucket: 'mediconnect-new-7ce7a.firebasestorage.app',
  );
}
