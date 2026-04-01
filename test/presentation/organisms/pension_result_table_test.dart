import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/application/dtos/pension_by_age_data.dart';
import 'package:life_planning/presentation/organisms/pension_result_table.dart';

void main() {
  group('PensionResultTable Tests', () {
    // テスト用のサンプルデータ
    List<PensionByAgeData> createSampleData() {
      return [
        const PensionByAgeData(
          age: 65,
          basicPensionMonthly: 65000,
          occupationalPensionMonthly: 50000,
          idecoMonthly: 30000,
          investmentTrustMonthly: 20000,
          monthlyLivingExpenses: 200000,
        ),
        const PensionByAgeData(
          age: 66,
          basicPensionMonthly: 65000,
          occupationalPensionMonthly: 50000,
          idecoMonthly: 30000,
          investmentTrustMonthly: 20000,
          monthlyLivingExpenses: 200000,
        ),
        const PensionByAgeData(
          age: 67,
          basicPensionMonthly: 65000,
          occupationalPensionMonthly: 50000,
          idecoMonthly: 0,
          investmentTrustMonthly: 20000,
          monthlyLivingExpenses: 200000,
        ),
      ];
    }

    testWidgets('データが空の場合「データがありません」が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: []),
          ),
        ),
      );

      expect(find.text('データがありません'), findsOneWidget);
    });

    testWidgets('年齢列が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: createSampleData()),
          ),
        ),
      );

      expect(find.text('65歳'), findsOneWidget);
      expect(find.text('66歳'), findsOneWidget);
      expect(find.text('67歳'), findsOneWidget);
    });

    testWidgets('月額表示モードでヘッダーに月額と表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: createSampleData()),
          ),
        ),
      );

      expect(find.textContaining('(月額)'), findsWidgets);
    });

    testWidgets('年額表示モードでヘッダーに年額と表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(
              data: createSampleData(),
              showAnnual: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('(年額)'), findsWidgets);
    });

    testWidgets('基礎年金のみの場合、厚生年金列が表示されない',
        (WidgetTester tester) async {
      final data = [
        const PensionByAgeData(
          age: 65,
          basicPensionMonthly: 65000,
          occupationalPensionMonthly: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: data),
          ),
        ),
      );

      expect(find.textContaining('厚生年金'), findsNothing);
    });

    testWidgets('iDeCoがない場合、iDeCo列が表示されない',
        (WidgetTester tester) async {
      final data = [
        const PensionByAgeData(
          age: 65,
          basicPensionMonthly: 65000,
          occupationalPensionMonthly: 50000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: data),
          ),
        ),
      );

      expect(find.textContaining('iDeCo'), findsNothing);
    });

    testWidgets('生活費がある場合、過不足列が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: createSampleData()),
          ),
        ),
      );

      expect(find.textContaining('過不足'), findsOneWidget);
    });

    testWidgets('通貨フォーマットが正しく適用される', (WidgetTester tester) async {
      final data = [
        const PensionByAgeData(
          age: 65,
          basicPensionMonthly: 65000,
          occupationalPensionMonthly: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: data),
          ),
        ),
      );

      // ¥65,000 のフォーマットで表示される
      expect(find.text('¥65,000'), findsWidgets);
    });

    testWidgets('値が0の場合はハイフンで表示される', (WidgetTester tester) async {
      final data = [
        const PensionByAgeData(
          age: 65,
          basicPensionMonthly: 0,
          occupationalPensionMonthly: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PensionResultTable(data: data),
          ),
        ),
      );

      // 0円は「-」で表示される
      expect(find.text('-'), findsWidgets);
    });
  });
}
