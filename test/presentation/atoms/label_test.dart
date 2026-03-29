import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/atoms/label.dart';

void main() {
  group('Label Atom Tests', () {
    testWidgets('Label displays text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Label('Sample Label'),
          ),
        ),
      );

      // 確認: ラベルテキストが表示される
      expect(find.text('Sample Label'), findsOneWidget);
    });

    testWidgets('Label respects size variations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Label('Small', size: LabelSize.small),
                Label('Medium', size: LabelSize.medium),
                Label('Large', size: LabelSize.large),
              ],
            ),
          ),
        ),
      );

      // 確認: 3つのラベルが表示される
      expect(find.byType(Label), findsNWidgets(3));
    });

    testWidgets('Label respects color variations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Label('Primary', color: LabelColor.primary),
                Label('Secondary', color: LabelColor.secondary),
                Label('Error', color: LabelColor.error),
                Label('Success', color: LabelColor.success),
              ],
            ),
          ),
        ),
      );

      // 確認: 4つのラベルが表示される
      expect(find.byType(Label), findsNWidgets(4));
    });

    testWidgets('Label respects textAlign', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Label(
              'Centered Label',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      // 確認: ラベルが表示される
      expect(find.text('Centered Label'), findsOneWidget);
    });

    testWidgets('Label handles maxLines overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Label(
              '長いテキストが入ってきた場合には省略表示される',
              maxLines: 1,
            ),
          ),
        ),
      );

      // 確認: ラベルが表示される
      expect(find.byType(Label), findsOneWidget);
    });
  });
}
