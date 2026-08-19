import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int statusCode, Object? data, {String? statusMessage}) {
  final options = RequestOptions(path: '/ai-report/202608');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      statusMessage: statusMessage,
      data: data,
    ),
  );
}

void main() {
  group('mapDioException — 공통 봉투 응답', () {
    test('봉투의 resultMessage를 그대로 예외 메시지로 쓴다', () {
      final result = mapDioException(_badResponse(500, {
        'resultCode': 500,
        'resultMessage': '아직 종료되지 않은 월은 발행할 수 없습니다',
        'resultData': null,
        'errorMessage': '아직 종료되지 않은 월은 발행할 수 없습니다',
      }, statusMessage: 'Internal Server Error'));

      expect(result, isA<ServerException>());
      expect(result.message, '아직 종료되지 않은 월은 발행할 수 없습니다');
    });

    test('404 봉투도 서버 메시지를 쓴다', () {
      final result = mapDioException(_badResponse(404, {
        'resultCode': 404,
        'resultMessage': '202607 회차 리포트가 없습니다',
        'resultData': null,
        'errorMessage': '202607 회차 리포트가 없습니다',
      }));

      expect(result.message, '202607 회차 리포트가 없습니다');
    });
  });

  group('mapDioException — FastAPI 검증 에러(422)', () {
    test('detail 배열의 msg를 예외 메시지로 쓴다', () {
      final result = mapDioException(_badResponse(422, {
        'detail': [
          {'type': 'missing', 'loc': ['body', 'userConfirmed'], 'msg': 'Field required'},
        ],
      }, statusMessage: 'Unprocessable Entity'));

      expect(result, isA<ServerException>());
      expect(result.message, 'Field required');
    });

    test("필드 조합 검증의 'Value error, ' 접두사는 떼고 보여준다", () {
      final result = mapDioException(_badResponse(422, {
        'detail': [
          {
            'type': 'value_error',
            'loc': ['body'],
            'msg': 'Value error, endDt 는 strtDt 이후여야 합니다',
          },
        ],
      }, statusMessage: 'Unprocessable Entity'));

      expect(result.message, 'endDt 는 strtDt 이후여야 합니다');
    });

    test('사유가 여러 건이면 줄바꿈으로 이어 붙인다', () {
      final result = mapDioException(_badResponse(422, {
        'detail': [
          {'msg': 'String should have at least 1 character'},
          {'msg': 'strtTm 과 endTm 은 함께 지정하거나 함께 비워야 합니다'},
        ],
      }, statusMessage: 'Unprocessable Entity'));

      expect(
        result.message,
        'String should have at least 1 character\n'
        'strtTm 과 endTm 은 함께 지정하거나 함께 비워야 합니다',
      );
    });

    test('msg가 없으면 상태코드 표기로 떨어진다', () {
      final result = mapDioException(_badResponse(422, {
        'detail': [
          {'type': 'missing'},
        ],
      }, statusMessage: 'Unprocessable Entity'));

      expect(result.message, '[422] Unprocessable Entity');
    });
  });

  group('mapDioException — 봉투가 아닌 응답 (기존 동작 유지)', () {

    test('바디가 문자열이면 상태코드 표기로 떨어진다', () {
      final result = mapDioException(
        _badResponse(502, 'Bad Gateway', statusMessage: 'Bad Gateway'),
      );

      expect(result.message, '[502] Bad Gateway');
    });

    test('resultMessage가 빈 문자열이면 상태코드 표기로 떨어진다', () {
      final result = mapDioException(_badResponse(500, {
        'resultCode': 500,
        'resultMessage': '',
      }, statusMessage: 'Internal Server Error'));

      expect(result.message, '[500] Internal Server Error');
    });
  });

  group('mapDioException — 네트워크 계열', () {
    test('연결 타임아웃', () {
      final result = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/ai-report'),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(result, isA<NetworkException>());
      expect(result.message, '네트워크 연결이 지연되고 있습니다.');
    });

    test('연결 실패', () {
      final result = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/ai-report'),
        type: DioExceptionType.connectionError,
      ));

      expect(result.message, '서버에 연결할 수 없습니다.');
    });
  });
}
