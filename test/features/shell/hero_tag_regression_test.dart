// Regression test for a Hero tag collision that occurs because
// `StatefulShellRoute.indexedStack` (see lib/core/router/app_router.dart)
// keeps every branch mounted simultaneously. `AccountListScreen` is the root
// of the "list" branch (`/accountList`) but is also pushed on top of OTHER
// branches (e.g. from AnalysisScreen's category/member rows, via
// `context.push('/accountList', extra: ...)`). If `AccountListScreen`'s FAB
// hero tags are constant string literals, two live instances of the screen
// end up sharing the same Hero tag, and Flutter throws:
// "There are multiple heroes that share the same tag within a subtree."
//
// This test drives the REAL app router to reproduce the exact navigation
// sequence that triggers the collision:
//   go /accountList (mounts branch 0 root)
//   -> go /analysis (switches active branch; branch 0 stays mounted)
//   -> push /accountList with extra (mounts a SECOND AccountListScreen)
//   -> push /account (forces Flutter to resolve all live Hero tags)
//
// Before the fix (constant `heroTag: 'addAccount'` / `'scrollTop'`), this
// test fails with a Hero tag collision assertion. After the fix (instance
// unique hero tags), it passes.
import 'package:account_book_vibe/core/router/app_router.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'no Hero tag collision when AccountListScreen is mounted twice '
    'across shell branches (list branch root + pushed from analysis branch)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Mount the "list" branch's root AccountListScreen.
      appRouter.go('/accountList');
      await tester.pumpAndSettle();

      // Switch to the "analysis" branch. The list branch (and its
      // AccountListScreen instance) stays mounted via indexedStack.
      appRouter.go('/analysis');
      await tester.pumpAndSettle();

      // Simulate tapping a category/member row in AnalysisScreen, which
      // pushes a SECOND AccountListScreen instance on top of the analysis
      // branch.
      appRouter.push<void>(
        '/accountList',
        extra: const AccountListExtra(divisionId: 'EXP'),
      );
      await tester.pumpAndSettle();

      // Push another screen with its own FAB. This forces Flutter to
      // resolve/search Hero tags for the transition, which is where the
      // collision previously surfaced.
      appRouter.push<String>('/account');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
