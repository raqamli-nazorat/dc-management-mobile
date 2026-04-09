import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionRepository {
  static const _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
