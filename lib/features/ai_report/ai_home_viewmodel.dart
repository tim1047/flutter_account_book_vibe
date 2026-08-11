import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/data/services/ai_report_service.dart';
import 'package:flutter/foundation.dart';

/// AI 탭 루트의 상태. 발행 가능 회차의 상태 + 지난 리포트 목록을 함께 들고 있다.
///
/// 발행 완료를 폴링하지 않는다. 서버에 푸시 채널이 없고, 사용자가 당겨서
/// 새로고침하면 [load]가 다시 돈다.
class AiHomeViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isPublishing = false;
  String? errorMessage;

  ReportStatusResponse? status;
  List<ReportListItem> reports = [];

  /// 발행 가능 회차의 상세. null이면 그 회차를 한 번도 발행 시도하지 않은 것이다.
  ReportDetailResponse? publishableDetail;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // publishablePeriod가 status 응답에서 나오므로 셋을 한 번에 묶을 수 없다.
      final currentStatus = await AiReportService.instance.getStatus();
      final rest = await Future.wait([
        AiReportService.instance.getReports(),
        AiReportService.instance.getReport(currentStatus.publishablePeriod),
      ]);

      status = currentStatus;
      reports = excludePublishable(
        rest[0] as List<ReportListItem>,
        currentStatus.publishablePeriod,
      );
      publishableDetail = rest[1] as ReportDetailResponse?;
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 발행 요청. 성공하면 null, 실패하면 화면이 토스트로 띄울 메시지를 돌려준다.
  ///
  /// `POST`가 상태 조회와 같은 스키마를 돌려주므로(API 스펙 §5.7) 재조회 없이
  /// 그 값으로 교체한다. 실제 발행은 서버 백그라운드에서 계속 돈다.
  Future<String?> publish() async {
    final period = status?.publishablePeriod;
    if (period == null) return null;

    isPublishing = true;
    notifyListeners();

    try {
      status = await AiReportService.instance.publish(period);
      publishableDetail = null;
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  /// 발행 카드와 목록이 같은 회차를 두 번 보여주지 않게 한다.
  static List<ReportListItem> excludePublishable(
    List<ReportListItem> reports,
    String publishablePeriod,
  ) =>
      reports.where((e) => e.period != publishablePeriod).toList();
}
