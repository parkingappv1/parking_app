class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.isSuccess,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.success({T? data, String? message}) {
    return ApiResponse<T>(isSuccess: true, data: data, message: message);
  }

  factory ApiResponse.error({
    String? message,
    int? statusCode,
    Map<String, dynamic>? errors,
    int? code,
  }) {
    return ApiResponse<T>(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse<T>(
      isSuccess: json['success'] ?? false,
      data: data,
      message: json['message'],
      statusCode: json['status_code'],
      errors: json['errors'],
    );
  }
}
