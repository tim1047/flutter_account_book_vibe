import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:dio/dio.dart';

/// 일정 API. 상세 조회는 없다 — 목록이 `contents`까지 전부 실어 보낸다.
/// 유형 목록(`GET /event/type`)도 고정 4종이라 [EventType] 상수로 대체했다.
class EventService {
  EventService._();
  static final EventService instance = EventService._();

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

  /// 조회 기간과 **겹치는** 일정을 모두 준다. 기간 이전에 시작해 기간 안까지
  /// 이어지는 여러 날짜 일정도 포함된다.
  ///
  /// 정렬은 서버가 `strtDt → strtTm → eventId` 오름차순으로 해주므로
  /// 타임라인은 받은 순서를 그대로 쓴다.
  Future<List<EventListResponse>> getEvents({
    required String strtDt,
    required String endDt,
    String? eventTypeCd,
    String? memberId,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/event',
          queryParameters: <String, dynamic>{
            'strtDt': strtDt,
            'endDt': endDt,
            if (eventTypeCd != null && eventTypeCd.isNotEmpty)
              'eventTypeCd': eventTypeCd,
            if (memberId != null && memberId.isNotEmpty) 'memberId': memberId,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) => EventListResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? <EventListResponse>[];
      });

  /// 생성된 `eventId`를 돌려준다.
  Future<int> createEvent(EventRequest request) => _request(() async {
        final response = await _dio.post('/event', data: request.toJson());
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as int,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  /// 전량 치환. 부분 수정(PATCH)은 없다.
  Future<void> updateEvent(int eventId, EventRequest request) =>
      _request(() async {
        final response =
            await _dio.put('/event/$eventId', data: request.toJson());
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });

  /// 404는 이미 지워졌다는 뜻이라 오류로 올리지 않는다. 호출부는 어느 쪽이든
  /// 목록만 다시 읽으면 된다.
  Future<void> deleteEvent(int eventId) => _request(() async {
        try {
          final response = await _dio.delete('/event/$eventId');
          final api = ApiResponse.fromJson(
            response.data as Map<String, dynamic>,
            (json) => json,
          );
          if (!api.isSuccess) throw ServerException(api.errorMessage);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return;
          rethrow;
        }
      });
}
