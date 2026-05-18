import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:flutter/foundation.dart';

class DashboardSharedViewModel extends ChangeNotifier {
  DashboardSharedViewModel(this._period) {
    _period.addListener(load);
  }

  final DashboardPeriodViewModel _period;
  DashboardPeriodViewModel get period => _period;

  bool isLoading = false;
  String? errorMessage;
  List<AccountListResponse> accounts = const [];
  List<CategorySumResponse> catSums = const [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _period.range;
      final results = await Future.wait([
        AccountService.instance.getAccounts(
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
        CategoryService.instance.getCategorySum(
          divisionId: Division.expense,
          strtDt: range.strtDt,
          endDt: range.endDt,
        ),
      ]);

      accounts = results[0] as List<AccountListResponse>;
      catSums = results[1] as List<CategorySumResponse>;
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _period.removeListener(load);
    super.dispose();
  }
}
