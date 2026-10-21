import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/design_system.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name is required"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated!"),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: DSAppBar(title: "EDIT PROFILE"),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kBlack))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        DSAvatar(
                          initials: _nameController.text.isNotEmpty
                              ? _nameController.text.substring(0, 1).toUpperCase()
                              : 'U',
                          size: DS.avatarXl,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(DS.spaceSm),
                            decoration: const BoxDecoration(
                              color: AppColors.kBlack,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.kWhite,
                              size: DS.iconSm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DS.spaceXl),
                  DSInput(
                    controller: _nameController,
                    label: "Full Name",
                    hint: "Enter your name",
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: DS.spaceXl),
                  DSInput(
                    controller: _phoneController,
                    label: "Phone Number",
                    hint: "Enter your phone number",
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: DS.spaceXl),
                  DSInput(
                    controller: _emailController,
                    label: "Email",
                    hint: "Enter your email",
                    prefixIcon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: DS.space2xl),
                  DSButton.primary(
                    label: "Save Changes",
                    onPressed: _saving ? null : _saveProfile,
                    loading: _saving,
                  ),
                ],
              ),
            ),
    );
  }
}