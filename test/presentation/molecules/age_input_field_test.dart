import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/molecules/age_input_field.dart';

void main() {
  group('AgeInputField Molecule Tests', () {
    testWidgets('AgeInputField displays label and hint',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              label: '現在の年齢',
              hintText: '例: 35',
            ),
          ),
        ),
      );

      // 確認: ラベルが表示される
      expect(find.text('現在の年齢'), findsOneWidget);
      // 確認: ヒントが表示される
      expect(find.text('例: 35'), findsOneWidget);
    });

    testWidgets('AgeInputField accepts valid age range',
        (WidgetTester tester) async {
      int? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      );

      // 実行: 有効な年齢を入力（30歳）
      await tester.enterText(find.byType(TextField), '30');
      await tester.pumpAndSettle();

      // 確認: 値が有効に解析される
      expect(lastValue, 30);
    });

    testWidgets('AgeInputField rejects invalid age (over 120)',
        (WidgetTester tester) async {
      int? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      );

      // 実行: 無効な年齢を入力（121歳）
      await tester.enterText(find.byType(TextField), '121');
      await tester.pumpAndSettle();

      // 確認: エラーが表示される
      expect(find.text('0～120の範囲で入力してください'), findsOneWidget);
      // 確認: コールバックで null が返される
      expect(lastValue, isNull);
    });

    testWidgets('AgeInputField rejects negative age',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              onChanged: (value) {},
            ),
          ),
        ),
      );

      // 実行: 負の値を入力
      await tester.enterText(find.byType(TextField), '-5');
      await tester.pumpAndSettle();

      // 確認: エラーが表示される
      expect(find.text('0～120の範囲で入力してください'), findsOneWidget);
    });

    testWidgets('AgeInputField rejects non-numeric input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              onChanged: (value) {},
            ),
          ),
        ),
      );

      // 実行: 数字以外を入力
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      // 確認: エラーが表示される
      expect(find.text('整数で入力してください'), findsOneWidget);
    });

    testWidgets('AgeInputField clears error on valid input',
        (WidgetTester tester) async {
      int? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      );

      // 実行: 最初は無効な値
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      // 確認: エラーが表示される
      expect(find.text('整数で入力してください'), findsOneWidget);

      // 実行: テキストをクリアして有効な値を入力
      await tester.enterText(find.byType(TextField), '40');
      await tester.pumpAndSettle();

      // 確認: エラーが消える
      expect(find.text('整数で入力してください'), findsNothing);
      // 確認: 値が有効に解析される
      expect(lastValue, 40);
    });

    testWidgets('AgeInputField allows empty input',
        (WidgetTester tester) async {
      int? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeInputField(
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      );

      // 実行: テキストをクリア
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // 確認: null が返される
      expect(lastValue, isNull);
      // 確認: エラーがない
      expect(find.text('整数で入力してください'), findsNothing);
    });
  });
}
