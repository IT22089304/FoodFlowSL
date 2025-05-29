// Replace with your real Firebase config
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Return the appropriate FirebaseOptions for Android/iOS/Web
    return const FirebaseOptions(
      apiKey: 'AIzaSyC_GknCorE0goHp-bDUqySS7-BmrjONXE8',
      appId: '1:804091201630:web:234dbd999f20e197c78ccf',
      messagingSenderId: '804091201630',
      projectId: 'ceylonvibes',
      storageBucket: 'ceylonvibes.appspot.com',
    );
  }
}
