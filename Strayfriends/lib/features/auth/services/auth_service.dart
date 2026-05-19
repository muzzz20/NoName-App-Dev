import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

/// Auth backend wrapping FirebaseAuth + users collection in Firestore.
///
/// Public surface (per NAD-6 AC):
/// - [registerUser]: create Firebase Auth user + users/{uid} doc
/// - [loginUser]: sign in with email/password
/// - [logoutUser]: clear session
/// - [currentUser]: synchronous current FirebaseUser (null if signed out)
/// - [authStateChanges]: stream for routing / autoroute on session changes
/// - [loadProfile]: fetch UserProfile from Firestore (called after login)
///
/// Errors thrown as [AuthFailure] with friendly messages — UI shows
/// `.message` directly without touching FirebaseAuthException codes.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user. Creates Auth account + Firestore users/{uid} doc.
  ///
  /// Throws [AuthFailure] on validation / Firebase errors.
  Future<UserProfile> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = fullName.trim();

    if (trimmedName.isEmpty) {
      throw const AuthFailure('Full name is required.');
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final uid = cred.user!.uid;

      final profile = UserProfile(
        uid: uid,
        email: trimmedEmail,
        fullName: trimmedName,
        role: 'user',
        createdAt: DateTime.now().toUtc(),
      );

      await _users.doc(uid).set(profile.toFirestore());

      // Cosmetic: set Auth displayName so it shows in Firebase console.
      await cred.user!.updateDisplayName(trimmedName);

      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  /// Sign in with email/password. Returns Firebase User; call [loadProfile]
  /// separately if you need the Firestore profile.
  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  /// Load profile doc for the given uid (defaults to current user).
  /// Returns null if the user is signed out or the doc is missing.
  Future<UserProfile?> loadProfile({String? uid}) async {
    final id = uid ?? currentUser?.uid;
    if (id == null) return null;
    final snap = await _users.doc(id).get();
    if (!snap.exists) return null;
    return UserProfile.fromFirestore(snap);
  }

  /// Send password reset email (used by Login "Forgot Password" link).
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  /// Maps FirebaseAuthException codes to user-friendly messages.
  /// Keep this internal — UI sees only [AuthFailure.message].
  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'Network error — check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled. Contact admin.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}

/// Friendly auth error suitable for surfacing in UI.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}
