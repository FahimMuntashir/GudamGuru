class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? userId;
  String? companyName;
  String? phone;
  int? companyId;

  factory UserSession() => _instance;

  UserSession._internal();

  void clear() {
    userId = null;
    companyName = null;
    phone = null;
    companyId = null;
  }
}
