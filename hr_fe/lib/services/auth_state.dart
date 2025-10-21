import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class AuthState extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user; // {id,email,role,name}

  bool get isLoggedIn => token != null;
  String get role => user?['role'] ?? 'guest';

  Future<void> login(String email, String password) async {
    final res = await http.post(Uri.parse('http://localhost:4000/api/auth/login'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (res.statusCode!=200) { throw Exception('Login failed'); }
    final body = jsonDecode(res.body);
    token = body['token'];
    user = body['user'];
    setAuthToken(token);
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    final res = await http.post(Uri.parse('http://localhost:4000/api/auth/register'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'full_name': name, 'email': email, 'password': password}));
    if (res.statusCode!=201) { throw Exception('Signup failed'); }
    final body = jsonDecode(res.body);
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
