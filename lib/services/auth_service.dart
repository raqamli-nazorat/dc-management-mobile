import 'dart:convert';
import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService({ApiService? api, StorageService? storage})
    : _api = api ?? ApiService(),
      _storage = storage ?? StorageService();

  Future<bool> signIn(String username, String password) async {
    await _storage.saveString(StorageService.tokenKey, 'fake_token_123');
    await _storage.saveString('plain_username', username);
    await _storage.saveString('password_length', password.length.toString());
    PinSession.instance.markVerified();

    try {
      final response = await _api.login(username, password);
      debugPrint('=== AUTH SERVICE: full response: $response ===');

      final success = response['success'] as bool? ?? false;
      if (!success) return false;

      final innerData = response['data'] as Map<String, dynamic>?;
      final accessToken = innerData?['access'] as String?;
      final refreshToken = innerData?['refresh'] as String?;
      final user = innerData?['user'] as Map<String, dynamic>?;

      debugPrint('=== AUTH SERVICE: access=$accessToken ===');
      if (accessToken == null) return false;

      await _storage.saveString(StorageService.tokenKey, accessToken);
      await _storage.saveString('plain_username', username);
      await _storage.saveString('password_length', password.length.toString());
      if (refreshToken != null) {
        await _storage.saveString('refresh_token', refreshToken);
      }
      if (user != null) {
        await _storage.saveString(StorageService.userKey, jsonEncode(user));
      }

      PinSession.instance.markVerified();
      debugPrint('=== AUTH SERVICE: login muvaffaqiyatli ===');
      return true;
    } catch (e, stack) {
      debugPrint('=== AUTH SERVICE ERROR: $e ===');
      debugPrint('=== STACK: $stack ===');
      return false;
    }
  }

  /// Returns (success, throttleSeconds, isApiError).
  /// throttleSeconds > 0 means API returned 429 — wait that many seconds.
  /// isApiError is true when a network/server exception occurred.
  Future<(bool, int?, bool)> signInWithPin(String pin) async {
    try {
      final username = await _storage.getString('plain_username');
      debugPrint('=== PIN LOGIN: username=$username, pin=$pin ===');
      if (username == null || username.isEmpty) return (false, null, false);

      final response = await _api.login(username, pin);
      debugPrint('=== PIN LOGIN RESPONSE: $response ===');

      final success = response['success'] as bool? ?? false;
      if (!success) {
        final error = response['error'] as Map<String, dynamic>?;
        final errorId = (error?['errorId'] as num?)?.toInt();
        if (errorId == 429) {
          final msg = error?['errorMsg'] as String? ?? '';
          final match = RegExp(r'(\d+)\s+second').firstMatch(msg);
          final secs = match != null ? int.tryParse(match.group(1)!) : 30;
          return (false, secs ?? 30, false);
        }
        return (false, null, false);
      }

      final innerData = response['data'] as Map<String, dynamic>?;
      final accessToken = innerData?['access'] as String?;
      final refreshToken = innerData?['refresh'] as String?;
      if (accessToken == null) return (false, null, false);

      await _storage.saveString(StorageService.tokenKey, accessToken);
      if (refreshToken != null) {
        await _storage.saveString('refresh_token', refreshToken);
      }

      PinSession.instance.markVerified();
      return (true, null, false);
    } catch (e) {
      debugPrint('=== PIN LOGIN ERROR: $e ===');
      return (false, null, true);
    }
  }

  Future<void> signOut() async {
    PinSession.instance.reset();
    await _storage.clear();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getString(StorageService.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() => _storage.getString(StorageService.tokenKey);
  Future<String?> getUsername() => _storage.getString('plain_username');
  Future<int?> getPasswordLength() async {
    final raw = await _storage.getString('password_length');
    return raw != null ? int.tryParse(raw) : null;
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<List<String>> getUserRoles() async {
    final raw = await _storage.getString(StorageService.userKey);
    if (raw == null) return [];

    final user = jsonDecode(raw);
    final roles = user['roles'];

    if (roles is List) {
      return roles.map((e) => e.toString()).toList();
    }
    return [];
  }
}
