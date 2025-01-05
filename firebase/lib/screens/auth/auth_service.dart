import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../currentAddress/find_restaurants_screen.dart';


class AuthService {
  final _auth = FirebaseAuth.instance;
  final _storage = FlutterSecureStorage();

  // Đăng nhập bằng email và mật khẩu
  Future<void> signInWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await saveCredentials(email, password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FindRestaurantsScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này.';
          break;
        case 'wrong-password':
          message = 'Sai mật khẩu.';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ.';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa.';
          break;
        default:
          message = 'Đăng nhập thất bại: ${e.message}';
      }
      throw Exception(message);
    }
  }

  // Đăng nhập bằng vân tay hoặc nhận diện khuôn mặt (sử dụng thông tin đã lưu)
  Future<void> signInWithBiometrics(BuildContext context) async {
    try {
      final credentials = await getStoredCredentials();
      if (credentials != null) {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: credentials['email']!,
          password: credentials['password']!,
        );

        if (userCredential.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FindRestaurantsScreen()),
          );
        }
      }
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // Lấy thông tin tài khoản đã lưu từ secure storage
  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // Lưu thông tin tài khoản vào secure storage
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  // Đăng nhập bằng tài khoản Google
  Future<void> signUpWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception("Quá trình đăng nhập Google bị hủy.");
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FindRestaurantsScreen()),
      );
    } catch (e) {
      log('Lỗi khi đăng nhập bằng Google: ${e.toString()}'); // In lỗi chi tiết
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng nhập bằng Google: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
//Dang nhap voi Facebook
  Future<void> signInWithFacebook(BuildContext context) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.token,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FindRestaurantsScreen()),
        );
      }
    } catch (e) {
      log('Lỗi khi đăng nhập bằng Facebook: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng nhập bằng Facebook: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Kiểm tra trạng thái đăng nhập
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // Lấy thông tin user hiện tại
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
