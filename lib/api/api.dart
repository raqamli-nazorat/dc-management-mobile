import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('=== LOGIN REQUEST ===');
    debugPrint('URL: ${_dio.options.baseUrl}auth/login/');
    debugPrint('Body: { username: "$username", password: "$password" }');

    try {
      final response = await _dio.post('auth/login/', data: {
        'username': username,
        'password': password,
      });
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

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data as Map<String, dynamic>;
  }
}