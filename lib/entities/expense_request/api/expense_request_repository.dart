import 'package:dio/dio.dart';
import '../../../shared/api/api_endpoints.dart';
import '../model/expense_request.dart';

class ExpenseRequestRepository {
  final Dio _dio;
  ExpenseRequestRepository(this._dio);

  Future<List<ExpenseRequest>> getAll({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.expenseRequests,
      queryParameters: {
        'page': page,
        'limit': limit,
        'status': status,
      }..removeWhere((_, v) => v == null),
    );
    final raw = response.data['data'] as List<dynamic>;
    return raw
        .map((e) => ExpenseRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseRequest> create(ExpenseRequestCreatePayload payload) async {
    final response = await _dio.post(
      ApiEndpoints.expenseRequests,
      data: payload.toJson(),
    );
    return ExpenseRequest.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.expenseRequestById(id));
  }
}
