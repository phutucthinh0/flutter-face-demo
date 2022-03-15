import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class LocalDatabase {
  late SharedPreferences prefs;

  void initialize() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> setListUser(List<User> users) async {
    List<dynamic> _list = [];
    users.forEach((element) {
      _list.add(element.toMap());
    });
    await prefs.setString('list_user', jsonEncode(_list));
  }

  List<User> getListUser() {
    List<User> users = [];
    String? parseData = prefs.getString('list_user');
    if (parseData == null) return [];
    List<dynamic> _list = jsonDecode(parseData);
    _list.forEach((element) {
      users.add(User(user: element['user'], modelData: jsonDecode(element['model_data'])));
    });
    return users;
  }
  LocalDatabase();
}
LocalDatabase localDatabase = LocalDatabase();
