import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _functions = functions,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final UserCredential credential =
            await _auth.signInWithPopup(GoogleAuthProvider());
        await _upsertUserProfile(credential.user);
        return credential;
      }

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      final GoogleSignInAuthentication authData = await account.authentication;
      final bool hasIdToken =
          authData.idToken != null && authData.idToken!.isNotEmpty;
      final bool hasAccessToken =
          authData.accessToken != null && authData.accessToken!.isNotEmpty;

      if (!hasIdToken && !hasAccessToken) {
        throw FirebaseAuthException(
          code: 'google-sign-in-token-missing',
          message:
              'Google Sign-In did not return OAuth tokens. Enable Google in Firebase Auth and add SHA fingerprints for com.example.summerhack.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authData.accessToken,
        idToken: authData.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await _upsertUserProfile(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: _googleSignInErrorMessage(error),
      );
    }
  }

  String _googleSignInErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'google-sign-in-cancelled':
        return 'Google sign-in was cancelled.';
      case 'google-sign-in-token-missing':
        return error.message ??
            'Google Sign-In did not return tokens. Check Firebase Auth and SHA settings.';
      case 'operation-not-allowed':
        return 'Google sign-in is disabled in Firebase. Enable it in Firebase Console > Authentication > Sign-in method.';
      case 'invalid-credential':
      case 'invalid-idp-response':
      case 'invalid-identity-token':
      case 'invalid-oauth-client-id':
        return 'Google credentials were rejected. Verify package name, SHA-1/SHA-256, and regenerated Firebase config files.';
      default:
        return error.message ?? 'Google sign-in failed. Please try again.';
    }
  }

  Future<void> requestEmailOtp({required String email}) async {
    await _functions.httpsCallable('requestEmailOtp').call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
    });
  }

  Future<UserCredential> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('verifyEmailOtp').call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    });

    final Map<dynamic, dynamic> data = result.data as Map<dynamic, dynamic>;
    final String? token = data['customToken'] as String?;

    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-custom-token',
        message: 'OTP verification did not return a token.',
      );
    }

    final UserCredential credential = await _auth.signInWithCustomToken(token);
    await _upsertUserProfile(credential.user, fallbackEmail: email);
    return credential;
  }

  Future<void> _upsertUserProfile(
    User? user, {
    String? fallbackEmail,
  }) async {
    if (user == null) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(user.uid);

    final DateTime now = DateTime.now().toUtc();
    await userRef.set(<String, dynamic>{
      'fullName': user.displayName ?? 'Student',
      'email': user.email ?? fallbackEmail ?? '',
      'photoUrl': user.photoURL,
      'updatedAt': Timestamp.fromDate(now),
      'createdAt': FieldValue.serverTimestamp(),
      'defaultCurrency': 'INR',
    }, SetOptions(merge: true));
  }
}
