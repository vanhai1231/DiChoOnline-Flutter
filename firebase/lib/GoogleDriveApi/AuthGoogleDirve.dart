import 'package:google_sign_in/google_sign_in.dart';

class AuthGoogleDrive {
  static final _instance = AuthGoogleDrive._();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
  );

  AuthGoogleDrive._();

  factory AuthGoogleDrive() {
    return _instance;
  }

  /// Sign in with Google
  /// returns auth-headers on success, else null
  Future<Map<String, String>?> googleSignIn() async {
    try {
      GoogleSignInAccount? googleAccount;
      if (_googleSignIn.currentUser == null) {
        googleAccount = await _googleSignIn.signIn();
      } else {
        googleAccount = await _googleSignIn.signInSilently();
      }

      return await googleAccount?.authHeaders;
    } catch (e) {
      return null;
    }
  }

  /// sign out google account
  Future<void> googleSignOut() => _googleSignIn.signOut();
}