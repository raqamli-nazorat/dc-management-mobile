import 'dart:convert';

import 'package:dcmanagement/models/ledger_model.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Har bir API so‘rov/javobini terminalga yozadi (`ApiService` va token refresh Dio).
class _ApiLoggingInterceptor extends Interceptor {
  static String _payload(dynamic data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fieldLines =
          data.fields.map((e) => '    ${e.key}: ${e.value}').join('\n');
      final fileLines = data.files
          .map((e) => '    ${e.key}: file(${e.value.filename})')
          .join('\n');
      return 'FormData(\n  fields:\n$fieldLines\n  files:\n$fileLines\n  )';
    }
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {}
    return data.toString();
  }

  static Map<String, dynamic> _headersForLog(Map<String, dynamic> headers) {
    final out = Map<String, dynamic>.from(headers);
    final auth = out['Authorization'] ?? out['authorization'];
    if (auth is String && auth.startsWith('Bearer ')) {
      out['Authorization'] = 'Bearer <redacted>';
    }
    return out;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer()
      ..writeln('=== API REQUEST [${options.method}] ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('query: ${_payload(options.queryParameters)}');
    }
    if (options.data != null) {
      buffer.writeln('body: ${_payload(options.data)}');
    }
    if (options.headers.isNotEmpty) {
      buffer.writeln('headers: ${_payload(_headersForLog(options.headers))}');
    }
    buffer.write('===');
    debugPrint(buffer.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '=== API RESPONSE [${response.statusCode}] ${response.requestOptions.uri}\n'
      'data: ${_payload(response.data)}\n===',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    final buf = StringBuffer()
      ..writeln(
        '=== API ERROR [${res?.statusCode}] ${err.requestOptions.uri}',
      )
      ..writeln('type: ${err.type}')
      ..writeln('message: ${err.message}');
    if (res?.data != null) {
      buf.writeln('data: ${_payload(res!.data)}');
    }
    buf.write('===');
    debugPrint(buf.toString());
    handler.next(err);
  }
}

/// Thrown when the backend returns success=false.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class _TokenRefreshInterceptor extends Interceptor {
  final Dio dio;
  final StorageService storage;
  bool _isRefreshing = false;

  _TokenRefreshInterceptor(this.dio, this.storage);

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    // validateStatus allows 401 through as a normal response — catch it here
    if (response.statusCode == 401 &&
        !response.requestOptions.path.contains('auth/token/refresh/') &&
        !response.requestOptions.path.contains('auth/login/') &&
        !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await storage.getString('refresh_token');
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshDio = Dio(BaseOptions(
            baseUrl: dio.options.baseUrl,
            validateStatus: (s) => s != null && s < 600,
          ));
          refreshDio.interceptors.add(_ApiLoggingInterceptor());
          final refreshResponse = await refreshDio.post(
            'auth/token/refresh/',
            data: {'refresh': refreshToken},
          );

          final body = refreshResponse.data as Map<String, dynamic>?;
          final success = body?['success'] as bool? ?? false;
          final dataMap = body?['data'] as Map<String, dynamic>?;
          final newAccess =
              (dataMap?['access'] ?? body?['access']) as String?;

          if (newAccess != null && (success || dataMap == null)) {
            debugPrint('=== TOKEN REFRESHED, retrying request ===');
            await storage.saveString(StorageService.tokenKey, newAccess);
            final opts = response.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final retryResponse = await dio.fetch(opts);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        debugPrint('=== TOKEN REFRESH ERROR: $e ===');
      }
      // Refresh ham ishlamadi — foydalanuvchini login sahifasiga yo'naltiramiz
      debugPrint('=== SESSION EXPIRED: logging out ===');
      await _forceLogout();
      _isRefreshing = false;
    }
    return handler.next(response);
  }

  Future<void> _forceLogout() async {
    await storage.clear();
    PinSession.instance.reset(); // router refresh => /login
  }
}

class ApiService {
  final Dio _dio;
  final StorageService _storage;

  ApiService({
    String baseUrl = 'https://backend.raqamlinazorat.uz/api/',
    StorageService? storage,
  })  : _storage = storage ?? StorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            followRedirects: true,
            maxRedirects: 5,
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    _dio.interceptors.add(_ApiLoggingInterceptor());
    _dio.interceptors.add(_TokenRefreshInterceptor(_dio, _storage));
  }

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  /// Unwraps { "data": ..., "error": ..., "success": bool }.
  /// Throws [ApiException] when success=false.
  dynamic _unwrap(Map<String, dynamic> body) {
    final success = body['success'] as bool? ?? false;
    if (!success) {
      debugPrint('=== API _unwrap: success=false, full body: $body ===');
      final error = body['error'] as Map<String, dynamic>?;
      final code = (error?['errorId'] as num?)?.toInt() ?? 0;

      final details = error?['details'] as Map<String, dynamic>?;
      final String msg;
      if (details != null && details.isNotEmpty) {
        msg = details.entries.map((e) {
          final msgs = e.value is List
              ? (e.value as List).map((v) => v.toString()).join(', ')
              : e.value.toString();
          return msgs;
        }).join('\n');
      } else {
        msg = error?['errorMsg'] as String? ?? "Noma'lum xatolik yuz berdi";
      }

      throw ApiException(msg, code);
    }
    return body['data'];
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'auth/login/',
        data: {'username': username, 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Returns all users. Throws [ApiException] with statusCode=403 if the
  /// current user does not have permission.
  Future<List<UserModel>> getUsers(String token) async {
    final response = await _dio.get('users/', options: _auth(token));
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

  Future<List<Map<String, dynamic>>> getMyExpenseRequests(String token) async {
    final response = await _dio.get(
      'expense-request/',
      queryParameters: {'my_requests': 'true'},
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
    final response = await _dio.get('payroll/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> confirmPayroll(String token, int id) async {
    final response = await _dio.post(
      'payroll/confirm/',
      data: {'payroll_ids': [id]},
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    _unwrap(body);
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

  Future<void> confirmExpenseRequest(String token, int id) async {
    final response = await _dio.post(
      'expense-request/$id/confirm/',
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    _unwrap(body);
  }

  Future<void> payExpenseRequest(String token, int id) async {
    final response = await _dio.post(
      'expense-request/$id/pay/',
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    _unwrap(body);
  }

  Future<Map<String, dynamic>> updateExpenseRequest(
      String token, int id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      'expense-request/$id/',
      data: data,
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    return _unwrap(body) as Map<String, dynamic>;
  }

  Future<void> deleteExpenseRequest(String token, int id) async {
    final response = await _dio.delete(
      'expense-request/$id/',
      options: _auth(token),
    );
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return;
    }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      _unwrap(body);
    }
  }

  Future<void> createExpenseRequest(
      String token, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        'expense-request/',
        data: data,
        options: _auth(token),
      );
      final body = response.data as Map<String, dynamic>;
      _unwrap(body);
    } on DioException {
      rethrow;
    }
  }

  // ── Tasks ────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTasks(
    String token, {
    String? status,
    int? projectId,
  }) async {
    final response = await _dio.get(
      'tasks/',
      queryParameters: {
        if (status != null) 'status': status,
        if (projectId != null) 'project': projectId,
      },
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> getTaskDetail(String token, int id) async {
    final response = await _dio.get('tasks/$id/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    return _unwrap(body) as Map<String, dynamic>;
  }

  Future<void> createTask(String token, Map<String, dynamic> data) async {
    final response = await _dio.post(
      'tasks/',
      data: data,
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    _unwrap(body);
  }

  Future<void> updateTask(
      String token, int id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      'tasks/$id/',
      data: data,
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    _unwrap(body);
  }

  Future<void> deleteTask(String token, int id) async {
    final response =
        await _dio.delete('tasks/$id/', options: _auth(token));
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) return;
    final body = response.data;
    if (body is Map<String, dynamic>) _unwrap(body);
  }

  // ── Meetings ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMeetings(
    String token, {
    bool myMeetings = false,
  }) async {
    final response = await _dio.get(
      'meetings/',
      queryParameters: myMeetings ? {'my_meetings': 'true'} : null,
      options: _auth(token),
    );
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body);
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  // ── Ledger/History ──────────────────────────────────────────────────────────

  Future<List<LedgerModel>> getLedgerEntries(String token) async {
    final response = await _dio.get('ledger/', options: _auth(token));
    final body = response.data as Map<String, dynamic>;
    final data = _unwrap(body) as Map<String, dynamic>? ?? {};
    final results = data['results'] as List? ?? [];
    return results
        .map((e) => LedgerModel.fromJson(e as Map<String, dynamic>))
        .toList();
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