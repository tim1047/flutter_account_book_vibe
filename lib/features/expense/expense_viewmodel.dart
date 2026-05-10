import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/data/services/member_service.dart';
import 'package:flutter/foundation.dart';

class ExpenseViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<CategorySumResponse> categorySumList = [];
  List<CategorySeqSumResponse> categorySeqSumList = [];
  List<MemberSumResponse> memberSumList = [];

  Future<void> loadCategorySum(String strtDt, String endDt) async {
    _begin();
    try {
      categorySumList = await CategoryService.instance.getCategorySum(
        divisionId: Division.expense,
        strtDt: strtDt,
        endDt: endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  Future<void> loadCategorySeqSum(String strtDt, String endDt) async {
    _begin();
    try {
      categorySeqSumList = await CategoryService.instance.getCategorySeqSum(
        divisionId: Division.expense,
        strtDt: strtDt,
        endDt: endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  Future<void> loadMemberSum(String strtDt, String endDt) async {
    _begin();
    try {
      memberSumList = await MemberService.instance.getMemberSum(
        divisionId: Division.expense,
        strtDt: strtDt,
        endDt: endDt,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      _end();
    }
  }

  void _begin() {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
  }

  void _end() {
    isLoading = false;
    notifyListeners();
  }
}
