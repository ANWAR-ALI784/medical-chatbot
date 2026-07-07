import 'dart:io';
import 'package:animationpractice/main.dart';
import 'package:animationpractice/pages/cloudinaryimageupload/cloudinaryimageuplaod.dart';
import 'package:animationpractice/pages/homenext.dart';
import 'package:animationpractice/pages/uihelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../models/usermodel.dart';

class Profilepage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const Profilepage({
    super.key,
    required this.userModel,
    required this.firebaseUser,
  });

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  TextEditingController fullName = TextEditingController();
  File? _imageFile;

  void selectImage(ImageSource source) async {
    XFile? pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      cropImage(pickedImage);
    }
  }

  void cropImage(XFile file) async {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 20,
    );
    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }

  void showPhotoOption() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload Profile Picture"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  selectImage(ImageSource.gallery);
                },
                leading: const Icon(Icons.image),
                title: const Text("Select from Gallery"),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  selectImage(ImageSource.camera);
                },
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text("Take a Photo"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile page"), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade400,
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              radius: 60,
              child: GestureDetector(
                onTap: showPhotoOption,
                child: (_imageFile == null)
                    ? const Icon(Icons.person, size: 70, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: TextField(
              controller: fullName,
              decoration: const InputDecoration(
                hintText: "Full Name",
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          UiHelper.CustomButton(() async {
            if (_imageFile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select an image")),
              );
              return;
            }

            String? imageUrl = await CloudinaryUploader.uploadFile(_imageFile!);

            if (imageUrl != null) {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final email = FirebaseAuth.instance.currentUser!.email ?? "";

              UserModel updatedUser = UserModel(
                fullName.text,
                imageUrl,
                email,
                uid,
              );

              await FirebaseFirestore.instance
                  .collection("Users")
                  .doc(updatedUser.uid)
                  .set(updatedUser.toMap());
              Navigator.popUntil(context, (route)=>route.isFirst);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Homenext(
                    userModel: updatedUser,
                    firebaseUser: widget.firebaseUser,
                  ),
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile updated successfully!")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Image upload failed!")),
              );
            }
          }, "Submit"),
        ],
      ),
    );
  }
}
