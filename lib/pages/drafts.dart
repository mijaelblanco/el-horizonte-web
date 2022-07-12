import 'package:line_icons/line_icons.dart';
import 'package:news_admin/models/article.dart';
import 'package:news_admin/pages/update_draft.dart';
import 'package:news_admin/utils/empty.dart';
import 'package:news_admin/utils/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../blocs/admin_bloc.dart';
import '../utils/cached_image.dart';
import '../utils/dialog.dart';
import '../utils/next_screen.dart';
import '../utils/styles.dart';
import '../widgets/article_preview.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({Key? key}) : super(key: key);

  @override
  _DraftPageState createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {


  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<DocumentSnapshot> _snap = [];
  List<Article> _data = [];
  String collectionName = 'drafts';
  bool? _hasData;

  

  @override
  void initState() {
    controller = new ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _getData();
  }

  Future<Null> _getData() async {
    QuerySnapshot? data;
    if (_lastVisible == null)
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
    else
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .startAfter([_lastVisible!['timestamp']])
          .limit(10)
          .get();

    if (data.docs.length > 0) {
      _lastVisible = data.docs[data.docs.length - 1];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = true;
          _snap.addAll(data!.docs);
          _data = _snap.map((e) => Article.fromFirestore(e)).toList();
        });
      }
    } else {
      if(_lastVisible == null){
        setState(() {
          _isLoading = false;
          _hasData = false; 
        }); 
      }else{
        setState(() {
          _isLoading = false; 
          _hasData = true; 
        });
      openToast(context, 'No more content available'); }
    }
    return null;
  }



  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoading) {
      if (controller!.position.pixels == controller!.position.maxScrollExtent) {
        setState(() => _isLoading = true);
        _getData();
      }
    }
  }


  reloadData (){
    setState(() {
      _isLoading = true;
      _lastVisible = null;
      _snap.clear();
      _data.clear();
    });
    _getData();
  }


  handlePreview(Article d) async {
    await showArticlePreview(
      context, 
      d.title, 
      d.description, 
      d.thumbnailImagelUrl, 
      d.loves, 
      d.sourceUrl ?? '', 
      d.date ?? '', 
      d.category, 
      d.contentType,
      d.youtubeVideoUrl ?? ''
      );
  }


  void _handleDeletefromDraft(timestamp) async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(50),
            elevation: 0,
            children: <Widget>[
              Text('Delete?',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              SizedBox(
                height: 10,
              ),
              Text('Want to delete this item from the draft?',
                  style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                height: 30,
              ),
              Center(
                  child: Row(
                children: <Widget>[
                  TextButton(
                    style: buttonStyle(Colors.redAccent),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      if (ab.isAdmin == false) {
                        Navigator.pop(context);
                        openDialog(context, 'You are a Tester','Only admin can delete contents');
                      } else {
                        await ab.deleteContent(timestamp, 'drafts')
                        .then((value) => ab.decreaseCount('drafts_count'))
                        .then((value) => openToast(context, 'Item deleted successfully!'));
                        reloadData();
                        Navigator.pop(context);
                      }
                      
                    },
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    style: buttonStyle(Colors.deepPurpleAccent),
                    child: Text(
                      'No',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ))
            ],
          );
        });
  }

  

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Drafts',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 5, bottom: 10),
          height: 3,
          width: 50,
          decoration: BoxDecoration(
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15)),
        ),
        Expanded(
          child: _hasData == false ? emptyPage(Icons.content_paste, 'No drafts available!')
          
          : RefreshIndicator(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 30, bottom: 20),
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: _data.length + 1,
              itemBuilder: (_, int index) {
                if (index < _data.length) {
                  return dataList(_data[index]);
                }
                return Center(
                  child: new Opacity(
                    opacity: _isLoading ? 1.0 : 0.0,
                    child: new SizedBox(
                        width: 32.0,
                        height: 32.0,
                        child: new CircularProgressIndicator()),
                  ),
                );
              },
            ),
            onRefresh: () async {
              reloadData();
            },
          ),
        ),
      ],
    );
  }


  Widget dataList(Article d) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(top: 5, bottom: 5),
      height: 140,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                ),
                  child: CustomCacheImage(imageUrl: d.thumbnailImagelUrl, radius: 10,),
              ),

              d.contentType == 'image' ? Container()
              : Align(
                alignment: Alignment.center,
                child: Icon(LineIcons.playCircle, size: 70, color: Colors.white,),
              )
            ],
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 0,
                left: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    d.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                        padding: EdgeInsets.fromLTRB(8, 3, 8, 3),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(d.category!, style: TextStyle(
                          color: Colors.white,
                          fontSize: 12
                        ),),
                      ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: <Widget>[
                      
                      InkWell(
                          child: Container(
                              height: 35,
                              width: 45,
                              padding: EdgeInsets.only(left: 8, right: 8),
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.remove_red_eye,
                                  size: 16, color: Colors.grey[800])),
                          onTap: () {
                            handlePreview(d);
                          }),
                      SizedBox(width: 10),
                      InkWell(
                        child: Container(
                            height: 35,
                            width: 45,
                            padding: EdgeInsets.only(left: 8, right: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.edit,
                                size: 16, color: Colors.grey[800])),
                        onTap: () {
                          nextScreen(context, UpdateDraft(data: d));
                        },
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 35,
                        padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(30)),
                        child: TextButton.icon(
                            onPressed: () => _handleDeletefromDraft(d.timestamp),
                            icon: Icon(Icons.delete, size: 18,),
                            label: Text('Delete from Draft')),
                      ),
                      

                      
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}