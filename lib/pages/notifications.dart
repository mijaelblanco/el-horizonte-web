import 'package:news_admin/blocs/admin_bloc.dart';
import 'package:news_admin/blocs/notification_bloc.dart';
import 'package:news_admin/utils/dialog.dart';
import 'package:news_admin/utils/notification_preview.dart';
import 'package:news_admin/utils/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Send A Notification to All Users',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 5, bottom: 10),
          height: 3,
          width: 200,
          decoration: BoxDecoration(
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15)),
        ),

        SizedBox(
          height: 50,
        ),

        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: inputDecoration(
                    'Enter Notification Title', 'Title', titleCtrl),
                controller: titleCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'Title is empty';
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(
                    hintText: 'Enter Description (supports HTML text)',
                    border: OutlineInputBorder(),
                    labelText: 'Description',
                    contentPadding:
                        EdgeInsets.only(right: 0, left: 10, top: 15, bottom: 5),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey[300],
                        child: IconButton(
                            icon: Icon(Icons.close, size: 15),
                            onPressed: () {
                              descriptionCtrl.clear();
                            }),
                      ),
                    )),
                textAlignVertical: TextAlignVertical.top,
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                controller: descriptionCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'Description is empty';
                  return null;
                },
              ),
              SizedBox(
                height: 50,
              ),
              Center(
                  child: Row(
                children: <Widget>[
                  TextButton(
                    style: buttonStyle(Colors.purpleAccent),
                    child: _isLoading == true
                    ? CircularProgressIndicator()
                    
                    : Text(
                      'Send Now',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      await handleSendNotification();
                      clearTextfields();
                    },
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    style: buttonStyle(Colors.pinkAccent),
                    child: Text(
                      'Preview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      handleOpenPreview();
                    },
                  ),
                ],
              )),
              SizedBox(
                height: 200,
              )
            ],
          ),
        )
      ],
    ));
  }

  var formKey = GlobalKey<FormState>();
  var titleCtrl = TextEditingController();
  var descriptionCtrl = TextEditingController();
  String? timestamp;
  String? date;
  bool _isLoading = false;

  handleSendNotification() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.isAdmin == false) {
        openDialog(context, 'You are a Tester', 'Only admin can send notifications');
      } else {
        setState ((() => _isLoading = true));
        await context.read<NotificationBloc>().sendCustomNotification(titleCtrl.text)
          .then((value) => context.read<AdminBloc>().increaseCount('notifications_count'))
          .then((value) => openDialog(context, 'Sent Successfully', 'The notification has been sent successfully to all of the users of the app'));
        setState ((() => _isLoading = false));
        
      }
    }
  }

  clearTextfields() {
    titleCtrl.clear();
    descriptionCtrl.clear();
  }

  handleOpenPreview() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      showNotificationPreview(context, titleCtrl.text, descriptionCtrl.text);
    }
  }

  Future getTimestamp() async {
    DateTime now = DateTime.now();
    String _timestamp = DateFormat('yyyyMMddHHmmss').format(now);
    String _date = DateFormat('dd-MM-yyyy').format(now);
    setState(() {
      timestamp = _timestamp;
      date = _date;
    });
  }
}
