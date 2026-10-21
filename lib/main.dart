import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:serbisyo_ph/firebase_options.dart';
import 'package:serbisyo_ph/navbars/home_navigation_bar.dart';
import 'package:serbisyo_ph/navbars/provider_navigation_bar.dart';
import 'package:serbisyo_ph/pages/auth/login_page.dart';
import 'package:serbisyo_ph/services/notification_service.dart';
import 'package:serbisyo_ph/theme/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const SerbisyoApp());
}

class SerbisyoApp extends StatelessWidget {
  const SerbisyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serbisyo PH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.kBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.kBlack,
          secondary: AppColors.kGreyText,
          surface: AppColors.kWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.kBlack,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: DS.headlineMedium,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.kBorder,
          thickness: 1,
          space: DS.spaceXl,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DS.radiusMd),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DS.radiusMd),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DS.radiusMd),
            borderSide: const BorderSide(color: AppColors.kBlack, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DS.spaceLg,
            vertical: DS.spaceMd,
          ),
          hintStyle: DS.bodySmall,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kBlack,
            foregroundColor: AppColors.kWhite,
            elevation: 0,
            minimumSize: const Size(double.infinity, DS.btnHeightLg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DS.radiusLg),
            ),
            textStyle: DS.labelMedium,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kBlack,
            minimumSize: const Size(double.infinity, DS.btnHeightLg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DS.radiusLg),
            ),
            side: const BorderSide(color: AppColors.kBorder),
            textStyle: DS.labelMedium,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
          side: const BorderSide(color: AppColors.kBorder),
          selectedColor: AppColors.kBlack,
          labelStyle: DS.labelMedium,
          secondaryLabelStyle: DS.labelMedium.copyWith(color: AppColors.kWhite),
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceMd, vertical: DS.spaceXs),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const RoleBasedNavigation();
        }

        return const LoginPage();
      },
    );
  }
}

class RoleBasedNavigation extends StatefulWidget {
  const RoleBasedNavigation({super.key});

  @override
  State<RoleBasedNavigation> createState() => _RoleBasedNavigationState();
}

class _RoleBasedNavigationState extends State<RoleBasedNavigation> {
  String? _userRole;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    NotificationService().initialize();
  }

  Future<void> _fetchUserRole() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'customer';
          _loading = false;
        });
      } else {
        setState(() {
          _userRole = 'customer';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userRole = 'customer';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _userRole == 'provider'
        ? const ProviderNavigationBar()
        : const HomeNavigationBar();
  }
}
