/// Generic wrapper for the `{success, message, data}` envelope every
/// E-LIKAS public endpoint returns.
///
/// [fromData] decodes whatever `T` is for a given call site — for a
/// list endpoint, that's mapping over the raw `data` list and calling
/// each model's own JSON factory constructor.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final T data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: fromData(json['data']),
    );
  }
}
