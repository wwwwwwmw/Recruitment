import 'dart:html' as html;

String currentHost() {
  return html.window.location.hostname ?? 'localhost';
}

String? currentScheme() {
  final p = html.window.location.protocol; // e.g., 'http:'
  return (p.isEmpty) ? 'http' : p.replaceAll(':', '');
}

String? defaultApiPort() => '4000';

String? tryGetStoredApiBaseUrl() {
  // 1) url query ?api=http://host:port
  final uri = Uri.base;
  final api = uri.queryParameters['api'];
  if (api != null && api.isNotEmpty) {
    try { html.window.localStorage['apiBaseUrl'] = api; } catch (_) {}
    return api;
  }
  // 2) localStorage
  try {
    final saved = html.window.localStorage['apiBaseUrl'];
    if (saved != null && saved.isNotEmpty) return saved;
  } catch (_) {}
  return null;
}

void persistApiBaseUrlIfWeb(String base){
  try { html.window.localStorage['apiBaseUrl'] = base; } catch (_) {}
}
