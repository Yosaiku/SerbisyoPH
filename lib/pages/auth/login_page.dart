import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/design_system.dart';
import 'package:serbisyo_ph/pages/auth/signup_page.dart';
import 'package:serbisyo_ph/navbars/home_navigation_bar.dart';
import 'package:serbisyo_ph/navbars/provider_navigation_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final role = doc.data()?['role'] ?? 'customer';

        if (mounted) {
          if (role == 'provider') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const ProviderNavigationBar(),
              ),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomeNavigationBar(),
              ),
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.code);
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DS.space2xl),

              DSText.displayLarge("Serbisyo PH"),
              const SizedBox(height: DS.spaceSm),
              DSText.bodySmall("Sign in to your account"),

              const SizedBox(height: DS.space2xl),

              DSInput(
                controller: emailController,
                label: "Email",
                hint: "you@email.com",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: DS.spaceLg),

              DSInput(
                controller: passwordController,
                label: "Password",
                hint: "••••••••",
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: login,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.kGreyText,
                    size: DS.iconMd,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: DS.spaceMd),
                DSText.bodySmall(_errorMessage!, color: Colors.red),
              ],

              const SizedBox(height: DS.spaceXl),

              DSButton.primary(
                label: "Sign In",
                onPressed: _loading ? null : login,
                loading: _loading,
              ),

              const SizedBox(height: DS.spaceLg),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DSText.bodySmall("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    child: DSText.bodySmall("Sign Up", color: AppColors.kBlack),
                  ),
                ],
              ),

              const SizedBox(height: DS.space2xl),
            ],
          ),
        ),
      ),
    );
  }
}