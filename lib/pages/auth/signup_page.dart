import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/design_system.dart';
import 'package:serbisyo_ph/navbars/home_navigation_bar.dart';
import 'package:serbisyo_ph/navbars/provider_navigation_bar.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String _selectedRole = 'customer';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    if (nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your name.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        if (_selectedRole == 'provider') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ProviderNavigationBar(),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeNavigationBar()),
            (route) => false,
          );
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
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: DSAppBar(
        title: "CREATE ACCOUNT",
        dark: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DS.spaceXl),

              DSText.labelMedium("I am a"),
              const SizedBox(height: DS.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: DSChip(
                      label: "Customer",
                      selected: _selectedRole == 'customer',
                      onTap: () => setState(() => _selectedRole = 'customer'),
                    ),
                  ),
                  const SizedBox(width: DS.spaceMd),
                  Expanded(
                    child: DSChip(
                      label: "Provider",
                      selected: _selectedRole == 'provider',
                      onTap: () => setState(() => _selectedRole = 'provider'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DS.spaceXl),

              DSInput(
                controller: nameController,
                label: "Full Name",
                hint: "Juan Dela Cruz",
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: DS.spaceLg),

              DSInput(
                controller: emailController,
                label: "Email",
                hint: "you@email.com",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: DS.spaceLg),

              DSInput(
                controller: phoneController,
                label: "Phone Number",
                hint: "09XX XXX XXXX",
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: DS.spaceLg),

              DSInput(
                controller: passwordController,
                label: "Password",
                hint: "Min. 6 characters",
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
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

              const SizedBox(height: DS.spaceLg),

              DSInput(
                controller: confirmPasswordController,
                label: "Confirm Password",
                hint: "Re-enter your password",
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.kGreyText,
                    size: DS.iconMd,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: DS.spaceMd),
                DSText.bodySmall(_errorMessage!, color: Colors.red),
              ],

              const SizedBox(height: DS.spaceXl),

              DSButton.primary(
                label: "Create Account",
                onPressed: _loading ? null : signup,
                loading: _loading,
              ),

              const SizedBox(height: DS.spaceLg),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DSText.bodySmall("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: DSText.bodySmall("Sign In", color: AppColors.kBlack),
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