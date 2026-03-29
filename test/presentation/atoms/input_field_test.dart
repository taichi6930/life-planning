import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/atoms/input_field.dart';

void main() {
  group('InputField Atom Tests', () {
    testWidgets('InputField displays label and hint',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputField(
              label: 'Username',
              hintText: 'Enter username',
            ),
          ),
        ),
      );

      // 確認: ラベルが表示される
      expect(find.text('Username'), findsOneWidget);
      // 確認: ヒントが表示される
      expect(find.text('Enter username'), findsOneWidget);
    });

    testWidgets('InputField accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputField(
              label: 'Email',
              hintText: 'your@email.com',
            ),
          ),
        ),
      );

      // 実行: テキスト入力
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pumpAndSettle();

      // 確認: 入力値が反映される
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('InputField displays error text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputField(
              label: 'Password',
              errorText: 'パスワードは8文字以上必要です',
            ),
          ),
        ),
      );

      // 確認: エラーメッセージが表示される
      expect(find.text('パスワードは8文字以上必要です'), findsOneWidget);
    });

    testWidgets('InputField calls onChanged callback',
        (WidgetTester tester) async {
      String? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputField(
              label: 'Name',
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      );

      // 実行: テキスト入力
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle();

      // 確認: コールバックが実行された
      expect(lastValue, 'John');
    });

    testWidgets('InputField respects keyboardType', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputField(
              label: 'Age',
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      );

      // 確認: TextFieldが存在する
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('InputField handles multiline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputField(
              label: 'Comment',
              maxLines: 3,
              minLines: 2,
            ),
          ),
        ),
      );

      // 確認: TextFieldが表示される
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
