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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return await _createOrUpdateUser(userCredential.user!);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Send sign in link to email
  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://blocnet.page.link/signin',
        handleCodeInApp: true,
        androidPackageName: 'com.blocnet.app',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.blocnet.app',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } catch (e) {
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
