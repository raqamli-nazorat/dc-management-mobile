import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  DioClient._();

  static const String _baseUrl = 'http://localhost:3000/api';
  static final _storage = const FlutterSecureStorage();

  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Request interceptor: attach Bearer token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
            // Navigation is handled at page level via Riverpod state
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
