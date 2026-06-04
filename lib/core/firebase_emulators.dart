import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Point every Firebase SDK at the local **Emulator Suite** instead of the
/// production `strayfriends-utm` project.
///
/// Used by the integration tests (always — write-path tests must never touch
/// prod) and for manual runs via `flutter run --dart-define=USE_EMULATOR=true`.
///
/// Host is `localhost` for iOS Simulator / web / desktop. For the **Android
/// emulator** the host machine is `10.0.2.2`, so pass that explicitly.
Future<void> connectToFirebaseEmulators({String host = 'localhost'}) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
