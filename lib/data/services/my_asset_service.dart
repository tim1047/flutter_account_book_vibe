import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:dio/dio.dart';

class MyAssetService {
  MyAssetService._();
  static final MyAssetService instance = MyAssetService._();

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

  Future<MyAssetListResponse> getMyAssets({
    String? strtDt,
    String? endDt,
    String? type,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/my-asset',
          queryParameters: {
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
            if (type != null) 'type': type,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              MyAssetListResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });

  Future<void> createMyAsset(MyAssetRequest request) =>
      _request(() async {
        final response =
            await _dio.post('/my-asset', data: request.toJson());
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });

  Future<void> updateMyAsset(String myAssetId, MyAssetRequest request) =>
      _request(() async {
        final response = await _dio.put(
          '/my-asset/$myAssetId',
          data: request.toJson(),
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });

  Future<void> deleteMyAsset(String myAssetId) =>
      _request(() async {
        final response = await _dio.delete('/my-asset/$myAssetId');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });

  Future<List<MyAssetSumResponse>> getMyAssetSum({
    String? strtDt,
    String? endDt,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/my-asset/sum',
          queryParameters: {
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .expand((group) => (group['data'] as List).map(
                    (e) => MyAssetSumResponse.fromJson(
                        e as Map<String, dynamic>),
                  ))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<MyAssetListResponse> refreshMyAsset(String procDt) =>
      _request(() async {
        final response = await _dio.post(
          '/my-asset/refresh',
          data: {'procDt': procDt},
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              MyAssetListResponse.fromJson(json as Map<String, dynamic>),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData!;
      });
}
