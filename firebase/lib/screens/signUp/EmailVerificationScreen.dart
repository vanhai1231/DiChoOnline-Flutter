import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/sign_in_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late User? user;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _checkEmailVerification();
  }

  // Check email verification status
  Future<void> _checkEmailVerification() async {
    await user?.reload();
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isEmailVerified)
              const Text("Your email has been verified! You can now log in.")
            else
              Column(
                children: [
                  const Text("Please check your email to verify your account."),
                  ElevatedButton(
                    onPressed: () async {
                      await user?.sendEmailVerification();
                      _checkEmailVerification();
                    },
                    child: const Text("Resend Verification Email"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print("Is Email Verified: $_isEmailVerified");
                      if (_isEmailVerified) {
                        // Navigate to the SignInScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) =>  SignInScreen()),
                        );
                      }
                    },
                    child: const Text("Go to Login"),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }
}
