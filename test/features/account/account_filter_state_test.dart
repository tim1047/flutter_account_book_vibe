import 'package:account_book_vibe/features/account/account_list_filter_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountFilterState', () {
    test('기본값은 isActive = false', () {
      const state = AccountFilterState();
      expect(state.isActive, false);
    });

    test('divisionIds 있으면 isActive = true', () {
      const state = AccountFilterState(divisionIds: {'1'});
      expect(state.isActive, true);
    });

    test('searchText 있으면 isActive = true', () {
      const state = AccountFilterState(searchText: '식비');
      expect(state.isActive, true);
    });

    test('activeCount: 활성 그룹 수 반환', () {
      const state = AccountFilterState(
        divisionIds: {'1'},
        categoryIds: {'C1'},
        searchText: '식비',
      );
      expect(state.activeCount, 3);
    });

    test('activeCount: 빈 상태는 0', () {
      const state = AccountFilterState();
      expect(state.activeCount, 0);
    });

    test('copyWith: 지정 필드만 교체, 나머지 보존', () {
      const original = AccountFilterState(
        divisionIds: {'1'},
        categoryIds: {'C1'},
      );
      final updated = original.copyWith(searchText: '테스트');
      expect(updated.divisionIds, {'1'});
      expect(updated.categoryIds, {'C1'});
      expect(updated.searchText, '테스트');
    });

    test('cleared: 빈 상태 반환', () {
      const state = AccountFilterState(
        divisionIds: {'1'},
        searchText: '식비',
      );
      final result = state.cleared;
      expect(result.isActive, false);
      expect(result.divisionIds, isEmpty);
      expect(result.searchText, '');
    });
  });
}
