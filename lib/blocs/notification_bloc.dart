import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:news_admin/config/config.dart';
import 'package:news_admin/constants/constants.dart';
import 'package:http/http.dart' as http;

class NotificationBloc extends ChangeNotifier {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  Future sendPostNotification (String title, String postId, String imageUrl, String contentType) async{
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=${Config().serverToken}',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Click here to read more details',
            'title': title,
            'sound':'default'
          },
          'priority': 'normal',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
            'post_id': postId,
            'image_url': imageUrl,
            'notification_type': 'post',
            'content_type': contentType
          },
          'to': "/topics/${Constants.fcmSubscriptionTopic}",
        },
      ),
    );
  }

  Future sendCustomNotification (String title) async{
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=${Config().serverToken}',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Click here to read more details',
            'title': title,
            'sound':'default'
          },
          'priority': 'normal',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
            'notification_type': 'custom'
          },
          'to': "/topics/${Constants.fcmSubscriptionTopic}",
        },
      ),
    );
  }


  
}
