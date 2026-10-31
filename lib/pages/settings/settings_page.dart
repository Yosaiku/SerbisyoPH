import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:serbisyo_ph/theme/design_system.dart";
import "package:serbisyo_ph/pages/auth/login_page.dart";
import "package:serbisyo_ph/pages/notifications/notifications_page.dart";
import "package:serbisyo_ph/pages/settings/edit_profile_page.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showRoleSwitchDialog() {
    final currentRole = _userData?["role"] ?? "customer";
    final newRole = currentRole == "provider" ? "customer" : "provider";
    final newRoleLabel = newRole == "provider" ? "Provider" : "Customer";

    showDialog(
      context: context,
      builder: (context) => DSDialog(
        title: "Switch to $newRoleLabel",
        content: DSText.bodyMedium(
          "This will change your account type to $newRoleLabel. You will be signed out and need to sign in again.",
          color: AppColors.kGreyText,
        ),
        actions: [
          DSButton.secondary(
            label: "Cancel",
            onPressed: () => Navigator.pop(context),
          ),
          DSButton.primary(
            label: "Switch",
            onPressed: () => _switchRole(newRole),
          ),
        ],
      ),
    );
  }

  Future<void> _switchRole(String newRole) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Navigator.pop(context);

    try {
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "role": newRole,
        "has_completed_setup": false,
      });

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account switched to ${newRole == "provider" ? "Provider" : "Customer"}. Please sign in again."),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: DSAppBar(title: "Settings"),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kBlack))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: DS.spaceXl),
                  DSSectionHeader(title: "Account Type"),
                  const SizedBox(height: DS.spaceMd),
                  DSActionTile(
                    icon: _userData?["role"] == "provider" ? Icons.storefront : Icons.person_outline,
                    title: _userData?["role"] == "provider" ? "Provider Account" : "Customer Account",
                    subtitle: "Switch to ${_userData?["role"] == "provider" ? "Customer" : "Provider"} mode",
                    trailing: DSRoleBadge(role: _userData?["role"] ?? "customer", small: true),
                    onTap: _showRoleSwitchDialog,
                  ),
                  const SizedBox(height: DS.spaceXl),
                  DSSectionHeader(title: "Account"),
                  const SizedBox(height: DS.spaceMd),
                  DSActionTile(
                    icon: Icons.person_outline,
                    title: "Edit Profile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  DSActionTile(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: DS.spaceXl),
                  DSSectionHeader(title: "Support"),
                  const SizedBox(height: DS.spaceMd),
                  DSActionTile(
                    icon: Icons.help_outline,
                    title: "Help Center",
                    onTap: () {},
                  ),
                  DSActionTile(
                    icon: Icons.info_outline,
                    title: "About",
                    onTap: () {},
                  ),
                  const SizedBox(height: DS.spaceXl),
                  DSActionTile(
                    icon: Icons.logout,
                    title: "Log Out",
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _logout,
                  ),
                  const SizedBox(height: DS.space2xl),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return DSCard(
      padding: const EdgeInsets.all(DS.spaceLg),
      child: Row(
        children: [
          DSAvatar(
            initials: _userData?["name"]?.substring(0, 1).toUpperCase() ?? "U",
            size: DS.avatarLg,
          ),
          const SizedBox(width: DS.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DSText.headlineMedium(_userData?["name"] ?? "User"),
                    const SizedBox(width: DS.spaceMd),
                    DSRoleBadge(role: _userData?["role"] ?? "customer", small: true),
                  ],
                ),
                const SizedBox(height: DS.spaceXs),
                DSText.bodySmall(_userData?["email"] ?? ""),
                if (_userData?["phone"] != null) ...[
                  const SizedBox(height: DS.spaceXs),
                  DSText.bodySmall(_userData!["phone"]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
