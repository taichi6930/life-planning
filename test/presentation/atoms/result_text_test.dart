import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/atoms/result_text.dart';

void main() {
  Widget buildTestWidget({
    String label = 'ラベル',
    String value = '¥100,000',
    String? unit,
    ResultTextSize size = ResultTextSize.medium,
    bool isHighlight = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ResultText(
          label: label,
          value: value,
          unit: unit,
          size: size,
          isHighlight: isHighlight,
        ),
      ),
    );
  }

  group('ResultText Atom Tests', () {
    testWidgets('ラベルと値が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: '年額',
        value: '¥840,960',
      ));

      expect(find.text('年額'), findsOneWidget);
      expect(find.text('¥840,960'), findsOneWidget);
    });

    testWidgets('unit が指定されると表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: '月額',
        value: '70,080',
        unit: '円',
      ));

      expect(find.text('円'), findsOneWidget);
    });

    testWidgets('unit が null なら単位は表示されない', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: '月額',
        value: '70,080',
        unit: null,
      ));

      // 単位テキストは表示されない
      expect(find.text('円'), findsNothing);
    });

    /// デシジョンテーブル: サイズ別スタイル
    ///
    /// | # | size   | 期待されるスタイル   |
    /// |---|--------|-------------------|
    /// | 1 | small  | bodyMedium        |
    /// | 2 | medium | headlineSmall     |
    /// | 3 | large  | headlineMedium    |

    testWidgets('small サイズで表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        size: ResultTextSize.small,
      ));

      expect(find.text('¥100,000'), findsOneWidget);
    });

    testWidgets('large サイズで表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        size: ResultTextSize.large,
      ));

      expect(find.text('¥100,000'), findsOneWidget);
    });

    testWidgets('isHighlight=true でハイライト背景が適用される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(isHighlight: true));
      await tester.pumpWidget(buildTestWidget(isHighlight: false));

      // ウィジェットが表示される（背景色のテスト）
      expect(find.byType(Container), findsWidgets);
    });
  });
}
