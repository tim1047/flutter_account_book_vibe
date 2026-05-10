import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/asset_model.dart';
import 'package:dio/dio.dart';

class AssetService {
  AssetService._();
  static final AssetService instance = AssetService._();

  final _dio = DioClient.instance.dio;

  Future<List<AssetListResponse>> getAssets() async {
    try {
      final response = await _dio.get('/asset');
      final api = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List)
            .map((e) =>
                AssetListResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (!api.isSuccess) throw ServerException(api.errorMessage);
      return api.resultData ?? [];
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw NetworkException(e.message ?? '알 수 없는 오류');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(e.toString());
    }
  }
}
