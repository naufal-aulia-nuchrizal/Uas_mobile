import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    await currentUser?.updateDisplayName(displayName);
    if (photoUrl != null) {
      await currentUser?.updatePhotoURL(photoUrl);
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
