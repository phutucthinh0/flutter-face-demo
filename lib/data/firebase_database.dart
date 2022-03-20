import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_face_demo/data/local_database.dart';

import '../models/user.dart';

class FBRealtime {
  static DatabaseReference ref = FirebaseDatabase.instance.ref("users");
  static List<User> users = [];
  static void saveInput(String data){
    ref.update({'data':data});
  }
  static void initialize(){
    ref.onValue.listen((event) {
      if(event.snapshot.hasChild('list')){
        List<dynamic> _list = [];
        users = [];
        _list = event.snapshot.child('list').value as List;
        _list.forEach((element) {
          users.add(User(
            user: element['user'],
            modelData:  jsonDecode(element['model_data'])
          ));
        });
        if(users!=localDatabase.getListUser()){
          localDatabase.setListUser(users);
        }
      }
    });
  }
  static readAllUsers () async {
    users = localDatabase.getListUser();
  }
  static Future<void> addUsers (List<User> user) async {
    List<dynamic> _list = [];
    users.forEach((element) {
      _list.add(element.toMap());
    });
    user.forEach((element) {_list.add(element.toMap());});
    ref.update({"list":_list});
  }
}