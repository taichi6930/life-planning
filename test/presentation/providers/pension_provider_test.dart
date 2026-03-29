import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_planning/presentation/providers/pension_provider.dart';

void main() {
  // Setup for shared_preferences in tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PensionFormNotifier Tests', () {
    test('初期状態は全てnull', () {
      final container = ProviderContainer();
      final state = container.read(pensionFormNotifierProvider);

      expect(state.currentAge, isNull);
      expect(state.paymentMonths, isNull);
      expect(state.isLoading, false);
      expect(state.result, isNull);
      expect(state.error, isNull);
    });

    test('setCurrentAge で年齢を更新できる', () {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      notifier.setCurrentAge(35);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.currentAge, 35);
    });

    test('setPaymentMonths で納付月数を更新できる', () {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      notifier.setPaymentMonths(360);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.paymentMonths, 360);
    });

    test('年齢なしで計算を実行するとエラーが返される', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 納付月数のみ設定
      notifier.setPaymentMonths(360);

      // 計算を実行
      await notifier.calculatePension();
      final state = container.read(pensionFormNotifierProvider);

      expect(state.error, 'すべてのフィールドを入力してください');
    });

    test('納付月数なしで計算を実行するとエラーが返される', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 年齢のみ設定
      notifier.setCurrentAge(35);

      // 計算を実行
      await notifier.calculatePension();
      final state = container.read(pensionFormNotifierProvider);

      expect(state.error, 'すべてのフィールドを入力してください');
    });

    test('正常な入力値で計算できる', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);
      
      // 入力値を設定
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);

      // 計算を実行
      await notifier.calculatePension();
      final state = container.read(pensionFormNotifierProvider);

      // 結果が取得される
      expect(state.result, isNotNull);
      expect(state.error, isNull);
      expect(state.result!.basicPensionMonthly, greaterThan(0));
      expect(state.result!.basicPensionAnnual, greaterThan(0));
    });

    test('計算後、基礎年金の月額を取得できる', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 入力値を設定
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);

      // 計算を実行
      await notifier.calculatePension();
      final monthlyPension =
          container.read(nationalPensionMonthlyProvider);

      expect(monthlyPension, isNotNull);
      expect(monthlyPension, contains('¥'));
    });

    test('計算後、基礎年金の年額を取得できる', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 入力値を設定
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);

      // 計算を実行
      await notifier.calculatePension();
      final yearlyPension = container.read(nationalPensionYearlyProvider);

      expect(yearlyPension, isNotNull);
      expect(yearlyPension, contains('¥'));
    });

    test('計算後、納付率を取得できる', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 入力値を設定
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);

      // 計算を実行
      await notifier.calculatePension();
      final rate = container.read(contributionRateProvider);

      expect(rate, isNotNull);
      expect(rate, 360 / 480);
    });

    test('reset でフォームをリセットできる', () {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 入力値を設定
      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);

      // リセット
      notifier.reset();
      final state = container.read(pensionFormNotifierProvider);

      expect(state.currentAge, isNull);
      expect(state.paymentMonths, isNull);
      expect(state.result, isNull);
    });
  });
}
