import 'package:animationpractice/models/healthMateChatScreen.dart';
import 'package:animationpractice/pages/signup.dart';
import 'package:animationpractice/pages/uihelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Loginauth extends StatefulWidget {
  const Loginauth({super.key});

  @override
  State<Loginauth> createState() => _LoginauthState();
}

class _LoginauthState extends State<Loginauth> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isDarkMode = false;
  bool _isLoading = false;

  /// Login function
  void login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.CustomAlertBox(context, "Please fill in all fields.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Sign-In
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Fetch user data from Firestore
      String uid = userCredential.user!.uid;
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (!userData.exists) {
        UiHelper.CustomAlertBox(context, "User data not found!");
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      // Navigate to HealthMateChatScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HealthMateChatScreen(
            isDarkMode: isDarkMode,
            toggleTheme: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
            firebaseUser: userCredential.user!,
          ),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (ex) {
      UiHelper.CustomAlertBox(context, ex.message ?? "Login failed.");
    } catch (e) {
      UiHelper.CustomAlertBox(context, "An error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Professional Teal Header Background
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // App Icon and Title
                  const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "HealthMate AI",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Login Card
                  Card(
                    elevation: 10,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Column(
                        children: [
                          const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Login to continue your health journey",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 30),

                          UiHelper.CustomTesxtField(
                            emailController,
                            'Email Address',
                            Icons.email_outlined,
                            false,
                          ),
                          const SizedBox(height: 20),

                          UiHelper.CustomTesxtField(
                            passwordController,
                            'Password',
                            Icons.lock_outline,
                            true,
                          ),
                          const SizedBox(height: 35),

                          _isLoading
                              ? const CircularProgressIndicator(color: Colors.teal)
                              : UiHelper.CustomButton(() {
                            login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          }, 'LOGIN'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bottom Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an Account? ", style: TextStyle(fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Signup()),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}