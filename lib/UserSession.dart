import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? userId;
  String? companyName;
  String? phone;
  int? companyId;

  factory UserSession() => _instance;

  UserSession._internal();

  Future<void> clear() async {
    userId = null;
    companyName = null;
    phone = null;
    companyId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    companyName = prefs.getString('companyName');
    phone = prefs.getString('phone');
    companyId = prefs.getInt('companyId');
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId ?? '');
    await prefs.setString('companyName', companyName ?? '');
    await prefs.setString('phone', phone ?? '');
    await prefs.setInt('companyId', companyId ?? 0);
  }

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;
}
