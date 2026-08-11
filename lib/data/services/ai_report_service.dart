import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:dio/dio.dart';

/// AI 자산관리 리포트 API. 경로는 `AppConfig.baseUrl`의 `/account-book`
/// 뒤에 붙으므로 `/ai-report`로 시작한다.
///
/// `POST /ai-report/questions`는 외부 cron 전용이라 여기 없다.
class AiReportService {
  AiReportService._();
  static final AiReportService instance = AiReportService._();

  final _dio = DioClient.instance.dio;

  Future<T> _request<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw NetworkException(e.message ?? '알 수 없는 오류');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(e.toString());
    }
  }

  Future<ReportStatusResponse> getStatus() => _request(() async {
        final response = await _dio.get('/ai-report/status');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ReportStatusResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  Future<List<ReportListItem>> getReports({
    int limit = 20,
    int offset = 0,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/ai-report',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) => ReportListItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  /// 한 번도 발행을 시도하지 않은 회차는 서버가 404를 준다. 그건 오류가 아니라
  /// 정상 상태이므로 예외 대신 null을 돌려준다. 발행 카드가 이 값으로
  /// "미발행"과 "직전 발행 실패"를 가른다.
  Future<ReportDetailResponse?> getReport(String period) =>
      _request<ReportDetailResponse?>(() async {
        try {
          final response = await _dio.get('/ai-report/$period');
          final api = ApiResponse.fromJson(
            response.data as Map<String, dynamic>,
            (json) =>
                ReportDetailResponse.fromJson(json as Map<String, dynamic>),
          );
          if (!api.isSuccess) throw ServerException(api.errorMessage);
          return api.resultData;
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      });

  /// 발행 요청. 응답은 즉시 돌아오고 실제 발행은 서버 백그라운드에서 돈다.
  /// 이미 running인 회차에 다시 요청하면 오류가 아니라 현재 상태만 돌아온다.
  Future<ReportStatusResponse> publish(String period) => _request(() async {
        final response = await _dio.post('/ai-report/$period');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ReportStatusResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  Future<ProfileResponse> getProfile() => _request(() async {
        final response = await _dio.get('/ai-report/profile');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ProfileResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  /// 사용자 확정 구역 전면 교체. 부분 갱신이 아니다.
  Future<ProfileResponse> updateProfile(String userConfirmed) =>
      _request(() async {
        final response = await _dio.put(
          '/ai-report/profile',
          data: {'userConfirmed': userConfirmed},
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ProfileResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });
}
