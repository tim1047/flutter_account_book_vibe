import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:dio/dio.dart';

class DivisionService {
  DivisionService._();
  static final DivisionService instance = DivisionService._();

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

  Future<List<DivisionListResponse>> getDivisions() =>
      _request(() async {
        final response = await _dio.get('/division');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) =>
                  DivisionListResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<DivisionSumResponse> getDivisionSum({
    String? strtDt,
    String? endDt,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/division/sum',
          queryParameters: {
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              DivisionSumResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  Future<List<DailyChartEntry>> getDivisionSumDaily(
    String divisionId, {
    String? strtDt,
    String? endDt,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/division/$divisionId/sum-daily',
          queryParameters: {
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) {
            final rows = json as List;
            final entries = <DailyChartEntry>[];
            for (final row in rows.skip(1)) {
              final pair = row as List;
              final label = pair[0] as String;
              final price = (pair[1] as num).toInt();
              final day = int.tryParse(label.replaceAll('일', '')) ?? 0;
              if (day > 0) entries.add(DailyChartEntry(day: day, price: price));
            }
            return entries;
          },
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<SumGroupByMonthResponse> getDivisionSumGroupByMonth(
    String divisionId, {
    String? procDt,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/division/$divisionId/sum-group-by-month',
          queryParameters: {
            if (procDt != null) 'procDt': procDt,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => SumGroupByMonthResponse.fromJson(
              json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });
}
