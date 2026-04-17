import 'package:dcmanagement/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thrown when the backend returns success=false.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;

  ApiService({String baseUrl = 'https://backend.raqamlinazorat.uz/api/'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  /// Unwraps { "data": ..., "error": ..., "success": bool }.
  /// Throws [ApiException] when success=false.
  dynamic _unwrap(Map<String, dynamic> body) {
    final success = body['success'] as bool? ?? false;
    if (!success) {
      final error = body['error'] as Map<String, dynamic>?;
      final msg = error?['errorMsg'] as String? ?? "Noma'lum xatolik yuz berdi";
      final code = (error?['errorId'] as num?)?.toInt() ?? 0;
      throw ApiException(msg, code);
    }
    return body['data'];
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('=== LOGIN REQUEST ===');
    debugPrint('URL: ${_dio.options.baseUrl}auth/login/');
    debugPrint('Body: { username: "$username", password: "$password" }');

    try {
      final response = await _dio.post(
        'auth/login/',
        data: {'username': username, 'password': password},
      );
      debugPrint('=== LOGIN RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('=== LOGIN ERROR ===');
      debugPrint('Type: ${e.type}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      rethrow;
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Returns all users. Throws [ApiException] with statusCode=403 if the
  /// current user does not have permission.
  Future<List<UserModel>> getUsers(String token) async {
    final response = await _dio.get('users/', options: _auth(token));
    debugPrint('=== GET USERS RAW ===');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Data: ${response.data}');
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body) as Map<String, dynamic>? ?? {};
    final results = data['results'] as List? ?? [];
    return results
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a single user by id. Throws [ApiException] on 403/404.
  Future<UserModel> getUserDetail(String token, int id) async {
    final response = await _dio.get('users/$id/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body) as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data);
  }

  /// Returns the currently authenticated user's profile.
  Future<UserModel> getMe(String token) async {
    final response = await _dio.get('users/me/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body) as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data);
  }

  // ── Expense Requests ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExpenseRequests(String token) async {
    final response = await _dio.get(
      'expense-request/',
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      final results = data['results'] as List? ?? [];
      return results.cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> getPayrolls(String token) async {
    final response = await _dio.get('payrolls/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> getProjects(String token) async {
    final response = await _dio.get('projects/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> getExpenseCategories(String token) async {
    final response = await _dio.get('expense-category/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> getExpenseRequestDetail(
      String token, int id) async {
    final response =
        await _dio.get('expense-request/$id/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    return _unwrap(body) as Map<String, dynamic>;
  }

  Future<void> createExpenseRequest(
      String token, Map<String, dynamic> data) async {
    final response = await _dio.post('expense-request/',
        data: data, options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    _unwrap(body);
  }

  // ── Legacy ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data as Map<String, dynamic>;
  }
}
