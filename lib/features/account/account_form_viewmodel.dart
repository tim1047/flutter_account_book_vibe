import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/category_model.dart';
import 'package:account_book_vibe/data/models/division_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/data/models/payment_model.dart';
import 'package:account_book_vibe/data/services/category_service.dart';
import 'package:account_book_vibe/data/services/division_service.dart';
import 'package:account_book_vibe/data/services/member_service.dart';
import 'package:account_book_vibe/data/services/payment_service.dart';
import 'package:flutter/foundation.dart';

class AccountFormViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<DivisionListResponse> divisions = [];
  List<CategoryListResponse> categories = [];
  List<CategorySeqListResponse> categorySeqs = [];
  List<MemberListResponse> members = [];
  List<PaymentListResponse> payments = [];

  String? selectedDivisionId;
  String? selectedCategoryId;
  String? selectedCategorySeq;
  String? selectedMemberId;
  String? selectedPaymentId;

  bool isCategoriesLoading = false;
  bool isCategorySeqsLoading = false;

  /// 수정 모드: 기존 값을 미리 채워 넣음. 추가 모드: 모든 파라미터 null
  Future<void> init({
    String? divisionId,
    String? memberId,
    String? categoryId,
    String? categorySeq,
    String? paymentId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        DivisionService.instance.getDivisions(),
        MemberService.instance.getMembers(),
      ]);
      divisions = results[0] as List<DivisionListResponse>;
      members = results[1] as List<MemberListResponse>;

      if (divisionId != null && memberId != null) {
        selectedDivisionId = divisionId;
        selectedMemberId = memberId;
        selectedCategoryId = categoryId;
        selectedCategorySeq = categorySeq;
        selectedPaymentId = paymentId;

        await Future.wait([
          _loadCategories(divisionId),
          _loadPayments(memberId),
        ]);
        if (categoryId != null) await _loadCategorySeqs(categoryId);
      }
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onDivisionChanged(String divisionId) async {
    selectedDivisionId = divisionId;
    selectedCategoryId = null;
    selectedCategorySeq = null;
    categories = [];
    categorySeqs = [];
    isCategoriesLoading = true;
    isCategorySeqsLoading = false;
    notifyListeners();
    await _loadCategories(divisionId);
  }

  Future<void> onMemberChanged(String memberId) async {
    selectedMemberId = memberId;
    selectedPaymentId = null;
    payments = [];
    notifyListeners();
    await _loadPayments(memberId);
  }

  Future<void> onCategoryChanged(String categoryId) async {
    selectedCategoryId = categoryId;
    selectedCategorySeq = null;
    categorySeqs = [];
    isCategorySeqsLoading = true;
    notifyListeners();
    await _loadCategorySeqs(categoryId);
  }

  void onCategorySeqChanged(String categorySeq) {
    selectedCategorySeq = categorySeq;
    notifyListeners();
  }

  void onPaymentChanged(String paymentId) {
    selectedPaymentId = paymentId;
    notifyListeners();
  }

  Future<void> _loadCategories(String divisionId) async {
    try {
      categories = await CategoryService.instance
          .getCategories(divisionId: divisionId);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isCategoriesLoading = false;
    }
    notifyListeners();
  }

  Future<void> _loadCategorySeqs(String categoryId) async {
    try {
      categorySeqs =
          await CategoryService.instance.getCategorySeqs(categoryId);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isCategorySeqsLoading = false;
    }
    notifyListeners();
  }

  Future<void> _loadPayments(String memberId) async {
    try {
      payments =
          await PaymentService.instance.getPayments(memberId: memberId);
    } on AppException catch (e) {
      errorMessage = e.message;
    }
    notifyListeners();
  }
}
