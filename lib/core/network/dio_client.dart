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

/// [DioException]을 앱 내부 [AppException]으로 변환한다.
///
/// 서버가 공통 봉투(`CommResponse`)로 내려준 `resultMessage`를 최우선으로 쓴다.
/// 일부 도메인(ai-report)은 입력값 오류도 500 + 메시지 문자열로 구분하게 되어
/// 있어서, 상태코드만 남기면 화면에서 사유를 보여줄 방법이 없다.
/// 봉투가 아닌 응답(FastAPI 검증 에러의 `detail` 배열 등)은 기존대로
/// `[코드] 상태문구` 형태로 떨어진다.
AppException mapDioException(DioException err) {
  switch (err.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('네트워크 연결이 지연되고 있습니다.');
    case DioExceptionType.connectionError:
      return const NetworkException('서버에 연결할 수 없습니다.');
    case DioExceptionType.badResponse:
      final envelopeMessage = _envelopeMessage(err.response?.data);
      if (envelopeMessage != null) return ServerException(envelopeMessage);
      final statusCode = err.response?.statusCode ?? 0;
      final message = err.response?.statusMessage ?? '알 수 없는 오류';
      return ServerException.fromCode(statusCode, message);
    case DioExceptionType.cancel:
      return const NetworkException('요청이 취소되었습니다.');
    default:
      return NetworkException(err.message ?? '알 수 없는 네트워크 오류');
  }
}

String? _envelopeMessage(Object? data) {
  if (data is! Map) return null;
  for (final key in const ['resultMessage', 'errorMessage']) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = mapDioException(err);

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
