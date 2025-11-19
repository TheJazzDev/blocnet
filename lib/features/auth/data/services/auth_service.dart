import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      print('🔵 [AUTH] Starting Google Sign In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🔵 [AUTH] Google user selected: ${googleUser?.email}');

      if (googleUser == null) {
        print('🟡 [AUTH] User canceled Google Sign In');
        return null; // User canceled
      }

      print('🔵 [AUTH] Getting Google authentication...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔵 [AUTH] AccessToken: ${googleAuth.accessToken != null ? "Present" : "Missing"}');
      print('🔵 [AUTH] IdToken: ${googleAuth.idToken != null ? "Present" : "Missing"}');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔵 [AUTH] Signing in with Firebase credential...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print('🟢 [AUTH] Firebase sign in successful: ${userCredential.user?.email}');

      return await _createOrUpdateUser(userCredential.user!);
    } catch (e, stackTrace) {
      print('🔴 [AUTH ERROR] Google sign in failed:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Google sign in failed: $e');
    }
  }

  // Send sign in link to email
  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      print('🔵 [AUTH] Sending sign-in link to: $email');

      final actionCodeSettings = ActionCodeSettings(
        url: 'https://blocnet-f2c6e.firebaseapp.com/__/auth/action',
        handleCodeInApp: true,
        androidPackageName: 'com.example.blocnet',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.example.blocnet',
      );

      print('🔵 [AUTH] Action code settings:');
      print('  URL: https://blocnet-f2c6e.firebaseapp.com/__/auth/action');
      print('  Android Package: com.example.blocnet');
      print('  iOS Bundle: com.example.blocnet');

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      print('🟢 [AUTH] Sign-in link sent successfully to: $email');
    } catch (e, stackTrace) {
      print('🔴 [AUTH ERROR] Failed to send sign-in link:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to send sign in link: $e');
    }
  }

  // Sign in with email link
  Future<AppUser?> signInWithEmailLink(String email, String emailLink) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailLink(email: email, emailLink: emailLink);

      return await _createOrUpdateUser(userCredential.user!);
    } catch (e) {
      throw Exception('Email link sign in failed: $e');
    }
  }

  // Verify if link is a sign in link
  bool isSignInWithEmailLink(String emailLink) {
    return _auth.isSignInWithEmailLink(emailLink);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Create or update user in Firestore
  Future<AppUser> _createOrUpdateUser(User firebaseUser) async {
    final userDoc =
        _firestore.collection('users').doc(firebaseUser.uid);

    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      // Update last active
      await userDoc.update({
        'lastActive': Timestamp.now(),
      });

      return AppUser.fromFirestore(
        docSnapshot,
        null,
      );
    } else {
      // Create new user
      final newUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await userDoc.set(newUser.toJson());

      return newUser;
    }
  }

  // Get user profile from Firestore
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      return AppUser.fromFirestore(
        doc,
        null,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('No user signed in');

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (bio != null) updates['bio'] = bio;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('No user signed in');

      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete Firebase Auth account
      await currentUser!.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
