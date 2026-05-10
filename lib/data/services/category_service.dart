import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:dio/dio.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

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

  Future<List<CategoryListResponse>> getCategories({
    String? divisionId,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/category',
          queryParameters: {
            if (divisionId != null) 'divisionId': divisionId,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) =>
                  CategoryListResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<List<CategorySeqListResponse>> getCategorySeqs(
    String categoryId,
  ) =>
      _request(() async {
        final response =
            await _dio.get('/category/$categoryId/category-seq');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) =>
                  CategorySeqListResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<List<CategorySeqSumResponse>> getCategorySeqSum({
    String? divisionId,
    String? strtDt,
    String? endDt,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/category/category-seq/sum',
          queryParameters: {
            if (divisionId != null) 'divisionId': divisionId,
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) =>
                  CategorySeqSumResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<List<CategorySumResponse>> getCategorySum({
    String? divisionId,
    String? strtDt,
    String? endDt,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/category/sum',
          queryParameters: {
            if (divisionId != null) 'divisionId': divisionId,
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) =>
                  CategorySumResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });
}
