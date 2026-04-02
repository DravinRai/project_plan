import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:project_plan/features/auth/models/user_model.dart';

/// Handles all authentication operations and Firestore user document management.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    gsi.GoogleSignIn? googleSignIn,
  })  : _auth        = auth        ?? FirebaseAuth.instance,
        _firestore   = firestore   ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? gsi.GoogleSignIn(
          // On Android, clientId is read automatically from google-services.json.
          // Passing it explicitly on Android causes sign-in to fail.
          clientId: defaultTargetPlatform == TargetPlatform.android
              ? null
              : '***REMOVED_CLIENT_ID***',
        );

  final FirebaseAuth    _auth;  
  final FirebaseFirestore _firestore;
  final gsi.GoogleSignIn    _googleSignIn;

  // ── Auth State ────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User?         get currentUser      => _auth.currentUser;

  // ── Sign In ───────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    String? idToken;
    String? accessToken;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final result = await _signInWithGoogleWindowsNative();
      accessToken = result.$1;
      idToken = result.$2;
    } else {
      // Mobile and Web login
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const _SignInCancelledException();

      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      idToken = googleAuth.idToken;
      accessToken = googleAuth.accessToken;
    }

    AuthCredential credential;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // On Windows Desktop, the idToken is minted for the Desktop OAuth Client ID.
      // Firebase Auth often rejects this if it expects the Web Client ID.
      // We pass only the accessToken which is sufficient for Firebase to authenticate.
      credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
      );
    } else {
      credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken:     idToken,
      );
    }

    final UserCredential result = await _auth.signInWithCredential(credential);
    final User user = result.user!;

    final userModel = await upsertUserDocument(user);
    return userModel;
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
    // Use switchMap on authStateChanges so that:
    // 1. During startup, when currentUser is momentarily null, we emit null
    //    instead of hitting Firestore without credentials.
    // 2. When the user signs in/out, the Firestore listener automatically
    //    switches to the correct user document (or stops listening).
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _firestore
          .collection('users')
          .doc(user.uid)
          .withConverter<UserModel>(
            fromFirestore: (s, _) => UserModel.fromFirestore(s),
            toFirestore: (m, _) => m.toFirestore(),
          )
          .snapshots()
          .map((s) => s.data());
    });
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
        'lastActiveDate': DateTime.now(),
      });
      final updated = await ref.get();
      return UserModel.fromFirestore(updated);
    }
  }

  // ── Windows Native Google Auth (PKCE Flow) ───────────────────

  String _generateCodeVerifier() {
    var random = Random.secure();
    var values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  String _generateCodeChallenge(String verifier) {
    var bytes = utf8.encode(verifier);
    var digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  Future<(String?, String?)> _signInWithGoogleWindowsNative() async {
    const clientId = '***REMOVED_CLIENT_ID***';
    const port = 8080;
    const redirectUri = 'http://localhost:$port';

    final verifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(verifier);

    // Start local server to listen for the OAuth callback
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'email profile openid',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
    });

    // Launch the system browser
    await launchUrl(authUrl);

    // Wait for the browser to redirect back to localhost
    final request = await server.first;
    final code = request.uri.queryParameters['code'];
    // Load the app icon dynamically to display in the success/error page
    String? base64Logo;
    try {
      final ByteData data = await rootBundle.load('assets/images/app_icon.png');
      base64Logo = base64Encode(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('Could not load app icon for auth page: $e');
    }

    final String logoHtml = base64Logo != null 
        ? '<img class="logo-icon" src="data:image/png;base64,$base64Logo" alt="App Logo" />'
        : '<!-- No logo loaded -->';
    
    debugPrint('Auth Page: App icon loaded successfully, base64 length: ${base64Logo?.length ?? 0}');

    const String errorHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Sign in failed</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter:wght@400;500&display=swap');
    body { margin: 0; padding: 0; background-color: #171514; color: #E8E2D9; font-family: 'Inter', sans-serif; display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100vh; text-align: center; }
    h1 { font-family: 'Instrument Serif', serif; font-size: 3.5rem; font-weight: normal; margin: 0 0 1rem 0; }
    p { font-size: 1.05rem; color: #A09D98; margin: 0; }
  </style>
</head>
<body>
  <h1>Authentication Failed</h1>
  <p>Something went wrong. You may close this window and try again.</p>
</body>
</html>
''';

    final error = request.uri.queryParameters['error'];
    if (error != null || code == null) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.html
        ..write(errorHtml);
      await request.response.close();
      await server.close();
      throw const _SignInCancelledException();
    }

    final String successHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Sign in complete</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter:wght@400;500&display=swap');
    
    body {
      margin: 0;
      padding: 0;
      background-color: #171514;
      color: #E8E2D9;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
      text-align: center;
    }

    .logo-container {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 2rem;
    }

    .logo-text {
      font-family: 'Instrument Serif', serif;
      font-size: 2.2rem;
      font-weight: normal;
      color: #FFFFFF;
      letter-spacing: 0.5px;
    }

    .logo-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.5);
    }

    h1 {
      font-family: 'Instrument Serif', serif;
      font-size: 3.5rem;
      font-weight: normal;
      margin: 0 0 1rem 0;
      color: #E6E1D8;
    }

    p {
      font-size: 1.05rem;
      color: #A09D98;
      margin: 0;
    }
  </style>
</head>
<body>
  <div class="logo-container">
    $logoHtml
    <div class="logo-text">Pie</div>
  </div>
  <h1>Sign in complete</h1>
  <p>You can now close this window and return to the Pie app.</p>
</body>
</html>
''';

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write(successHtml);
    await request.response.close();
    await server.close();

    // Exchange the code and verifier for an access token directly with Google
    final tokenResponse = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        'client_id': clientId,
        'client_secret': '***REMOVED_SECRET***',
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (tokenResponse.statusCode == 200) {
      final data = jsonDecode(tokenResponse.body);
      return (data['access_token'] as String?, data['id_token'] as String?);
    } else {
      throw Exception('Failed to exchange token: ${tokenResponse.body}');
    }
  }
}

class _SignInCancelledException implements Exception {
  const _SignInCancelledException();
  @override
  String toString() => 'Google Sign-In was cancelled by the user.';
}
