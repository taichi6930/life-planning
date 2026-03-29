import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/molecules/result_card.dart';

void main() {
  group('ResultCard Molecule Tests', () {
    testWidgets('ResultCard displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: '計算結果',
              results: {
                '年額': '¥840,960',
              },
            ),
          ),
        ),
      );

      // 確認: タイトルが表示される
      expect(find.text('計算結果'), findsOneWidget);
    });

    testWidgets('ResultCard displays results', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: '基礎年金',
              results: {
                '年額': '¥840,960',
                '月額': '¥70,080',
              },
            ),
          ),
        ),
      );

      // 確認: 結果が表示される
      expect(find.text('年額'), findsOneWidget);
      expect(find.text('¥840,960'), findsOneWidget);
      expect(find.text('月額'), findsOneWidget);
      expect(find.text('¥70,080'), findsOneWidget);
    });

    testWidgets('ResultCard displays units', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: '年金計算',
              results: {
                '年額': '840,960',
              },
              units: {
                '年額': '円',
              },
            ),
          ),
        ),
      );

      // 確認: 単位が表示される
      expect(find.text('円'), findsOneWidget);
    });

    testWidgets('ResultCard shows highlight style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: '重要な結果',
              results: {
                'Total': '¥5,000,000',
              },
              isHighlight: true,
            ),
          ),
        ),
      );

      // 確認: Cardが表示される
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('ResultCard displays multiple items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: '詳細',
              results: {
                'Item1': 'Value1',
                'Item2': 'Value2',
                'Item3': 'Value3',
              },
            ),
          ),
        ),
      );

      // 確認: 全てのアイテムが表示される
      expect(find.text('Item1'), findsOneWidget);
      expect(find.text('Item2'), findsOneWidget);
      expect(find.text('Item3'), findsOneWidget);
    });
  });
}
