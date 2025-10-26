import 'package:flutter/foundation.dart';
import 'api.dart';

class AuthState extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user; // {id,email,role,name}

  bool get isLoggedIn => token != null;
  String get role => user?['role'] ?? 'guest';

  Future<void> login(String email, String password) async {
    final body = await apiPost('/auth/login', {'email': email, 'password': password});
    token = body['token'];
    user = body['user'];
    setAuthToken(token);
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    final body = await apiPost('/auth/register', {'full_name': name, 'email': email, 'password': password});
    token = body['token'];
    user = body['user'];
    setAuthToken(token);
    notifyListeners();
  }

  void logout(){
    token = null;
    user = null;
    setAuthToken(null);
    notifyListeners();
  }
}
