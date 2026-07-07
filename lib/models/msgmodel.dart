import 'package:cloud_firestore/cloud_firestore.dart';

class MsgModel {
  String? messageId;
  String? sender;
  String? text;
  bool? seen;
  DateTime? createdAt;


  MsgModel({this.messageId ,this.sender, this.text, this.seen, this.createdAt});

  MsgModel.fromMap(Map<String, dynamic> map) {
    messageId=map['messageId'];
    sender = map['sender'];
    text = map['text'];
    seen = map['seen'];
    createdAt = map['createdAt'].toDate();
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId':this.messageId,
      'sender': this.sender,
    'text':this.text,
    'seen' : this.seen,
      'createdAt': this.createdAt != null ? Timestamp.fromDate(this.createdAt!) : FieldValue.serverTimestamp(),

    };

  }
}
