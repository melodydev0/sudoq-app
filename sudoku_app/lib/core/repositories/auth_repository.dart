import 'package:firebase_auth/firebase_auth.dart';

/// Defines the contract for authentication operations.
///
/// Decouples Firebase Auth from UI and business logic layers.
abstract class AuthRepository {
  /// The currently signed-in user, or `null` if unauthenticated.
  User? get currentUser;

  /// Stream that emits whenever the auth state changes.
  Stream<User?> get authStateChanges;

  /// Sign in anonymously (guest mode).
  Future<User?> signInAnonymously();

  /// Sign in with Google.
  Future<User?> signInWithGoogle();

  /// Sign in with Apple (iOS only).
  Future<User?> signInWithApple();

  /// Sign in with email and password.
  Future<User?> signInWithEmailPassword(String email, String password);

  /// Register a new account with email and password.
  Future<User?> registerWithEmailPassword(String email, String password);

  /// Send a password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email);

  /// Update the display name of the current user.
  Future<void> updateDisplayName(String name);

  /// Sign out the current user.
  Future<void> signOut();

  /// Delete the current user's account.
  Future<void> deleteAccount();

  /// Link an anonymous account to a Google credential.
  Future<User?> linkWithGoogle();
}
