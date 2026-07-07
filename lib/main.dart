import 'package:animationpractice/pages/splash_screen.dart'; // Import Splash Screen
import 'package:animationpractice/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyAppGlobal());
}

class MyAppGlobal extends StatelessWidget {
  const MyAppGlobal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "HealthMate",
      themeMode: ThemeMode.system, // Follow system theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // App now always starts with the Splash Screen
      home: const SplashScreen(),
    );
  }
}