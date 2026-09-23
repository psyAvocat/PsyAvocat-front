/// Enveloppe standard pour les réponses API Spring Boot.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? (json['status'] == 'OK' || json['status'] == 200 || !json.containsKey('error')),
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
