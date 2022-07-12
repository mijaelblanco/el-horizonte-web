import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_admin/blocs/admin_bloc.dart';
import 'package:news_admin/services/app_service.dart';
import 'package:news_admin/utils/dialog.dart';
import 'package:news_admin/utils/styles.dart';
import 'package:news_admin/widgets/article_preview.dart';
import 'package:provider/provider.dart';
import '../blocs/admin_bloc.dart';
import '../blocs/notification_bloc.dart';
import '../config/config.dart';
import '../utils/dialog.dart';

class UploadContent extends StatefulWidget {
  UploadContent({Key? key}) : super(key: key);

  @override
  _UploadContentState createState() => _UploadContentState();
}

class _UploadContentState extends State<UploadContent> {

  
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var formKey = GlobalKey<FormState>();
  var titleCtrl = TextEditingController();
  var imageUrlCtrl = TextEditingController();
  var sourceCtrl = TextEditingController();
  var descriptionCtrl = TextEditingController();
  var youtubeVideoUrlCtrl = TextEditingController();
  var scaffoldKey = GlobalKey<ScaffoldState>();


  bool? notifyUsers = true;
  bool uploadStarted = false;
  bool? uploadStartedonDrafts = false;
  String? _timestamp;
  String? _date;
  var _articleData;

  var categorySelection;
  var contentTypeSelection;

  Image? imageFile;
  bool _isPublished = false;

  




  void handleSubmit() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if(categorySelection == null){
      openDialog(context, 'Select a category first', '');
    }else if(contentTypeSelection == null){
      openDialog(context, 'Select content type', '');
    }else{
      if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.isAdmin == false) {
        openDialog(context, 'You are a Tester', 'Only Admin can upload, delete & modify contents');
      } else {
        setState(()=> uploadStarted = true);
        await _isAvailableonDrafts().then((bool? isAvailable)async {
          if(await isAvailable != null && isAvailable == true){
            await context.read<AdminBloc>().deleteContent(_timestamp, 'drafts')
            .then((value) => context.read<AdminBloc>().decreaseCount('drafts_count')); 
          }

          await getDate().then((_) async{
            await saveToDatabase()
            .then((value) => context.read<AdminBloc>().increaseCount('contents_count'))
            .then((value) => handleSendNotification());
            setState((){
              uploadStarted = false;
              _isPublished = true;
            });
            openDialog(context, 'Uploaded Successfully', '');
            clearTextFeilds();});
        });
      }
    }
    }
  }




  Future handleSendNotification ()async{
    if(notifyUsers == true){
      await context.read<NotificationBloc>().sendPostNotification(titleCtrl.text, _timestamp!, imageUrlCtrl.text, contentTypeSelection)
      .then((value) => context.read<AdminBloc>().increaseCount('notifications_count'));
    }
  }


  void handleUploadToDrafts() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if(categorySelection == null){
      openDialog(context, 'Select a category first', '');
    }else if(contentTypeSelection == null){
      openDialog(context, 'Select content type', '');
    }else{
      if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.isAdmin == false) {
        openDialog(context, 'You are a Tester', 'Only Admin can upload, delete & modify contents');
      } else {
        setState(()=> uploadStartedonDrafts = true);
        if(_timestamp != null){
          await updateToDrafts(_timestamp!).then((value){
          setState(()=> uploadStartedonDrafts = false);
          openDialog(context, 'Saved successfully on Drafts', '');
        });

        }else{
          await getDate().then((value) async => await updateToDrafts(_timestamp!)
          .then((value) => context.read<AdminBloc>().increaseCount('drafts_count'))
          .then((value){
            setState(()=> uploadStartedonDrafts = false);
            openDialog(context, 'Saved successfully on Drafts', '');
          }));
        }
      }
    }
    }
  }







  Future getDate() async {
    DateTime now = DateTime.now();
    String _d = DateFormat('dd MMMM yy').format(now);
    String _t = DateFormat('yyyyMMddHHmmss').format(now);
    setState(() {
      _timestamp = _t;
      _date = _d;
    });
    
  }



  Future saveToDatabase() async {
    final DocumentReference ref = firestore.collection('contents').doc(_timestamp);
    _articleData = {
      'category' : categorySelection,
      'content type' : contentTypeSelection,
      'title' : titleCtrl.text,
      'description' : descriptionCtrl.text,
      'image url' : imageUrlCtrl.text,
      'youtube url' : contentTypeSelection == 'image' ? null : youtubeVideoUrlCtrl.text,
      'loves' : 0,
      'source' : sourceCtrl.text == '' ? null : sourceCtrl.text,
      'date': _date,
      'timestamp' : _timestamp,
      'views': 0,
      
    };
    await ref.set(_articleData);
  }


  Future<bool?> _isAvailableonDrafts () async {
    bool? _isAvailable;
    final _db = FirebaseFirestore.instance;
    await _db.collection('drafts').doc(_timestamp).get().then((DocumentSnapshot snap){
      if(snap.exists){
        _isAvailable = true;
        debugPrint('doc exists');
      }
      else{
        _isAvailable = false;
        debugPrint("doc doesn't exist");
      }
    }).onError((error, stackTrace){
      _isAvailable = false;
      debugPrint(error.toString());
    });
    return _isAvailable;
  }


  Future updateToDrafts(String timestamp) async {
    final _db = FirebaseFirestore.instance;
    _articleData = {
      'category' : categorySelection,
      'content type' : contentTypeSelection,
      'title' : titleCtrl.text,
      'description' : descriptionCtrl.text,
      'image url' : imageUrlCtrl.text,
      'youtube url' : contentTypeSelection == 'image' ? null : youtubeVideoUrlCtrl.text,
      'loves' : 0,
      'source' : sourceCtrl.text == '' ? null : sourceCtrl.text,
      'date': null,
      'timestamp' : timestamp,
      'views': 0,
      
    };

    await _db.collection('drafts').doc(timestamp).set(_articleData, SetOptions(merge: true));
  }






  clearTextFeilds() {
    titleCtrl.clear();
    descriptionCtrl.clear();
    imageUrlCtrl.clear();
    youtubeVideoUrlCtrl.clear();
    sourceCtrl.clear();
    FocusScope.of(context).unfocus();
  }




  handlePreview() async{
    if(categorySelection == null){
      openDialog(context, 'Select a category first', '');
    }else if(contentTypeSelection == null){
      openDialog(context, 'Select content type', '');
    }else{
      if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      await getDate().then((_) async{
        await showArticlePreview(
          context, 
          titleCtrl.text, 
          descriptionCtrl.text, 
          imageUrlCtrl.text, 
          0, 
          sourceCtrl.text, 
          'Now',
          categorySelection,
          contentTypeSelection,
          youtubeVideoUrlCtrl.text
          
          );

        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      key: scaffoldKey,
      body: Form(
            key: formKey,
            child: ListView(
              children: <Widget>[
                SizedBox(
                  height: h * 0.10,
                ),
                Text(
                  'Article Details',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 20,),

                Row(
                  children: [
                    Expanded(child: categoriesDropdown()),
                    SizedBox(width: 20,),
                    Expanded(child: contentTypeDropdown()),

                  ],
                ),
                
                SizedBox(height: 20,),

                TextFormField(
                  decoration: inputDecoration('Enter Title', 'Title', titleCtrl),
                  controller: titleCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return 'Value is empty';
                    return null;
                  },
                  
                ),
                SizedBox(height: 20,),


                TextFormField(
                  decoration: inputDecoration('Enter Thumnail Url', 'Thumnail', imageUrlCtrl),
                  controller: imageUrlCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return 'Value is empty';
                    return null;
                  },
                  
                ),
                
                
                SizedBox(height: 20,),

                
                contentTypeSelection == null || contentTypeSelection == 'image' ? Container()
                : Column(
                  children: [
                    TextFormField(
                    decoration: inputDecoration('Enter Youtube Url', 'Youtube video Url', youtubeVideoUrlCtrl),
                    controller: youtubeVideoUrlCtrl,
                    validator: (value) {
                    if (value!.isEmpty) return 'Value is empty';
                    return null;
                  },
                ),
                
                
                SizedBox(height: 20,),
                  ],
                ),


                TextFormField(
                  decoration: inputDecoration('Enter Source Url (Optional)', 'Source Url(Optional)', sourceCtrl),
                  controller: sourceCtrl,
                ),
                
                
                SizedBox(height: 30,),
                InkWell(
                  child: Text('Content Description Helper', style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    decoration: TextDecoration.underline
                  ),),
                  onTap: ()=> AppService().openLink(context, 'https://www.mrb-lab.com/some-useful-html-code-for-content-descriptions-in-the-newshour-app'),
                ),

                SizedBox(height: 15,),


                TextFormField(
                  decoration: InputDecoration(
                      hintText: 'Enter Description (Html or Normal Text)',
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                      contentPadding: EdgeInsets.only(
                          right: 0, left: 10, top: 15, bottom: 5),
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
                  minLines: 5,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  controller: descriptionCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return 'Value is empty';
                    return null;
                  },
                  
                ),

                SizedBox(height: 100,),


                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[

                        Checkbox(
                          activeColor: Colors.blueAccent,
                          onChanged: (bool? value) {
                            setState(() {
                              notifyUsers = value;
                              debugPrint('notify users : $notifyUsers');
                            });
                          },
                          value: notifyUsers,
                        ),
                        Text('Notify All Users'),
                        Spacer(),
                        
                        TextButton.icon(
                          
                          icon: Icon(Icons.remove_red_eye, size: 25, color: Colors.blueAccent,),
                          label: Text('Preview', style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          ),),
                          onPressed: (){
                            handlePreview();
                          }
                        )
                      ],
                    ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                        color: Colors.deepPurpleAccent,
                        margin: EdgeInsets.only(right: 20),
                        width: 300,
                        height: 45,
                        child: uploadStarted == true
                          ? Center(child: Container(height: 30, width: 30,child: CircularProgressIndicator()),)
                          : TextButton(
                            child: Text(
                              'Publish Now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async{
                              handleSubmit();
                              
                            })
                          
                          ),

                          _isPublished == true
                          ? Container()

                          :Container(
                             margin: EdgeInsets.only(left: 20),
                             width: 200,
                        color: Colors.grey,
                        height: 45,
                        child: uploadStartedonDrafts == true
                          ? Center(child: Container(height: 30, width: 30,child: CircularProgressIndicator(color: Colors.white,)),)
                          : TextButton(
                            child: Text(
                              'Save on Drafts',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async{
                              handleUploadToDrafts();
                              
                            })
                          
                          ),
                  ],
                ),
                SizedBox(
                  height: 200,
                ),
              ],
            )),
      
    );
  }



  Widget categoriesDropdown() {
    final AdminBloc ab = Provider.of(context, listen: false);
    return Container(
        height: 50,
        padding: EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(30)),
        child: DropdownButtonFormField(
            itemHeight: 50,
            decoration: InputDecoration(border: InputBorder.none),
            onChanged: (dynamic value) {
              setState(() {
                categorySelection = value;
              });
            },
            onSaved: (dynamic value) {
              setState(() {
                categorySelection = value;
              });
            },
            value: categorySelection,
            hint: Text('Select Category',),
            items: ab.categories.map((f) {
              return DropdownMenuItem(
                child: Text(f),
                value: f,
              );
            }).toList()));
  }


  Widget contentTypeDropdown() {
    return Container(
        height: 50,
        padding: EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(30)),
        child: DropdownButtonFormField(
            itemHeight: 50,
            decoration: InputDecoration(border: InputBorder.none),
            onChanged: (dynamic value) {
              setState(() {
                contentTypeSelection = value;
              });
            },
            onSaved: (dynamic value) {
              setState(() {
                contentTypeSelection = value;
              });
            },
            value: contentTypeSelection,
            hint: Text('Select Content Type'),
            items: Config().contentTypes.map((f) {
              return DropdownMenuItem(
                child: Text(f),
                value: f,
              );
            }).toList()));
  }

}
