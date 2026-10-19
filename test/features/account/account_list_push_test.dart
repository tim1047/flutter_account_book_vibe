import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/account/account_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  // 목록 탭 루트 화면이 살아 있는 상태에서 다른 탭이 AccountListScreen을 push해도
  // 날짜 필터가 공유되지 않아 "setState() called during build"가 나지 않아야 한다.
  testWidgets('pushing AccountListScreen from another branch does not throw',
      (tester) async {
    final router = GoRouter(initialLocation: '/accountList', routes: [
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accountList',
              builder: (c, s) =>
                  AccountListScreen(extra: s.extra as AccountListExtra?),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/analysis',
              builder: (c, s) => TextButton(
                onPressed: () => c.push(
                  '/accountList',
                  extra: AccountListExtra(
                      categoryId: '10', year: DateTime.now().year, month: 1),
                ),
                child: const Text('go'),
              ),
            ),
          ]),
        ],
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.go('/analysis');
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
