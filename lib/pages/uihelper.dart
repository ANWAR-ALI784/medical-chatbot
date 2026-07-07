import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../models/usermodel.dart';
class UiHelper {
  static CustomTesxtField(
    TextEditingController controller,
    String text,
    IconData iconData,
    bool toHide,
  ) {
    return TextField(
      controller: controller,
      obscureText: toHide,
      decoration: InputDecoration(

        hintText: text,
        suffixIcon: Icon(iconData),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  static CustomButton(VoidCallback voidCallback, String text) {
    return SizedBox(
      height: 40,
      width: 250,
      child: ElevatedButton(
        onPressed: () {
          voidCallback();
        },
        style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.teal)),
        child: Text(text, style: TextStyle(color: Colors.white)),
      ),
    );
  }
  static CustomAlertBox(BuildContext context,String text){
return showDialog(context: context, builder: (BuildContext context){
  return AlertDialog(
    title: Text(text),

    actions: [
     TextButton(onPressed: (){
       Navigator.pop(context);
     }, child: Text("Ok")),

    ],
  );
});
  }
}
// class FirebaseHelper{
//   static Future<UserModel?>getUserModelById(String uid)async{
//     UserModel? userModel;
//    DocumentSnapshot docSnap= await  FirebaseFirestore.instance.collection("Users").doc(uid).get();
//    if(docSnap.data()!=null){
//      userModel=UserModel.fromMap(docSnap.data() as Map<String,dynamic>);
//    }
//    return userModel;
//
//   }
// }

class ShowDialog {
  static void showLoadingDialog(BuildContext context, String title) {
    AlertDialog loadingDialog = AlertDialog(
      shape:RoundedRectangleBorder(
        borderRadius: BorderRadius.only()
      ),
      content: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 👈 prevents overflow
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 30), // 👈 spacing
            Text(title),
          ],
        ),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false, // 👈 prevent closing by tapping outside
      builder: (context) {
        return loadingDialog;
      },
    );
  }
}


