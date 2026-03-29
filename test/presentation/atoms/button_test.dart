import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/atoms/button.dart';

void main() {
  group('Button Atom Tests', () {
    testWidgets('Button displays with label', (WidgetTester tester) async {
      // 前準備: Buttonを配置
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Button(
              label: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      // 確認: ラベルが表示される
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('Button is clickable', (WidgetTester tester) async {
      // 前準備: クリックイベント用の調査フラグ
      bool isPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Button(
              label: 'Press',
              onPressed: () {
                isPressed = true;
              },
            ),
          ),
        ),
      );

      // 実行: ボタンをタップ
      await tester.tap(find.byType(Button));
      await tester.pumpAndSettle();

      // 確認: コールバックが実行されたか
      expect(isPressed, true);
    });

    testWidgets('Button shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Button(
              label: 'Processing',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // 確認: 読み込み中インジケーターが表示される
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Button disabled when no callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Button(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      // 確認: ボタンが無効状態
      final buttonFinder = find.byType(ElevatedButton);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('Button displays different sizes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Button(
                  label: 'Small',
                  onPressed: () {},
                  size: ButtonSize.small,
                ),
                Button(
                  label: 'Medium',
                  onPressed: () {},
                  size: ButtonSize.medium,
                ),
                Button(
                  label: 'Large',
                  onPressed: () {},
                  size: ButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      );

      // 確認: 3つのボタンが表示される
      expect(find.byType(Button), findsNWidgets(3));
    });

    testWidgets('Button displays primary variant color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Button(
              label: 'Primary',
              onPressed: () {},
              variant: ButtonVariant.primary,
            ),
          ),
        ),
      );

      // 確認: Primary ボタンが表示される
      expect(find.byType(Button), findsOneWidget);
    });
  });
}
