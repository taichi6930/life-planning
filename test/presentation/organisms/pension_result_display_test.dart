import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/pension_result.dart';
import 'package:life_planning/presentation/organisms/pension_result_display.dart';

void main() {
  /// テスト用の PensionResult を生成するヘルパー
  PensionResult makeResult({
    double basicPensionMonthly = 65000,
    double occupationalPensionMonthly = 0,
    double idecoMonthly = 0,
    double monthlyLivingExpenses = 0,
    double idecoFutureValue = 0,
  }) {
    return PensionResult(
      basicPensionMonthly: basicPensionMonthly,
      basicPensionAnnual: basicPensionMonthly * 12,
      occupationalPensionMonthly: occupationalPensionMonthly,
      occupationalPensionAnnual: occupationalPensionMonthly * 12,
      idecoMonthly: idecoMonthly,
      idecoAnnual: idecoMonthly * 12,
      monthlyLivingExpenses: monthlyLivingExpenses,
      idecoFutureValue: idecoFutureValue,
      totalPensionMonthly: basicPensionMonthly + occupationalPensionMonthly + idecoMonthly,
      totalPensionAnnual: (basicPensionMonthly + occupationalPensionMonthly + idecoMonthly) * 12,
      adjustmentRate: 1.0,
      pensionStartAge: 65,
    );
  }

  /// テスト用ウィジェットを生成するヘルパー
  Widget buildTestWidget(PensionResultDisplay widget) {
    return MaterialApp(
      home: Scaffold(body: widget),
    );
  }

  group('PensionResultDisplay Organism Tests', () {
    /// デシジョンテーブル: 表示状態
    ///
    /// | # | isLoading | result | occPension>0 | 期待結果                |
    /// |---|-----------|--------|-------------|------------------------|
    /// | 1 | true      | any    | any         | CircularProgressIndicator |
    /// | 2 | false     | null   | -           | プロンプトテキスト         |
    /// | 3 | false     | あり   | false       | 基礎年金のみ             |
    /// | 4 | false     | あり   | true        | 基礎+厚生+合計           |

    testWidgets('ケース1: ローディング中はインジケータが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PensionResultDisplay(isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ケース2: 結果なしでプロンプトテキストが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PensionResultDisplay(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('フォームを入力して「計算する」ボタンを押してください'), findsOneWidget);
    });

    testWidgets('ケース3: 基礎年金のみの結果が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        PensionResultDisplay(
          result: makeResult(basicPensionMonthly: 65000),
          currentAge: 35,
          paymentMonths: 360,
        ),
      ));
      await tester.pumpAndSettle();

      // 基礎年金計算結果カードが表示される
      expect(find.text('基礎年金計算結果'), findsOneWidget);
      // 計算条件カードが表示される
      expect(find.text('計算条件'), findsOneWidget);
      // 納付状況カードが表示される
      expect(find.text('納付状況'), findsOneWidget);
    });

    testWidgets('ケース4: 厚生年金含む結果が表示される（基礎+厚生+合計）', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        PensionResultDisplay(
          result: makeResult(
            basicPensionMonthly: 65000,
            occupationalPensionMonthly: 80000,
          ),
          currentAge: 35,
          paymentMonths: 360,
          occupationalPaymentMonths: 240,
        ),
      ));
      await tester.pumpAndSettle();

      // 3つの結果カードが表示される
      expect(find.text('基礎年金計算結果'), findsOneWidget);
      expect(find.text('厚生年金計算結果'), findsOneWidget);
      expect(find.text('合計年金額'), findsOneWidget);
      // 条件と納付状況
      expect(find.text('計算条件'), findsOneWidget);
      expect(find.text('納付状況'), findsOneWidget);
    });

    testWidgets('計算条件に現在の年齢と納付月数が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        PensionResultDisplay(
          result: makeResult(basicPensionMonthly: 65000),
          currentAge: 40,
          paymentMonths: 300,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('40歳'), findsOneWidget);
      expect(find.text('300ヶ月'), findsOneWidget);
    });

    testWidgets('納付率が正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        PensionResultDisplay(
          result: makeResult(basicPensionMonthly: 65000),
          contributionRate: 1.0, // 480/480 = 100.0%
        ),
      ));
      await tester.pumpAndSettle();

      // 480/480 = 100.0%
      expect(find.text('100.0%'), findsOneWidget);
    });
  });
}
