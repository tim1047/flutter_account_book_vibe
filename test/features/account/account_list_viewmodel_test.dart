import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/features/account/account_list_filter_state.dart';
import 'package:account_book_vibe/features/account/account_list_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

AccountListResponse _item({
  required int accountId,
  required String accountDt,
  required String divisionId,
  required String divisionNm,
  required String memberId,
  required String memberNm,
  required String categoryId,
  required String categoryNm,
  required String categorySeq,
  required String categorySeqNm,
  String? remark,
}) =>
    AccountListResponse(
      seq: 0,
      accountId: accountId,
      accountDt: accountDt,
      divisionId: divisionId,
      divisionNm: divisionNm,
      memberId: memberId,
      memberNm: memberNm,
      paymentId: 'P1',
      paymentNm: '신한',
      paymentType: 'CARD',
      categoryId: categoryId,
      categoryNm: categoryNm,
      categorySeq: categorySeq,
      categorySeqNm: categorySeqNm,
      price: 10000,
      remark: remark,
      impulseYn: 'N',
      pointPrice: 0,
    );

void main() {
  late AccountListViewModel vm;

  final itemA = _item(
    accountId: 1,
    accountDt: '2026-05-01',
    divisionId: '3',
    divisionNm: '지출',
    memberId: 'M1',
    memberNm: '강원',
    categoryId: 'C1',
    categoryNm: '식비',
    categorySeq: 'S1',
    categorySeqNm: '외식',
    remark: '점심',
  );

  final itemB = _item(
    accountId: 2,
    accountDt: '2026-05-02',
    divisionId: '1',
    divisionNm: '수입',
    memberId: 'M2',
    memberNm: '정윤',
    categoryId: 'C2',
    categoryNm: '급여',
    categorySeq: 'S2',
    categorySeqNm: '월급',
  );

  final itemC = _item(
    accountId: 3,
    accountDt: '2026-05-01',
    divisionId: '3',
    divisionNm: '지출',
    memberId: 'M1',
    memberNm: '강원',
    categoryId: 'C1',
    categoryNm: '식비',
    categorySeq: 'S3',
    categorySeqNm: '카페',
    remark: '아메리카노',
  );

  setUp(() {
    vm = AccountListViewModel();
    vm.setItemsForTest([itemA, itemB, itemC]);
  });

  tearDown(() => vm.dispose());

  group('filteredGrouped', () {
    test('필터 없으면 전체 반환', () {
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 3);
    });

    test('divisionId 필터: 지출만', () {
      vm.updateFilter(const AccountFilterState(divisionIds: {'3'}));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 2);
      expect(
        result.values.expand((e) => e).every((e) => e.divisionId == '3'),
        true,
      );
    });

    test('categoryId 필터: 식비만', () {
      vm.updateFilter(const AccountFilterState(categoryIds: {'C1'}));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 2);
    });

    test('memberId 필터: 강원만', () {
      vm.updateFilter(const AccountFilterState(memberIds: {'M1'}));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 2);
    });

    test('searchText: categoryNm contains (대소문자 무시)', () {
      vm.updateFilter(const AccountFilterState(searchText: '식비'));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 2);
    });

    test('searchText: remark contains', () {
      vm.updateFilter(const AccountFilterState(searchText: '점심'));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 1);
      expect(result.values.first.first.accountId, 1);
    });

    test('searchText: categorySeqNm contains', () {
      vm.updateFilter(const AccountFilterState(searchText: '카페'));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 1);
      expect(result.values.first.first.accountId, 3);
    });

    test('복합 필터: divisionId + searchText', () {
      vm.updateFilter(const AccountFilterState(
        divisionIds: {'3'},
        searchText: '카페',
      ));
      final result = vm.filteredGrouped;
      expect(result.values.expand((e) => e).length, 1);
    });

    test('날짜별 그룹핑: 같은 날짜는 같은 키로 묶임', () {
      final result = vm.filteredGrouped;
      expect(result['2026-05-01']?.length, 2);
      expect(result['2026-05-02']?.length, 1);
    });
  });

  group('availableDivisions', () {
    test('데이터에서 고유 구분 추출', () {
      final result = vm.availableDivisions;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'1', '3'});
    });
  });

  group('availableCategories', () {
    test('데이터에서 고유 카테고리 추출', () {
      final result = vm.availableCategories;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'C1', 'C2'});
    });
  });

  group('availableCategorySeqs', () {
    test('카테고리 선택 없으면 빈 리스트', () {
      expect(vm.availableCategorySeqs, isEmpty);
    });

    test('카테고리 선택 시 해당 카테고리의 상세만 반환', () {
      vm.updateFilter(const AccountFilterState(categoryIds: {'C1'}));
      final result = vm.availableCategorySeqs;
      expect(result.length, 2);
      expect(result.map((e) => e.seq).toSet(), {'S1', 'S3'});
    });

    test('다른 카테고리 상세는 포함되지 않음', () {
      vm.updateFilter(const AccountFilterState(categoryIds: {'C2'}));
      final result = vm.availableCategorySeqs;
      expect(result.length, 1);
      expect(result.first.seq, 'S2');
    });
  });

  group('availableMembers', () {
    test('데이터에서 고유 멤버 추출', () {
      final result = vm.availableMembers;
      expect(result.length, 2);
      expect(result.map((e) => e.id).toSet(), {'M1', 'M2'});
    });
  });

  group('updateFilter', () {
    test('카테고리 선택 해제 시 해당 카테고리의 상세 선택 자동 제거', () {
      vm.updateFilter(const AccountFilterState(
        categoryIds: {'C1'},
        categorySeqs: {'S1', 'S3'},
      ));
      vm.updateFilter(const AccountFilterState(
        categoryIds: {},
        categorySeqs: {'S1', 'S3'},
      ));
      expect(vm.filterState.categorySeqs, isEmpty);
    });

    test('다른 카테고리로 교체 시 기존 카테고리 상세만 제거', () {
      vm.updateFilter(const AccountFilterState(
        categoryIds: {'C1'},
        categorySeqs: {'S1'},
      ));
      vm.updateFilter(const AccountFilterState(
        categoryIds: {'C2'},
        categorySeqs: {'S1', 'S2'},
      ));
      expect(vm.filterState.categorySeqs, {'S2'});
    });
  });

  group('clearFilter', () {
    test('모든 필터 초기화', () {
      vm.updateFilter(const AccountFilterState(
        divisionIds: {'3'},
        searchText: '식비',
      ));
      vm.clearFilter();
      expect(vm.filterState.isActive, false);
    });
  });

  group('deleteAccount', () {
    test('삭제 후 _rawItems에서 해당 항목 제거', () async {
      vm.setItemsForTest(
        vm.filteredGrouped.values.expand((e) => e)
            .where((e) => e.accountId != 1)
            .toList(),
      );
      expect(
        vm.filteredGrouped.values.expand((e) => e)
            .any((e) => e.accountId == 1),
        false,
      );
    });
  });
}
