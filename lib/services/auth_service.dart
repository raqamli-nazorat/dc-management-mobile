import 'dart:convert';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService({ApiService? api, StorageService? storage})
    : _api = api ?? ApiService(),
      _storage = storage ?? StorageService();

  Future<bool> signIn(String username, String password) async {
    try {
      final response = await _api.login(username, password);

      debugPrint('=== AUTH SERVICE: full response: $response ===');

      final success = response['success'] as bool? ?? false;
      if (!success) {
        debugPrint('=== AUTH SERVICE: success=false, login failed ===');
        return false;
      }

      final innerData = response['data'] as Map<String, dynamic>?;
      debugPrint('=== AUTH SERVICE: inner data keys: ${innerData?.keys.toList()} ===');

      final accessToken = innerData?['access'] as String?;
      final refreshToken = innerData?['refresh'] as String?;
      final user = innerData?['user'] as Map<String, dynamic>?;

      debugPrint('=== AUTH SERVICE: access token = $accessToken ===');
      debugPrint('=== AUTH SERVICE: user = $user ===');

      if (accessToken == null) {
        debugPrint('=== AUTH SERVICE: access token null, login failed ===');
        return false;
      }

      await _storage.saveString(StorageService.tokenKey, accessToken);
      if (refreshToken != null) {
        await _storage.saveString('refresh_token', refreshToken);
      }
      if (user != null) {
        await _storage.saveString(StorageService.userKey, jsonEncode(user));
      }

      debugPrint('=== AUTH SERVICE: tokenlar saqlandi, login muvaffaqiyatli ===');
      return true;
    } catch (e, stack) {
      debugPrint('=== AUTH SERVICE ERROR: $e ===');
      debugPrint('=== STACK: $stack ===');
      return false;
    }
  }

  Future<void> signOut() async {
    await _storage.remove(StorageService.tokenKey);
    await _storage.remove(StorageService.userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getString(StorageService.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() => _storage.getString(StorageService.tokenKey);
}
