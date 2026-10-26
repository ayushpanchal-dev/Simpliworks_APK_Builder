import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialService {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'git_cred_';

  static String? _inMemoryUsername;
  static String? _inMemoryPasswordOrToken;

  static void setSessionCredentials(String username, String passwordOrToken) {
    _inMemoryUsername = username;
    _inMemoryPasswordOrToken = passwordOrToken;
  }

  static (String?, String?) getSessionCredentials() {
    return (_inMemoryUsername, _inMemoryPasswordOrToken);
  }

  static Future<void> savePersistentCredentials(String domain, String username, String token) async {
    await _storage.write(key: '$_keyPrefix${domain}_user', value: username);
    await _storage.write(key: '$_keyPrefix${domain}_token', value: token);
  }

  static Future<(String?, String?)> getPersistentCredentials(String domain) async {
    final user = await _storage.read(key: '$_keyPrefix${domain}_user');
    final token = await _storage.read(key: '$_keyPrefix${domain}_token');
    return (user, token);
  }
}
