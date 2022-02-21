import 'dart:convert';

class User {
  String user;
  List modelData;

  User({
    required this.user,
    required this.modelData,
  });

  factory User.fromMap(Map<String, dynamic> user) {
    return User(
      user: user['user'],
      modelData: jsonDecode(user['model_data']),
    );
  }
  toMap() {
    return {
      'user': user,
      'model_data': jsonEncode(modelData),
    };
  }
}