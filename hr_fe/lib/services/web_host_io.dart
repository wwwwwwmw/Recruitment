String currentHost() => 'localhost';
String? currentScheme() => 'http';
String? defaultApiPort() => '4000';
String? tryGetStoredApiBaseUrl() => null; // non-web: no storage
void persistApiBaseUrlIfWeb(String _) {}
