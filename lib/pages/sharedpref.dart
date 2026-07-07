import 'package:animationpractice/pages/uihelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sharedpref extends StatefulWidget {


  @override
  State<Sharedpref> createState() => _SharedprefState();

}

class _SharedprefState extends State<Sharedpref> {
  var nameController =TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getValue();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.green,
        title: Text("LogIn Page",style: TextStyle(color: Colors.white),),
        centerTitle: true,),
      body: Container(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Padding(padding: EdgeInsets.all(20),
            child: TextField(
              controller:nameController,
              decoration: InputDecoration(
                hintText: 'enter your Name',
                label: Text('Name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                )
            
              ),
            ),
          ),
            SizedBox(height: 10,),
            ElevatedButton(
                onPressed: ()async{
           var name=nameController.text.toString();
           var prefs= await SharedPreferences.getInstance();
            prefs.setString("name", nameController.text.toString());
                },
                child: Text("save")),
           SizedBox(height: 20,child: Text("Saved Value"),),
            ],),
      ),
    );
  }
  void GetValue()async {
    var prefs = await SharedPreferences.getInstance();
    var getname=prefs.getString("email");

  }
}

void getValue() {
  
}
