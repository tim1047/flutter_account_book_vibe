import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showMenuButton: false면 메뉴 아이콘이 렌더되지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: MainAppBar(showMenuButton: false)),
      ),
    );

    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('showMenuButton 생략(기본값 true)이면 메뉴 아이콘이 렌더된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: MainAppBar()),
      ),
    );

    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
