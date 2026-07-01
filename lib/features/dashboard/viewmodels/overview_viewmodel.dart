import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_period_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/dashboard_shared_viewmodel.dart';
import 'package:flutter/foundation.dart';

class CategoryExpenseItem {
  const CategoryExpenseItem({
    required this.categoryId,
    required this.categoryNm,
    required this.amount,
    required this.ratio,
  });

  final String categoryId;
  final String categoryNm;
  final int amount;
  final double ratio;
}

class DashboardOverviewData {
  const DashboardOverviewData({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalInvest,
    required this.prevTotalIncome,
    required this.prevTotalExpense,
    required this.prevTotalInvest,
    required this.topExpenseCategories,
    required this.recentTransactions,
    required this.changeLabel,
  });

  final int totalIncome;
  final int totalExpense;
  final int totalInvest;
  final int prevTotalIncome;
  final int prevTotalExpense;
  final int prevTotalInvest;
  final List<CategoryExpenseItem> topExpenseCategories;
  final List<AccountListResponse> recentTransactions;
  final String changeLabel;

  int get savings => totalIncome - totalExpense;
  int get prevSavings => prevTotalIncome - prevTotalExpense;

  int get incomeChange => totalIncome - prevTotalIncome;
  int get expenseChange => totalExpense - prevTotalExpense;
  int get savingsChange => savings - prevSavings;
  int get investChange => totalInvest - prevTotalInvest;
}

class DashboardOverviewViewModel extends ChangeNotifier {
  DashboardOverviewViewModel(this._shared) {
    _shared.addListener(_onSharedUpdated);
  }

  final DashboardSharedViewModel _shared;
  DashboardPeriodViewModel get _period => _shared.period;

  bool isLoading = false;
  String? errorMessage;
  DashboardOverviewData? data;

  // Internal state for own data
  bool _ownLoading = false;
  List<AccountListResponse>? _prevAccounts;
  bool _sharedWasLoading = false;

  /// Public entry point (called on init and when needed).
  Future<void> load() => _loadOwn();

  Future<void> _loadOwn() async {
    _ownLoading = true;
    _prevAccounts = null;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prevRange = _period.prevRange;
      _prevAccounts = await AccountService.instance.getAccounts(
        strtDt: prevRange.strtDt,
        endDt: prevRange.endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
      _ownLoading = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    _ownLoading = false;
    _tryBuildData();
  }

  void _onSharedUpdated() {
    if (_shared.isLoading) {
      _sharedWasLoading = true;
      return;
    }
    if (_sharedWasLoading) {
      _sharedWasLoading = false;
      _loadOwn();
      return;
    }
    _tryBuildData();
  }

  void _tryBuildData() {
    if (_ownLoading || _shared.isLoading) return;
    if (_prevAccounts == null) return;

    if (_shared.errorMessage != null) {
      errorMessage = _shared.errorMessage;
      isLoading = false;
      notifyListeners();
      return;
    }

    final allAccounts = _shared.accounts;
    final catSums = _shared.catSums;

    final sums = sumsByDivision(allAccounts);
    final prevSums = sumsByDivision(_prevAccounts!);

    final allTxs = [...allAccounts]
      ..sort((a, b) => b.accountDt.compareTo(a.accountDt));

    data = DashboardOverviewData(
      changeLabel: _period.changeLabel,
      totalIncome: sums.income,
      totalExpense: sums.expense,
      totalInvest: sums.invest,
      prevTotalIncome: prevSums.income,
      prevTotalExpense: prevSums.expense,
      prevTotalInvest: prevSums.invest,
      topExpenseCategories: buildTopCategories(catSums),
      recentTransactions: allTxs.take(5).toList(),
    );
    isLoading = false;
    notifyListeners();
  }

  static ({int income, int expense, int invest}) sumsByDivision(
    List<AccountListResponse> accounts,
  ) {
    int income = 0;
    int expense = 0;
    int invest = 0;
    for (final tx in accounts) {
      switch (tx.divisionId) {
        case Division.income:
          income += tx.price;
        case Division.expense:
          expense += tx.price;
        case Division.invest:
          invest += tx.price;
      }
    }
    return (income: income, expense: expense, invest: invest);
  }

  static List<CategoryExpenseItem> buildTopCategories(
    List<CategorySumResponse> sums,
  ) {
    final sorted = [...sums]..sort((a, b) => b.sumPrice.compareTo(a.sumPrice));
    final top = sorted.take(5).toList();
    final total = top.fold(0, (s, e) => s + e.sumPrice);
    if (total == 0) return [];
    return top
        .map((e) => CategoryExpenseItem(
              categoryId: e.categoryId,
              categoryNm: e.categoryNm,
              amount: e.sumPrice,
              ratio: e.sumPrice / total,
            ))
        .toList();
  }

  @override
  void dispose() {
    _shared.removeListener(_onSharedUpdated);
    super.dispose();
  }
}
