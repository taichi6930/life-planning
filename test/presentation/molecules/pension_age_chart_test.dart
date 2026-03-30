import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/application/dtos/pension_by_age_data.dart';
import 'package:life_planning/presentation/molecules/pension_age_chart.dart';

void main() {
  Widget buildTestWidget({
    List<PensionByAgeData>? data,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PensionAgeChart(
            data: data,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  /// テスト用チャートデータを生成（60〜100歳、70歳から受給開始）
  List<PensionByAgeData> createTestChartData({
    double basicMonthly = 50000,
    double occupationalMonthly = 0,
    int startAge = 65,
  }) {
    return List.generate(41, (i) {
      final age = 60 + i;
      final isReceiving = age >= startAge;
      return PensionByAgeData(
        age: age,
        basicPensionMonthly: isReceiving ? basicMonthly : 0,
        occupationalPensionMonthly: isReceiving ? occupationalMonthly : 0,
      );
    });
  }

  group('PensionAgeChart Molecule Tests', () {
    /// デシジョンテーブル: 表示状態
    ///
    /// | # | isLoading | data   | 期待結果                     |
    /// |---|-----------|--------|----------------------------|
    /// | 1 | true      | any    | CircularProgressIndicator  |
    /// | 2 | false     | null   | プロンプトテキスト             |
    /// | 3 | false     | []     | プロンプトテキスト             |
    /// | 4 | false     | [...]  | グラフ表示                   |

    testWidgets('ケース1: ローディング中はインジケータが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ケース2: data=null でプロンプトテキストが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(data: null));

      expect(find.text('グラフを表示するために計算してください'), findsOneWidget);
    });

    testWidgets('ケース3: data=空リストでプロンプトテキストが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(data: []));

      expect(find.text('グラフを表示するために計算してください'), findsOneWidget);
    });

    testWidgets('ケース4: データありでグラフとタイトルが表示される', (WidgetTester tester) async {
      final data = createTestChartData();
      await tester.pumpWidget(buildTestWidget(data: data));

      // タイトルが表示される
      expect(find.text('生涯年金額の推移（年額）'), findsOneWidget);
      // 説明テキストが表示される
      expect(find.text('60歳からの年金額を表示します（受給開始年齢前は0円）'), findsOneWidget);
      // BarChart が表示される
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('レジェンドが表示される', (WidgetTester tester) async {
      final data = createTestChartData();
      await tester.pumpWidget(buildTestWidget(data: data));

      expect(find.text('基礎年金'), findsOneWidget);
      expect(find.text('厚生年金'), findsOneWidget);
    });

    testWidgets('注釈テキストが表示される', (WidgetTester tester) async {
      final data = createTestChartData();
      await tester.pumpWidget(buildTestWidget(data: data));

      expect(find.text('※ グラフは各年齢で受給開始した場合の年額を表示します'), findsOneWidget);
    });

    testWidgets('厚生年金あり＋基礎年金ありのデータでもグラフが表示される', (WidgetTester tester) async {
      final data = createTestChartData(
        basicMonthly: 60000,
        occupationalMonthly: 80000,
        startAge: 70,
      );
      await tester.pumpWidget(buildTestWidget(data: data));

      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}
