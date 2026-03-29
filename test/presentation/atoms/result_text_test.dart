import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/atoms/result_text.dart';

void main() {
  group('ResultText Atom Tests', () {
    testWidgets('ResultText displays label and value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultText(
              label: '年間年金',
              value: '¥840,960',
            ),
          ),
        ),
      );

      // 確認: ラベルと値が表示される
      expect(find.text('年間年金'), findsOneWidget);
      expect(find.text('¥840,960'), findsOneWidget);
    });

    testWidgets('ResultText displays unit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultText(
              label: '月額',
              value: '70,080',
              unit: '円',
            ),
          ),
        ),
      );

      // 確認: 単位が表示される
      expect(find.text('円'), findsOneWidget);
    });

    testWidgets('ResultText respects size variations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ResultText(
                  label: 'Small',
                  value: '100',
                  size: ResultTextSize.small,
                ),
                ResultText(
                  label: 'Medium',
                  value: '500',
                  size: ResultTextSize.medium,
                ),
                ResultText(
                  label: 'Large',
                  value: '1000',
                  size: ResultTextSize.large,
                ),
              ],
            ),
          ),
        ),
      );

      // 確認: 3つのResultTextが表示される
      expect(find.byType(ResultText), findsNWidgets(3));
    });

    testWidgets('ResultText shows highlight style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultText(
              label: 'Important',
              value: '¥5,000,000',
              isHighlight: true,
            ),
          ),
        ),
      );

      // 確認: ハイライト付きResultTextが表示される
      expect(find.byType(ResultText), findsOneWidget);
    });

    testWidgets('ResultText without unit works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultText(
              label: 'Count',
              value: '42',
            ),
          ),
        ),
      );

      // 確認: 値が表示される
      expect(find.text('42'), findsOneWidget);
      // 確認: 単位がない
      expect(find.byType(ResultText), findsOneWidget);
    });
  });
}
