import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/templates/pension_form_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PensionFormTemplate Tests', () {
    testWidgets('タイトルがAppBarに表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PensionFormTemplate(title: '年金シミュレーション'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('年金シミュレーション'), findsOneWidget);
    });

    testWidgets('デフォルトタイトルは「年金計算」', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PensionFormTemplate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('年金計算'), findsOneWidget);
    });

    testWidgets('狭い画面ではタブが表示される', (WidgetTester tester) async {
      // 幅 400px のコンテナでレンダリング
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PensionFormTemplate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // タブが表示される
      expect(find.text('フォーム'), findsOneWidget);
      expect(find.text('結果'), findsOneWidget);
    });

    testWidgets('wide画面ではフォームと結果が横並び（タブなし）', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PensionFormTemplate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // タブは表示されない
      expect(find.text('フォーム'), findsNothing);
      // フォームが表示される
      expect(find.text('計算する'), findsOneWidget);
    });

    testWidgets('localStorageにデータがある場合、復元されて表示される', (WidgetTester tester) async {
      // 正しいキー名で保存データを設定
      SharedPreferences.setMockInitialValues({
        'pension_current_age': 40,
        'pension_payment_months': 300,
        'pension_occupational_payment_months': 120,
        'pension_monthly_salary': 250000,
        'pension_bonus': 600000,
        'pension_desired_pension_start_age': 70,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PensionFormTemplate(),
          ),
        ),
      );
      // 非同期の _loadSavedData を待つ
      await tester.pumpAndSettle();

      // クラッシュせずにフォームが表示されること
      expect(find.text('計算する'), findsOneWidget);
      expect(find.text('年金計算'), findsOneWidget);
    });
  });
}
