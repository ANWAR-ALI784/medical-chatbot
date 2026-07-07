import 'package:animationpractice/models/chatroommodel.dart';
import 'package:animationpractice/models/firebasehelper.dart';
import 'package:animationpractice/pages/chatroompage.dart';
import 'package:animationpractice/pages/loginauth.dart';
import 'package:animationpractice/pages/searchpage.dart';
import 'package:animationpractice/pages/uihelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/usermodel.dart';

class Homenext extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const Homenext({
    super.key,
    required this.userModel,
    required this.firebaseUser,
  });

  @override
  State<Homenext> createState() => _HomenextState();
}

class _HomenextState extends State<Homenext> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text("ChatApp", style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(onPressed: ()async{
          await FirebaseAuth.instance.signOut();
          Navigator.popUntil(context, (route)=>route.isFirst);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Loginauth()));
        }, icon: Icon(Icons.exit_to_app,color: Colors.white,)),
      ],),
      body: SafeArea(
        child: Container(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("chatroom")
                .where("participant.${widget.userModel.uid}", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  QuerySnapshot chatroomsnapshot =
                      snapshot.data as QuerySnapshot;
                  return ListView.builder(
                    itemCount: chatroomsnapshot.docs.length,
                    itemBuilder: (context, index) {
                      ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                        chatroomsnapshot.docs[index].data()
                            as Map<String, dynamic>,
                      );
                      Map<String, dynamic> participant =
                          chatRoomModel.participant!;
                      List<String> participantKeys = participant.keys.toList();
                      participantKeys.remove(widget.userModel.uid);
                      return FutureBuilder(
                        future: FirebaseHelper.getUserModelById(
                          participantKeys[0],
                        ),
                        builder: (context, userData) {
                          if (userData.connectionState ==
                              ConnectionState.done) {
                            if (userData != null) {
                              UserModel targetUser = userData.data as UserModel;
                              return ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Chatroompage(
                                        targetUser: targetUser,
                                        userModel: widget.userModel,
                                        firebaseUser: widget.firebaseUser,
                                        chatroom: chatRoomModel,
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    targetUser.profile.toString(),
                                  ),
                                ),
                                title: Text(targetUser.fullName.toString()),
                                subtitle: (chatRoomModel.lastMessage.toString() !="")?Text(
                                  chatRoomModel.lastMessage.toString(),
                                ):Text("say hi to your new friend!"),
                              );
                            } else {
                              return Container();
                            }
                          } else {
                            return Container();
                          }
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                } else {
                  Center(child: Text("no chat"));
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
              return Container();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        //ShowDialog.showLoadingDialog(context, "Loading....");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Searchpage(
                userModel: widget.userModel,
                firebaseUser: widget.firebaseUser,
              ),
            ),
          );
        },
        child: Icon(Icons.search),
      ),
    );
  }
}
