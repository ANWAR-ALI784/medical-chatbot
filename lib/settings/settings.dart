// lib/settings/settings.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _pickedImage = picked);
  }

  // 🔹 Save profile (name, photo)
  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() => _isSavingProfile = true);

    try {
      // Update display name
      if (_nameController.text.trim().isNotEmpty) {
        await user!.updateDisplayName(_nameController.text.trim());
      }

      // Update Firestore user info
      await FirebaseFirestore.instance.collection("Users").doc(user!.uid).set({
        "fullName": _nameController.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  // 🔹 Change password
  Future<void> _changePassword() async {
    if (user == null) return;
    final currentPassword = _currentPassController.text.trim();
    final newPassword = _newPassController.text.trim();

    if (currentPassword.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Enter current password and new password (min 6 chars)")),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );
      await user!.reauthenticateWithCredential(credential);
      await user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );
      _newPassController.clear();
      _currentPassController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password change failed: $e")),
      );
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  // 🔹 Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // 🔹 Delete account
  Future<void> _deleteAccount() async {
    if (user == null) return;
    final currentPassword = _currentPassController.text.trim();

    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter password to delete account")),
      );
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );
      await user!.reauthenticateWithCredential(credential);
      await FirebaseFirestore.instance.collection("Users").doc(user!.uid).delete();
      await user!.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account deletion failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 36,
                      child: _pickedImage == null
                          ? (user?.photoURL != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                        ),
                      )
                          : const Icon(Icons.person, size: 36))
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.file(
                          File(_pickedImage!.path),
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? "HealthMate User",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text("Change profile photo"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Profile Edit (Name)
          Card(
            elevation: 1,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full name",
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSavingProfile ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal),
                          child: _isSavingProfile
                              ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ))
                              : const Text("Save Profile"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Password Change
          Card(
            elevation: 1,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _currentPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Current password",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New password",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                          _isChangingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: _isChangingPassword
                              ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ))
                              : const Text("Change Password"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Dark Mode
          SwitchListTile(
            value: themeProvider.isDarkMode,
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.dark_mode, color: Colors.teal),
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),
          const SizedBox(height: 12),

          // Logout & Delete Account Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete Account"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
