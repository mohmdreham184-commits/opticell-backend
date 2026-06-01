import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common.dart';
import 'root_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  late final VoidCallback _emailControllerListener;

  final _formKey = GlobalKey<FormState>();

  bool rememberMe = false;
  bool isLoading = false;
  bool obscurePassword = true;

  static const List<String> _emailDomains = [
    'gmail.com',
    'hotmail.com',
    'yahoo.com',
    'outlook.com',
  ];

  @override
  void initState() {
    super.initState();
    loadRememberedUser();
    _emailControllerListener = () {
      if (mounted) setState(() {});
    };
    emailController.addListener(_emailControllerListener);
  }

  @override
  void dispose() {
    emailController.removeListener(_emailControllerListener);
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      rememberMe = prefs.getBool("rememberMe") ?? false;

      emailController.text = prefs.getString("email") ?? "";
    });
  }

  Future<void> saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setBool("rememberMe", true);

      await prefs.setString("email", emailController.text.trim());
    } else {
      await prefs.remove("rememberMe");
      await prefs.remove("email");
    }
  }

  void goToHome(String name, String role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RootScreen(
          user: UserModel(
            name: name,
            email: emailController.text.trim(),
            role: role,
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = credential.user!.uid;
      String name = credential.user?.displayName?.trim() ?? '';
      String role = 'Lab Operator';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
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
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        // Firestore read permission is denied. Continue with default role.
      }

      if (name.isEmpty) {
        name = emailController.text.trim().split('@').first;
      }

      if (name.isNotEmpty && credential.user!.displayName != name) {
        await credential.user!.updateDisplayName(name);
      }

      await saveRememberMe();

      if (!mounted) return;

      goToHome(name, role);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Login failed";

      switch (e.code) {
        case "user-not-found":
        case "wrong-password":
        case "invalid-credential":
          message = "Invalid email or password";
          break;

        case "invalid-email":
          message = "Invalid email";
          break;

        case "too-many-requests":
          message = "Too many attempts. Try later";
          break;

        case "user-disabled":
          message = "Account disabled";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffEDEAF3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              width: width > 600 ? 500 : width * .9,
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Opticell",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Welcome Back",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 25),

                    TextFormField(
                      controller: emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _passwordFocusNode.requestFocus();
                      },
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Enter email";
                        }
                        if (!RegExp(
                          r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                        ).hasMatch(value.trim())) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    if (emailController.text.trim().isNotEmpty &&
                        !emailController.text.contains('@'))
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _emailDomains.map((domain) {
                            final suggestion =
                                '${emailController.text.trim()}@$domain';
                            return ActionChip(
                              label: Text(suggestion),
                              onPressed: () {
                                emailController.text = suggestion;
                                emailController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: suggestion.length),
                                    );
                                _passwordFocusNode.requestFocus();
                              },
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller: passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => login(),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter password";
                        }
                        return null;
                      },
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text("Remember me"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
