class ChatRoomModel {
  String? chatroomId;
  Map<String,dynamic>? participant;
  String? lastMessage;


  ChatRoomModel({this.chatroomId, this.participant,this.lastMessage});

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomId = map['chatroomId'];
    participant = map['participant'];
    lastMessage=map['lastMessage'];
  }

  Map<String ,dynamic>toMap(){
    return {
      'chatroomId':this.chatroomId,
      'participant':this.participant,
      'lastMessage':this.lastMessage

    };
  }
}
