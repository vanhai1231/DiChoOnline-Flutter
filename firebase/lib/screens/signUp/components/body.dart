// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// import '../../../components/buttons/socal_button.dart';
// import '../../../components/welcome_text.dart';
// import '../../../constants.dart';
// import '../../auth/auth_service.dart';
// import '../../auth/sign_in_screen.dart';
// import 'sign_up_form.dart';
//
// class Body extends StatefulWidget {
//   const Body({super.key});
//
//   @override
//   _BodyState createState() => _BodyState();
// }
//
// class _BodyState extends State<Body> {
//   // Google Sign-In function
//   final _auth = AuthService();
//
//
//
//   // Show a dialog for errors or success
//   void _showDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const WelcomeText(
//                 title: "Create Account",
//                 text: "Enter your Name, Email and Password \nfor sign up.",
//               ),
//
//               // Sign Up Form
//               const SignUpForm(),
//               const SizedBox(height: 16),
//
//               // Already have account
//               Center(
//                 child: Text.rich(
//                   TextSpan(
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall!
//                         .copyWith(fontWeight: FontWeight.w500),
//                     text: "Already have account? ",
//                     children: <TextSpan>[
//                       TextSpan(
//                         text: "Sign In",
//                         style: const TextStyle(color: primaryColor),
//                         recognizer: TapGestureRecognizer()
//                           ..onTap = () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>  SignInScreen(),
//                             ),
//                           ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Center(
//                 child: Text(
//                   "By Signing up you agree to our Terms \nConditions & Privacy Policy.",
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               kOrText,
//               const SizedBox(height: 16),
//
//               // Facebook Button
//               SocalButton(
//                 press: () {
//                   // You can add Facebook login functionality here
//                 },
//                 text: "Connect with Facebook",
//                 color: const Color(0xFF395998),
//                 icon: SvgPicture.asset(
//                   'assets/icons/facebook.svg',
//                   colorFilter: const ColorFilter.mode(
//                     Color(0xFF395998),
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Google Button
//               SocalButton(
//
//             press: () async{
//             await _auth.signUpWithGoogle(context);
//             },
//               text: "Connect with Google",
//               color:
//                const Color(0xFF4285F4),
//                 icon: SvgPicture.asset(
//                   'assets/icons/google.svg',
//                 ),
//               ),
//               const SizedBox(height: defaultPadding),
//
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
