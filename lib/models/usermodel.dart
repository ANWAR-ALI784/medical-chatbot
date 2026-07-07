class UserModel {
  String? uid;
  String? fullName;
  String? profile;
  String? email;

  UserModel(this.fullName, this.profile, this.email, this.uid);

  // map to object
  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map['uid'];
    fullName = map['fullName'];
    profile = map['profile'];
    email = map['email'];
  }
  // to map
  Map<String, dynamic> toMap() {
    return {
      'uid': this.uid,
      'fullName': this.fullName,
      'profile': this.profile,
      'email': this.email,
    };
  }

  // copywith method
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? profile,
  }) {
    return UserModel(
      fullName ?? this.fullName,
      profile ?? this.profile,
      email ?? this.email,
      uid ?? this.uid,
    );
  }
}
