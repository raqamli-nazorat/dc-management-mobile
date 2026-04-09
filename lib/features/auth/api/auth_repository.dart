import 'package:dio/dio.dart';
import '../../../shared/api/api_endpoints.dart';
import '../../../entities/session/model/session.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<({String token, AuthUser user})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiEndpoints.authLogin, data: {
      'email': email,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.authLogout);
    } catch (_) {}
  }
}
