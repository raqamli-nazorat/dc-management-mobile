class ApiResponse<T> {
  final T data;
  final String? message;
  final bool success;

  const ApiResponse({
    required this.data,
    this.message,
    required this.success,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return ApiResponse(
      data: fromJsonT(json['data']),
      message: json['message'] as String?,
      success: json['success'] as bool? ?? true,
    );
  }
}
