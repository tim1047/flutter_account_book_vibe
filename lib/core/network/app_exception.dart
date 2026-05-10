sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class ServerException extends AppException {
  const ServerException(super.message);

  factory ServerException.fromCode(int code, String message) =>
      ServerException('[$code] $message');
}

final class ParseException extends AppException {
  const ParseException(super.message);
}
