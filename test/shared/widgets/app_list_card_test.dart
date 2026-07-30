import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('leading/subtitle/badges/trailing 없이도 title만으로 렌더된다', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목만'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('제목만'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leading이 주어지면 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          leading: const Icon(Icons.person),
          title: const Text('제목'),
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('trailing이 주어지면 title 옆에 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          trailing: const Text('10,000원'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('10,000원'), findsOneWidget);
  });

  testWidgets('badges가 비어있으면 Wrap을 렌더하지 않는다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('badges가 있으면 Wrap 안에 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          badges: const [Text('뱃지1'), Text('뱃지2')],
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.text('뱃지1'), findsOneWidget);
    expect(find.text('뱃지2'), findsOneWidget);
  });

  testWidgets('onTap과 onLongPress가 호출된다', (tester) async {
    var tapped = false;
    var longPressed = false;

    await tester.pumpWidget(
      wrap(
        AppListCard(
          title: const Text('제목'),
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );

    await tester.tap(find.byType(AppListCard));
    expect(tapped, isTrue);

    await tester.longPress(find.byType(AppListCard));
    expect(longPressed, isTrue);
  });
}
