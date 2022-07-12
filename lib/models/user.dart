import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? userName;
  String? userEmail;
  String? imageUrl;
  String? uid;
  String? joiningDate;
  String? timestamp;

  User({
    this.userName,
    this.userEmail,
    this.imageUrl,
    this.uid,
    this.joiningDate,
    this.timestamp
  });


  factory User.fromFirestore(DocumentSnapshot snapshot){
    Map d = snapshot.data() as Map<dynamic, dynamic>;
    return User(

      userName: d['name'] ?? '',  //live mode
      //userName: 'User Name',   //testing mode

      userEmail: d['email'] ?? '',   //live mode
      //userEmail: '******@mail.com',    //testing mode

      imageUrl: d['image url'] ?? 'https://www.seekpng.com/png/detail/115-1150053_avatar-png-transparent-png-royalty-free-default-user.png',   //live mode
      //imageUrl: 'https://www.seekpng.com/png/detail/115-1150053_avatar-png-transparent-png-royalty-free-default-user.png',   //testing mode
      
      uid: d['uid'] ?? '',  //live mode
      //uid: '${d['uid'].toString().substring(0, 15)}**************',  //testing mode

      joiningDate: d['joining date'] ?? '',
      timestamp: d['timestamp']

    );
  }
}