import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/platform_utils.dart';

/// Authentication service wrapping Supabase Auth with Google providers.
/// Supports guest mode where users can use the app without signing in.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Current authenticated user, or null if guest.
  User? get currentUser => _client.auth.currentUser;

  /// True if user is not signed in (guest mode).
  bool get isGuest => currentUser == null;

  /// User's email if signed in.
  String? get email => currentUser?.email;

  /// User's Supabase UID if signed in.
  String? get userId => currentUser?.id;

  /// Stream of auth state changes for reactive UI.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Google. Works on both Android and iOS.
  Future<(AuthResponse, String?)> signInWithGoogle() async {
    // Web-specific handling: Use Supabase OAuth redirect flow
    if (PlatformUtils.isWeb) {
      // Get current URL dynamically (works for localhost, GitHub Pages, any host)
      final redirectUrl = Uri.base.toString();

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      // On web, this triggers a redirect, so we never strictly "return" a signed-in user here
      // in the same session before the page reload.
      // We throw a special exception or return dummy data to signal 'redirecting'.
      throw const AuthException('Redirecting to Google...', statusCode: '302');
    }

    // Mobile handling (iOS/Android): Use native Google Sign-In
    // iOS client ID (from Google Cloud Console)
    // Set to null if not using iOS or if relying on Firebase/GoogleService-Info.plist
    const String? iosClientId = null;

    // Web Client ID from Google Cloud Console - REQUIRED for Android to receive ID token
    // This is the OAuth 2.0 Client ID of type "Web application" (same one used for Supabase)
    // Get this from: Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client IDs
    const String webClientId =
        '858277632380-p1juadqdn8pph9aipa6ju6esusi3f9f4.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      clientId: PlatformUtils.isIOS ? iosClientId : null,
      serverClientId: webClientId, // Required for ID token on Android
      scopes: ['openid', 'email', 'profile'],
    );

    var startGoogleUser = await googleSignIn.signIn();
    if (startGoogleUser == null) {
      throw const AuthException('Google sign-in was cancelled');
    }

    var googleAuth = await startGoogleUser.authentication;
    var idToken = googleAuth.idToken;
    var accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('No ID token received from Google');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return (response, startGoogleUser.photoUrl);
  }

  /// Sign out and return to guest mode.
  /// Local data is preserved.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Delete the user's account and all associated cloud data.
  /// This is irreversible.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Call the 'delete_user' RPC function to delete from auth.users
      // The user must create this function in Supabase (see documentation)
      await _client.rpc('delete_user');
    } catch (e) {
      // Fallback: manual data deletion if RPC fails or doesn't exist
      await _client.from('meals').delete().eq('user_id', user.id);
      await _client.from('weights').delete().eq('user_id', user.id);
      await _client.from('profiles').delete().eq('id', user.id);
    }

    // Sign out
    await signOut();
  }
}
