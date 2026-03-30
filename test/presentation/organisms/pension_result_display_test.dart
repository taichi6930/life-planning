import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/organisms/pension_result_display.dart';
import 'package:life_planning/presentation/providers/pension_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  /// ProviderScope 付きテストウィジェットを生成する
  Widget buildTestWidget({
    bool isLoading = false,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: PensionResultDisplay(isLoading: isLoading),
        ),
      ),
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
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ケース2: 結果なしでプロンプトテキストが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('フォームを入力して「計算する」ボタンを押してください'), findsOneWidget);
    });

    testWidgets('ケース3: 基礎年金のみの結果が表示される', (WidgetTester tester) async {
      // 計算を実行して結果を設定
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  // テスト用にNotifierに値を設定
                  return Builder(
                    builder: (context) {
                      return const PensionResultDisplay(isLoading: false);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 先にNotifierに値を設定
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PensionResultDisplay)),
      );
      final notifier = container.read(pensionFormNotifierProvider.notifier);
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);
      await notifier.calculatePension();
      await tester.pumpAndSettle();

      // 基礎年金計算結果カードが表示される
      expect(find.text('基礎年金計算結果'), findsOneWidget);
      // 計算条件カードが表示される
      expect(find.text('計算条件'), findsOneWidget);
      // 納付状況カードが表示される
      expect(find.text('納付状況'), findsOneWidget);
    });

    testWidgets('ケース4: 厚生年金含む結果が表示される（基礎+厚生+合計）', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PensionResultDisplay(isLoading: false),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PensionResultDisplay)),
      );
      final notifier = container.read(pensionFormNotifierProvider.notifier);
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);
      notifier.setOccupationalPaymentMonths(240);
      notifier.setMonthlySalary(300000);
      notifier.setBonus(500000);
      await notifier.calculatePension();
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
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PensionResultDisplay(isLoading: false),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PensionResultDisplay)),
      );
      final notifier = container.read(pensionFormNotifierProvider.notifier);
      notifier.setCurrentAge(40);
      notifier.setPaymentMonths(300);
      await notifier.calculatePension();
      await tester.pumpAndSettle();

      expect(find.text('40歳'), findsOneWidget);
      expect(find.text('300ヶ月'), findsOneWidget);
    });

    testWidgets('納付率が正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PensionResultDisplay(isLoading: false),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PensionResultDisplay)),
      );
      final notifier = container.read(pensionFormNotifierProvider.notifier);
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(480);
      await notifier.calculatePension();
      await tester.pumpAndSettle();

      // 480/480 = 100.0%
      expect(find.text('100.0%'), findsOneWidget);
    });
  });
}
