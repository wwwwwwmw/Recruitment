import 'dart:convert';
import 'package:http/http.dart' as http;

// Update this if your backend base URL differs
const String apiBaseUrl = 'http://localhost:4000/api';

String? _authToken;
void setAuthToken(String? token){ _authToken = token; }

Future<List<dynamic>> apiGetList(String path) async {
  final res = await http.get(Uri.parse('$apiBaseUrl$path'), headers: {
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  });
  if (res.statusCode >= 200 && res.statusCode < 300) {
    final body = jsonDecode(res.body);
    if (body is List) return body;
    if (body is Map && body['data'] is List) return body['data'];
    return [body];
  }
  throw Exception('GET $path failed: ${res.statusCode}');
}

Future<Map<String, dynamic>> apiPost(String path, Map<String, dynamic> body) async {
  final res = await http.post(Uri.parse('$apiBaseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode(body));
  if (res.statusCode >= 200 && res.statusCode < 300) {
    final b = jsonDecode(res.body);
    if (b is Map<String, dynamic>) return b;
    return {'result': b};
  }
  throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
}
