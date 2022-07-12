import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService{

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final userStream = FirebaseAuth.instance.authStateChanges();
  final user = FirebaseAuth.instance.currentUser;


  Future<UserCredential?> loginWithEmailPassword (String username, String password) async {
    UserCredential? userCredential;
    await _firebaseAuth.signInWithEmailAndPassword(
      email: username, 
      password: password
    ).then((UserCredential user)async{
      userCredential = user;
      
      

    }).catchError((e){
      debugPrint('SignIn Error: $e');
    });

    return userCredential;

  }

  Future loginAnnonumously () async {
    await Future.delayed(Duration(seconds: 1));
  }

  Future adminLogout () async {
    return _firebaseAuth.signOut().then((value){
      debugPrint('Logout Success');
    }).catchError((e){
      debugPrint('Logout error: $e');
    });
  }


  Future<bool?> checkAdminAccount (String uid) async{
    bool? isAdmin;
    await _firebaseFirestore.collection('users').doc(uid).get().then((DocumentSnapshot snap){
      if(snap.exists){
        List? userRole = snap['role'];
        debugPrint('User Role: ${userRole}');
        if(userRole != null && userRole.contains('admin')){
          isAdmin = true;
        }else{
          isAdmin = false;
        }
      }else{
        isAdmin = false;
      }
    }).catchError((e){
      isAdmin = false;
      debugPrint('check admin error: $e');
    });
    return isAdmin;
  }


  Future<bool?> changeAdminPassword (String oldPassword, String newPassword) async{
    bool? success;
    final user = await _firebaseAuth.currentUser;
    final cred = EmailAuthProvider.credential(email: user!.email!, password: oldPassword);
    await user.reauthenticateWithCredential(cred).then((UserCredential? userCredential) async{
      if(userCredential != null){
        await user.updatePassword(newPassword).then((_) {
        success = true;
        }).catchError((error) {
        debugPrint(error);
        success = false;
        });
      }else{
        success = false;
        debugPrint('Reauthentication failed');
      }
      
    }).catchError((err) {
      debugPrint('errro: $err');
      success = false;
    });

    return success;
  }
  
  

}