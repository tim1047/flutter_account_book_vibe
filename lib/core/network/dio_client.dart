import 'dart:developer';

import 'package:account_book_vibe/core/constants/app_config.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (AppConfig.isDebug) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => log(obj.toString(), name: 'DioClient'),
        ),
      );
    }

    dio.interceptors.add(_ErrorInterceptor());
    return dio;
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = const NetworkException('네트워크 연결이 지연되고 있습니다.');
      case DioExceptionType.connectionError:
        exception = const NetworkException('서버에 연결할 수 없습니다.');
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final message = err.response?.statusMessage ?? '알 수 없는 오류';
        exception = ServerException.fromCode(statusCode, message);
      case DioExceptionType.cancel:
        exception = const NetworkException('요청이 취소되었습니다.');
      default:
        exception = NetworkException(err.message ?? '알 수 없는 네트워크 오류');
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
        message: exception.message,
      ),
    );
  }
}
