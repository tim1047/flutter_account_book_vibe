import 'package:account_book_vibe/core/network/api_response.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:dio/dio.dart';

class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

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

  Future<List<AccountListResponse>> getAccounts({
    String? strtDt,
    String? endDt,
    String? divisionId,
    String? categoryId,
    String? categorySeq,
    String? memberId,
  }) =>
      _request(() async {
        final response = await _dio.get(
          '/account',
          queryParameters: {
            if (strtDt != null) 'strtDt': strtDt,
            if (endDt != null) 'endDt': endDt,
            if (divisionId != null) 'divisionId': divisionId,
            if (categoryId != null) 'categoryId': categoryId,
            if (categorySeq != null) 'categorySeq': categorySeq,
            if (memberId != null) 'memberId': memberId,
          },
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List)
              .map((e) =>
                  AccountListResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
        return api.resultData ?? [];
      });

  Future<void> createAccount(AccountRequest request) =>
      _request(() async {
        final response =
            await _dio.post('/account', data: request.toJson());
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });

  Future<void> updateAccount(int accountId, AccountRequest request) =>
      _request(() async {
        final response = await _dio.put(
          '/account/$accountId',
          data: request.toJson(),
        );
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });

  Future<void> deleteAccount(int accountId) =>
      _request(() async {
        final response = await _dio.delete('/account/$accountId');
        final api = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );
        if (!api.isSuccess) throw ServerException(api.errorMessage);
      });
}
