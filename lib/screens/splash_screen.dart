import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart' as login_screen;
import 'common.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }

    if (currentUser != null) {
      final user = currentUser;
      String name = user.displayName?.trim() ?? '';
      String role = 'Lab Operator';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final String? firestoreName = (data['name'] as String?)?.trim();
          final String? firestoreRole = (data['role'] as String?)?.trim();

          if (firestoreName != null && firestoreName.isNotEmpty) {
            name = firestoreName;
          }
          if (firestoreRole != null && firestoreRole.isNotEmpty) {
            role = firestoreRole;
          }
        }
      } on FirebaseException {
        // Continue with auth state even if Firestore permissions are restricted.
      }

      if (name.isEmpty) {
        name = user.email?.split('@').first ?? 'User';
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RootScreen(
            user: UserModel(name: name, email: user.email ?? '', role: role),
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const login_screen.LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff174194),
      body: Center(
        child: Image.asset(
          "assets/splash_logo.png",
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
