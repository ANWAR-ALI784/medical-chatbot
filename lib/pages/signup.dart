import 'package:animationpractice/models/healthMateChatScreen.dart';
import 'package:animationpractice/models/usermodel.dart';
import 'package:animationpractice/pages/loginauth.dart';
import 'package:animationpractice/pages/uihelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isDarkMode = false; // Default theme state

  Future<void> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.CustomAlertBox(context, 'Please enter all fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Firestore Save
      String uid = userCredential.user!.uid;
      UserModel newUser = UserModel(uid, "", email, ""); // Adjust based on your UserModel constructor

      await FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .set(newUser.toMap());

      if (!mounted) return;

      // 3. Success Navigation
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HealthMateChatScreen(
            isDarkMode: _isDarkMode,
            firebaseUser: userCredential.user!,
            toggleTheme: () {
              setState(() => _isDarkMode = !_isDarkMode);
            },
          ),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (ex) {
      UiHelper.CustomAlertBox(context, ex.message ?? "Signup failed.");
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
            height: MediaQuery.of(context).size.height * 0.3,
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
                  const SizedBox(height: 100),
                  // App Branding
                  const Icon(Icons.medical_services, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "HealthMate AI",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Signup Form Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Create Account",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          const SizedBox(height: 25),

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
                          const SizedBox(height: 30),

                          _isLoading
                              ? const CircularProgressIndicator(color: Colors.teal)
                              : UiHelper.CustomButton(() {
                            signUp(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          }, 'SIGN UP'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bottom Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Loginauth()), // Removed const
                          );
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}