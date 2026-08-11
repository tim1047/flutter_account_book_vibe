import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/data/services/ai_report_service.dart';
import 'package:flutter/foundation.dart';

/// 프로필 3구역의 로드와 저장.
///
/// 앱이 쓸 수 있는 건 `userConfirmed` 하나뿐이다. 나머지 두 구역은 LLM이
/// 쓰고 요청 스키마에 아예 없어서 덮어쓸 경로가 없다.
class AiProfileViewModel extends ChangeNotifier {
  ProfileResponse? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await AiReportService.instance.getProfile();
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 확정 구역 전면 교체. 성공하면 null, 실패하면 화면이 토스트로
  /// 띄울 메시지를 돌려준다. 실패해도 화면의 입력 내용은 건드리지 않는다.
  Future<String?> save(String userConfirmed) async {
    isSaving = true;
    notifyListeners();

    try {
      profile = await AiReportService.instance.updateProfile(userConfirmed);
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
