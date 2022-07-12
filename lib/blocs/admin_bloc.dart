
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:news_admin/utils/toast.dart';

class AdminBloc extends ChangeNotifier {
  
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool? _isSignedIn;
  bool _isAdmin = false;

  List _categories = [];
  List get categories => _categories;

  
  bool? get isSignedIn => _isSignedIn;
  bool get isAdmin => _isAdmin;


  bool? _bannerAd = false;
  bool? get bannerAd => _bannerAd;

  bool? _interstitialAd = false;
  bool? get interstitialAd => _interstitialAd;
  


  Future getAdsData () async {
    await firestore.collection('admin').doc('ads').get()
    .then((value)async{
      if(value.exists){
        _bannerAd = value['banner_ad'];
        _interstitialAd = value['interstitial_ad'];
      }else{
        await firestore.collection('admin').doc('ads')
        .set({
          'banner_ad' : false,
          'interstitial_ad' : false,

        });
      }
    });
    debugPrint('banner : $_bannerAd, interstitial : $interstitialAd');
    notifyListeners();
  }



  Future controlBannerAd (bool value, context) async {
    await firestore.collection('admin').doc('ads')
    .update({
      'banner_ad' : value
    }).then((_){
      _bannerAd = value;
      if(value == true){
        openToast(context, "Banner Ads enabled successfully");
      }else{
        openToast(context, "Banner Ads disabled successfully");
      }
    notifyListeners();
    });
    
  }


  Future controlInterstitialAd (bool value, context) async {
    await firestore.collection('admin').doc('ads')
    .update({
      'interstitial_ad' : value
    }).then((_){
      _interstitialAd = value;
      if(value == true){
        openToast(context, "Interstitial Ads enabled successfully");
      }else{
        openToast(context, "Interstitial Ads disabled successfully");
      }
    notifyListeners();
    });
    
  }




  Future<int> getTotalDocuments (String documentName) async {
    final String fieldName = 'count';
    final DocumentReference ref = firestore.collection('item_count').doc(documentName);
      DocumentSnapshot snap = await ref.get();
      if(snap.exists == true){
        int itemCount = snap[fieldName] ?? 0;
        return itemCount;
      }
      else{
        await ref.set({
          fieldName : 0
        });
        return 0;
      }
  }


  Future increaseCount (String documentName) async {
    await getTotalDocuments(documentName)
    .then((int documentCount)async {
      await firestore.collection('item_count')
      .doc(documentName)
      .update({
        'count' : documentCount + 1
      });
    });
  }



  Future decreaseCount (String documentName) async {
    await getTotalDocuments(documentName)
    .then((int documentCount)async {
      await firestore.collection('item_count')
      .doc(documentName)
      .update({
        'count' : documentCount - 1
      });
    });
  }

  



  Future getCategories ()async{

    await firestore.collection('categories').limit(1).get().then((value)async{
      if(value.size != 0){
        QuerySnapshot snap = await firestore.collection('categories').get();
        List d = snap.docs;
        _categories.clear();
        d.forEach((element) {
        _categories.add(element['name']);
      }
      
      );

    }else{
      _categories.clear();
    }

    notifyListeners();

    });
    
  }



  


  Future<List> getFeaturedList ()async{
    final DocumentReference ref = firestore.collection('featured').doc('featured_list');
      DocumentSnapshot snap = await ref.get();
      if(snap.exists == true){
        List featuredList = snap['contents'] ?? [];
        if(featuredList.isNotEmpty){
          List<int> a = featuredList.map((e) => int.parse(e)).toList()..sort();
          List<String> b = a.take(10).toList().map((e) => e.toString()).toList();
          return b;
        }else{
          return featuredList;
        }
      }
      else{
        await ref.set({
          'contents' : []
        });
        return [];
      }
  }

  


  Future addToFeaturedList (context, String? timestamp) async {
    final DocumentReference ref = firestore.collection('featured').doc('featured_list');
    await getFeaturedList().then((featuredList)async{

      if (featuredList.contains(timestamp)) {
        openToast(context, "This item is already available in the featured list");
      } else {

        featuredList.add(timestamp);
        await ref.update({'contents': FieldValue.arrayUnion(featuredList)});
        openToast(context, 'Added Successfully');
      }
    });
  }

  Future removefromFeaturedList (context, String? timestamp) async {
    final DocumentReference ref = firestore.collection('featured').doc('featured_list');
    await getFeaturedList().then((featuredList)async{

      if (featuredList.contains(timestamp)) {
        await ref.update({'contents' : FieldValue.arrayRemove([timestamp])});
        openToast(context, 'Removed Successfully');
      }
    });
  }



  Future deleteContent(String? timestamp, String collectionName) async {
    await firestore.collection(collectionName).doc(timestamp).delete();
    notifyListeners();
  }


  Future setSignIn() async {
    _isAdmin = true;
    _isSignedIn = true;
    notifyListeners();
  }
  

}
