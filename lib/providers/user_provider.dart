import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _companyName;
  bool _isAuthenticated = false;

  String? get userId => _userId;
  String? get companyName => _companyName;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String id, String password) async {
    final success =
        await DatabaseHelper.instance.authenticateUser(id, password);
    if (success) {
      final user = await DatabaseHelper.instance.getUser(id);
      if (user != null) {
        _userId = user['id'];
        _companyName = user['company_name'];
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _userId = null;
    _companyName = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final success = await DatabaseHelper.instance.createUser(userData);
      if (success) {
        _userId = userData['id'];
        _companyName = userData['company_name'];
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error in UserProvider createUser: $e');
      return false;
    }
  }
}
