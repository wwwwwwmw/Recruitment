import 'dart:convert';
import 'package:http/http.dart' as http;
import 'web_host_io.dart' if (dart.library.html) 'web_host_web.dart' as wh;
import 'api_override.dart';

// Backend base URL. Auto-detects host on web (so phone can hit PC IP),
// falls back to localhost for desktop, and supports override at runtime.
String apiBaseUrl = (() {
  // 0) explicit override for non-web or when you want a fixed URL
  final ov = apiOverrideBaseUrl();
  if (ov != null && ov.isNotEmpty) return ov;
  // 1) Web: use current host with port 4000, allow ?api= override or localStorage
  final webOverride = wh.tryGetStoredApiBaseUrl();
  if (webOverride != null && webOverride.isNotEmpty) return webOverride;
  final host = wh.currentHost();
  final scheme = wh.currentScheme() ?? 'http';
  final apiPort = wh.defaultApiPort() ?? '4000';
  if (host.isNotEmpty) return '$scheme://$host:$apiPort/api';
  // 2) Non-web fallbacks
  return 'http://localhost:4000/api';
})();

String? _authToken;
void setAuthToken(String? token){ _authToken = token; }

// Optional: allow overriding base URL at runtime (e.g., from a settings screen)
void setApiBaseUrl(String base){ apiBaseUrl = base; wh.persistApiBaseUrlIfWeb(base); }

Uri _buildUri(String path, [Map<String, dynamic>? params]){
  final uri = Uri.parse('$apiBaseUrl$path');
  if (params == null || params.isEmpty) return uri;
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    ...params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
  });
}

Future<List<dynamic>> apiGetList(String path, {Map<String, dynamic>? params}) async {
  final res = await http.get(_buildUri(path, params), headers: {
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

Future<Map<String, dynamic>> apiGet(String path, {Map<String, dynamic>? params}) async {
  final res = await http.get(_buildUri(path, params), headers: {
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  });
  if (res.statusCode >= 200 && res.statusCode < 300) {
    final body = jsonDecode(res.body);
  if (body is Map<String, dynamic>) return body;
  if (body is List && body.isNotEmpty && body.first is Map) return Map<String, dynamic>.from(body.first as Map);
    return {'result': body};
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

Future<Map<String, dynamic>> apiPut(String path, Map<String, dynamic> body) async {
  final res = await http.put(Uri.parse('$apiBaseUrl$path'),
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
  throw Exception('PUT $path failed: ${res.statusCode} ${res.body}');
}

Future<Map<String, dynamic>> apiPatch(String path, Map<String, dynamic> body) async {
  final res = await http.patch(Uri.parse('$apiBaseUrl$path'),
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
  throw Exception('PATCH $path failed: ${res.statusCode} ${res.body}');
}

Future<bool> apiDelete(String path) async {
  final res = await http.delete(Uri.parse('$apiBaseUrl$path'), headers: {
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  });
  if (res.statusCode >= 200 && res.statusCode < 300) return true;
  throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
}
