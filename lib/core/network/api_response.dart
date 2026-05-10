class ApiResponse<T> {
  const ApiResponse({
    required this.resultCode,
    required this.resultMessage,
    this.resultData,
    this.errorMessage = '',
  });

  final int resultCode;
  final String resultMessage;
  final T? resultData;
  final String errorMessage;

  bool get isSuccess => resultCode == 200;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      resultCode: json['resultCode'] as int,
      resultMessage: json['resultMessage'] as String? ?? '',
      resultData:
          json['resultData'] != null ? fromJsonT(json['resultData']) : null,
      errorMessage: json['errorMessage'] as String? ?? '',
    );
  }
}
