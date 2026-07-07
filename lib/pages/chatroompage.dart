import 'dart:developer';

import 'package:animationpractice/models/chatroommodel.dart';
import 'package:animationpractice/models/msgmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/usermodel.dart';

class Chatroompage extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

  const Chatroompage({
    super.key,
    required this.targetUser,
    required this.chatroom,
    required this.userModel,
    required this.firebaseUser,
  });

  @override
  State<Chatroompage> createState() => _ChatroompageState();
}

class _ChatroompageState extends State<Chatroompage> {
  TextEditingController messagecontroller = TextEditingController();

  void sendMessage() async {
    String msg = messagecontroller.text.trim();
    messagecontroller.clear();
    if (msg != "") {
      // send msg
      MsgModel newmsg = MsgModel(
        messageId: uuid.v1(),
        sender: widget.userModel.uid,
        createdAt: DateTime.now(),
        text: msg,
        seen: false,
      );
      FirebaseFirestore.instance
          .collection("chatroom")
          .doc(widget.chatroom.chatroomId)
          .collection("messages")
          .doc(newmsg.messageId)
          .set(newmsg.toMap());
      widget.chatroom.lastMessage=msg;
      FirebaseFirestore.instance.collection("chatroom").doc(widget.
      chatroom.chatroomId).set(widget.chatroom.toMap());
      log("msg send");
    } else {
      //nothing do
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(
                widget.targetUser.profile.toString(),
              ),
            ),
            SizedBox(width: 10),
            Text(
              widget.targetUser.fullName.toString(),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  // chat goes
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("chatroom")
                        .doc(
                          widget.chatroom.chatroomId,
                        ) //here order used for latest msg show first in below
                        .collection("messages")
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          QuerySnapshot dataSnapshot =
                              snapshot.data as QuerySnapshot;
                          return ListView.builder(
                            reverse: true,
                            itemCount: dataSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              MsgModel currentMsg = MsgModel.fromMap(
                                dataSnapshot.docs[index].data()
                                    as Map<String, dynamic>,
                              );
                              return Row(// our msg is show right side and the sender on left side
                                mainAxisAlignment: (currentMsg.sender==widget.userModel.uid)?
                                MainAxisAlignment.end: MainAxisAlignment.start,

                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                    margin:EdgeInsets.symmetric(vertical: 2) ,
                                    decoration: BoxDecoration(
                                      color: (currentMsg.sender==widget.userModel.uid)?Colors.grey:Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Text(
                                      currentMsg.text.toString(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "An error occured! Please check your internet connection",
                            ),
                          );
                        } else {
                          return Center(
                            child: Text("Say hi to yuor new friend"),
                          );
                        }
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Flexible(
                      child: TextField(
                        maxLines: null,
                        controller: messagecontroller,
                        decoration: InputDecoration(
                          hintText: 'Enter Message',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // function
                        sendMessage();
                      },
                      icon: Icon(Icons.send, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
