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

  testWidgets('trailing이 주어지면 title+subtitle 블록 중앙에 정렬된다', (tester) async {
    // IntrinsicHeight로 감싸 카드가 화면 전체 높이로 늘어나지 않고 콘텐츠
    // 높이만큼만 차지하도록 한다 (실제 앱에서는 ListView 안에서 항상 이렇게
    // 콘텐츠 높이로 렌더된다). 이렇게 해야 trailing의 세로 중앙 정렬 여부를
    // title+subtitle 블록 기준으로 정확히 검증할 수 있다.
    await tester.pumpWidget(
      wrap(
        IntrinsicHeight(
          child: AppListCard(
            title: const Text('제목'),
            subtitle: const Text('부제목'),
            trailing: const Text('10,000원'),
            onTap: () {},
          ),
        ),
      ),
    );

    final titleTop = tester.getTopLeft(find.text('제목')).dy;
    final subtitleBottom = tester.getBottomLeft(find.text('부제목')).dy;
    final trailingCenter = tester.getCenter(find.text('10,000원')).dy;

    expect(trailingCenter, greaterThan(titleTop));
    expect(trailingCenter, lessThan(subtitleBottom));
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
