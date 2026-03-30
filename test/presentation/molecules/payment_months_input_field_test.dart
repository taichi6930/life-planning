import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/molecules/payment_months_input_field.dart';

void main() {
  Widget buildTestWidget({
    String label = '年金納付月数',
    String? hintText = '例: 360',
    Function(int?)? onChanged,
    TextEditingController? controller,
    int maxMonths = 480,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PaymentMonthsInputField(
          label: label,
          hintText: hintText,
          onChanged: onChanged,
          controller: controller,
          maxMonths: maxMonths,
        ),
      ),
    );
  }

  group('PaymentMonthsInputField Molecule Tests', () {
    /// デシジョンテーブル: 入力値とバリデーション
    ///
    /// | # | 入力値  | 期待結果                         |
    /// |---|--------|--------------------------------|
    /// | 1 | ''     | エラーなし、onChanged(null)       |
    /// | 2 | '360'  | エラーなし、onChanged(360)        |
    /// | 3 | '0'    | エラーなし、onChanged(0)          |
    /// | 4 | '480'  | エラーなし、onChanged(480)        |
    /// | 5 | '-1'   | エラー表示、onChanged(null)       |
    /// | 6 | '481'  | エラー表示、onChanged(null)       |
    /// | 7 | 'abc'  | エラー表示、onChanged(null)       |

    testWidgets('ケース1: 空文字入力でエラーなし', (WidgetTester tester) async {
      int? lastValue = 999;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) {
          lastValue = v;
        },
      ));

      // 一旦有効値を入力してから空にする
      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();
      expect(lastValue, 100);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(lastValue, isNull);
      // エラーは表示されない
      expect(find.text('整数で入力してください'), findsNothing);
      expect(find.textContaining('範囲で入力してください'), findsNothing);
    });

    testWidgets('ケース2: 有効な値360でエラーなし', (WidgetTester tester) async {
      int? lastValue;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) => lastValue = v,
      ));

      await tester.enterText(find.byType(TextField), '360');
      await tester.pumpAndSettle();

      expect(lastValue, 360);
    });

    testWidgets('ケース3: 境界値0でエラーなし', (WidgetTester tester) async {
      int? lastValue;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) => lastValue = v,
      ));

      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();

      expect(lastValue, 0);
    });

    testWidgets('ケース4: 境界値480でエラーなし', (WidgetTester tester) async {
      int? lastValue;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) => lastValue = v,
      ));

      await tester.enterText(find.byType(TextField), '480');
      await tester.pumpAndSettle();

      expect(lastValue, 480);
    });

    testWidgets('ケース5: 負の値でエラー表示', (WidgetTester tester) async {
      int? lastValue;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) => lastValue = v,
      ));

      await tester.enterText(find.byType(TextField), '-1');
      await tester.pumpAndSettle();

      expect(find.text('0～480の範囲で入力してください'), findsOneWidget);
      expect(lastValue, isNull);
    });

    testWidgets('ケース6: 上限超過でエラー表示', (WidgetTester tester) async {
      int? lastValue;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) => lastValue = v,
      ));

      await tester.enterText(find.byType(TextField), '481');
      await tester.pumpAndSettle();

      expect(find.text('0～480の範囲で入力してください'), findsOneWidget);
      expect(lastValue, isNull);
    });

    testWidgets('ケース7: 非数値でエラー表示', (WidgetTester tester) async {
      int? lastValue;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (v) => lastValue = v,
      ));

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      expect(find.text('整数で入力してください'), findsOneWidget);
      expect(lastValue, isNull);
    });

    testWidgets('外部コントローラーが使用される', (WidgetTester tester) async {
      final controller = TextEditingController(text: '200');
      await tester.pumpWidget(buildTestWidget(controller: controller));

      expect(find.text('200'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('maxMonths カスタム値で範囲エラーが変わる', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(maxMonths: 300));

      await tester.enterText(find.byType(TextField), '301');
      await tester.pumpAndSettle();

      expect(find.text('0～300の範囲で入力してください'), findsOneWidget);
    });

    testWidgets('ラベルとヒントが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: 'カスタムラベル',
        hintText: 'カスタムヒント',
      ));

      expect(find.text('カスタムラベル'), findsOneWidget);
      expect(find.text('カスタムヒント'), findsOneWidget);
    });
  });
}
