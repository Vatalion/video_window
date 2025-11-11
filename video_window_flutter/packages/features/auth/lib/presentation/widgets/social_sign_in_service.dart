import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service to handle Apple and Google Sign-In SDK integration
/// Wraps platform-specific sign-in SDKs and provides unified interface
class SocialSignInService {
  final GoogleSignIn _googleSignIn;

  SocialSignInService({
    String? googleClientId,
  }) : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          // For iOS, client ID is configured in Info.plist
          // For Android, client ID is configured in google-services.json
        );

  /// Initiate Apple Sign-In flow
  /// Returns ID token on success, null on failure/cancellation
  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Web configuration (optional, for web support)
        // webAuthenticationOptions: WebAuthenticationOptions(
        //   clientId: 'YOUR_SERVICE_ID',
        //   redirectUri: Uri.parse('YOUR_REDIRECT_URI'),
        // ),
      );

      // Return the identity token for backend verification
      return credential.identityToken;
    } catch (e) {
      // User cancelled or error occurred
      return null;
    }
  }

  /// Initiate Google Sign-In flow
  /// Returns ID token on success, null on failure/cancellation
  Future<String?> signInWithGoogle() async {
    try {
      // Sign out first to allow account picker
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled sign-in
        return null;
      }

      final auth = await account.authentication;

      // Return the ID token for backend verification
      return auth.idToken;
    } catch (e) {
      // Error occurred during sign-in
      return null;
    }
  }

  /// Check if Apple Sign-In is available on this device
  /// Apple Sign-In is only available on iOS 13+, macOS 10.15+
  Future<bool> isAppleSignInAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Sign out from Google (local only, doesn't invalidate backend tokens)
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore sign-out errors
    }
  }
}
