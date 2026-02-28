import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi_all;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Handles all authentication operations and Firestore user document management.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    gsi.GoogleSignIn? googleSignIn,
  })  : _auth        = auth        ?? FirebaseAuth.instance,
        _firestore   = firestore   ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? gsi.GoogleSignIn(clientId: '313969971820-g2sc3eoi3mrbhlu6grigvcoueq6ld0nf.apps.googleusercontent.com');

  final FirebaseAuth    _auth;
  final FirebaseFirestore _firestore;
  final gsi.GoogleSignIn    _googleSignIn;
  static gsi_all.GoogleSignIn? _staticWindowsSignIn;

  // ── Auth State ────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User?         get currentUser      => _auth.currentUser;

  // ── Sign In ───────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    String? idToken;
    String? accessToken;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Windows Desktop specific login
      _staticWindowsSignIn ??= gsi_all.GoogleSignIn(
        params: gsi_all.GoogleSignInParams(
          clientId: '313969971820-g2sc3eoi3mrbhlu6grigvcoueq6ld0nf.apps.googleusercontent.com',
          clientSecret: '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',
          redirectPort: 8080,
        ),
      );

      final response = await _staticWindowsSignIn!.signIn();
      if (response == null) throw const _SignInCancelledException();
      
      idToken = response.idToken;
      accessToken = response.accessToken;
    } else {
      // Mobile and Web login
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const _SignInCancelledException();

      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      idToken = googleAuth.idToken;
      accessToken = googleAuth.accessToken;
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken:     idToken,
    );

    final UserCredential result = await _auth.signInWithCredential(credential);
    final User user = result.user!;

    return upsertUserDocument(user);
  }

  // ── Sign Out ──────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait<dynamic>([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── User Document ─────────────────────────────────────────

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid)
        .withConverter<UserModel>(
          fromFirestore: (s, _) => UserModel.fromFirestore(s),
          toFirestore: (m, _) => m.toFirestore(),
        )
        .get();

    return doc.data();
  }

  Stream<UserModel?> watchCurrentUserModel() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore.collection('users').doc(user.uid)
        .withConverter<UserModel>(
          fromFirestore: (s, _) => UserModel.fromFirestore(s),
          toFirestore: (m, _) => m.toFirestore(),
        )
        .snapshots()
        .map((s) => s.data());
  }

  // ── Update Profile ────────────────────────────────────────
  
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Update Firebase Auth profile
    if (displayName != null || photoURL != null) {
      await user.updateDisplayName(displayName ?? user.displayName);
      await user.updatePhotoURL(photoURL ?? user.photoURL);
    }

    // Update Firestore document
    final ref = _firestore.collection('users').doc(user.uid);
    final Map<String, dynamic> updates = {};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoURL != null) updates['photoURL'] = photoURL;
    
    if (updates.isNotEmpty) {
      await ref.update(updates);
    }
  }

  // ── Private ───────────────────────────────────────────────

  Future<UserModel> upsertUserDocument(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      // First sign-in: create user document
      final newUser = UserModel(
        uid:         user.uid,
        email:       user.email       ?? '',
        displayName: user.displayName ?? '',
        photoURL:    user.photoURL    ?? '',
        createdAt:   DateTime.now(),
        lastActiveDate: DateTime.now(),
      );
      await ref.set(newUser.toFirestore());
      return newUser;
    } else {
      // Returning user: refresh profile info and lastActiveDate
      await ref.update({
        'displayName':   user.displayName ?? '',
        'photoURL':      user.photoURL    ?? '',
        'lastActiveDate': DateTime.now().millisecondsSinceEpoch,
      });
      final updated = await ref.get();
      return UserModel.fromFirestore(updated);
    }
  }
}

class _SignInCancelledException implements Exception {
  const _SignInCancelledException();
  @override
  String toString() => 'Google Sign-In was cancelled by the user.';
}
