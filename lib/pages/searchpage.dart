import 'package:animationpractice/main.dart';
import 'package:animationpractice/models/chatroommodel.dart';
import 'package:animationpractice/models/usermodel.dart';
import 'package:animationpractice/pages/chatroompage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Searchpage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const Searchpage({
    super.key,
    required this.userModel,
    required this.firebaseUser,
  });

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  TextEditingController searchController = TextEditingController();
  Future<ChatRoomModel?> getChatRoomModel(UserModel targetUser) async {
    ChatRoomModel chatRoom;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatroom")
        .where("participant.${widget.userModel.uid}", isEqualTo: true)
        .where("participant.${targetUser.uid}", isEqualTo: true)
        .get();
    if (snapshot.docs.length > 0) {
      // fetch existing one
      var docData = snapshot.docs[0].data();
      ChatRoomModel exsitingChatroom = ChatRoomModel.fromMap(
        docData as Map<String, dynamic>,
      );
      print("already exist");
      chatRoom = exsitingChatroom;
    } else {
      //new chatroom create model
      ChatRoomModel newchatRoomModel = ChatRoomModel(
        chatroomId: uuid.v1(), // unique id generate
        lastMessage: '',
        participant: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );
      await FirebaseFirestore.instance
          .collection("chatroom")
          .doc(newchatRoomModel.chatroomId)
          .set(newchatRoomModel.toMap());
      chatRoom =newchatRoomModel;
      print("new chatroom created");
    }
   return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(labelText: "Email Address"),
                ),
                SizedBox(height: 20),
                CupertinoButton(
                  child: Text("Search", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {});
                  },
                  color: Colors.blue,
                  sizeStyle: CupertinoButtonSize.large,
                ),
                SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder(
                    // search email
                    stream: FirebaseFirestore.instance
                        .collection("Users")
                        .where(
                          "email",
                          isEqualTo: searchController.text.toString(),
                        )
                        .where("email", isNotEqualTo: widget.userModel.email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          QuerySnapshot datasnapshot =
                              snapshot.data as QuerySnapshot;

                          if (datasnapshot.docs.isNotEmpty) {
                            Map<String, dynamic> userMap =
                                datasnapshot.docs[0].data()
                                    as Map<String, dynamic>;
                            UserModel searchedUser = UserModel.fromMap(userMap);

                            return ListTile(
                              onTap: () async{
                                ChatRoomModel? chatroommodel=await
                                getChatRoomModel(searchedUser);
                                if(chatroommodel!=null){

                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Chatroompage(
                                      targetUser: searchedUser,
                                      userModel: widget.userModel,
                                      firebaseUser: widget.firebaseUser,
                                      chatroom:chatroommodel ,
                                    )));
                                }

                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade500,
                                backgroundImage: NetworkImage(
                                  searchedUser.profile!,
                                ),
                              ),
                              title: Text(searchedUser.fullName ?? "No Name"),
                              subtitle: Text(searchedUser.email ?? "No Email"),
                              trailing: Icon(
                                Icons.keyboard_arrow_right_outlined,
                              ),
                            );
                          } else {
                            return Center(child: Text("No results found"));
                          }
                        } else if (snapshot.hasError) {
                          return Center(child: Text("An error occurred"));
                        } else {
                          return Center(child: Text("No results"));
                        }
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
