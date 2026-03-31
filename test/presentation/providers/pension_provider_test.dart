import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/pension_result.dart';
import 'package:life_planning/presentation/providers/pension_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PensionResult _createMockResult() {
  return PensionResult(
    basicPensionMonthly: 50000,
    basicPensionAnnual: 600000,
    occupationalPensionMonthly: 80000,
    occupationalPensionAnnual: 960000,
    totalPensionMonthly: 130000,
    totalPensionAnnual: 1560000,
    adjustmentRate: 1.0,
    pensionStartAge: 65,
  );
}

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
      expect(monthlyPension, isA<double>());
      expect(monthlyPension!, greaterThan(0));
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
      expect(yearlyPension, isA<double>());
      expect(yearlyPension!, greaterThan(0));
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

    test('エラー後に正常な入力で再計算するとエラーがクリアされる', () async {
      final container = ProviderContainer();
      final notifier =
          container.read(pensionFormNotifierProvider.notifier);

      // 1回目: 不完全な入力（年齢なし）でエラー
      notifier.setPaymentMonths(360);
      await notifier.calculatePension();
      var state = container.read(pensionFormNotifierProvider);
      expect(state.error, isNotNull);

      // 2回目: 年齢を設定して再計算 → エラーがクリアされる
      notifier.setCurrentAge(35);
      await notifier.calculatePension();
      state = container.read(pensionFormNotifierProvider);
      expect(state.error, isNull);
      expect(state.result, isNotNull);
    });

    test('setOccupationalPaymentMonths で厚生年金加入月数を更新できる', () {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setOccupationalPaymentMonths(240);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.occupationalPaymentMonths, 240);
    });

    test('setMonthlySalary で標準報酬月額を更新できる', () {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setMonthlySalary(300000);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.monthlySalary, 300000);
    });

    test('setBonus で賞与を更新できる', () {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setBonus(500000);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.bonus, 500000);
    });

    test('setDesiredPensionStartAge で受給開始年齢を更新できる', () {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setDesiredPensionStartAge(70);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.desiredPensionStartAge, 70);
    });

    test('setIdecoCurrentBalance で現在の投資残高を更新できる', () {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setIdecoCurrentBalance(2000000);
      final state = container.read(pensionFormNotifierProvider);

      expect(state.idecoCurrentBalance, 2000000);
    });

    test('厚生年金パラメータ付きで計算すると結果に厚生年金が含まれる', () async {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);
      notifier.setOccupationalPaymentMonths(240);
      notifier.setMonthlySalary(300000);
      notifier.setBonus(500000);

      await notifier.calculatePension();
      final state = container.read(pensionFormNotifierProvider);

      expect(state.result, isNotNull);
      expect(state.result!.basicPensionMonthly, greaterThan(0));
      expect(state.result!.occupationalPensionMonthly, greaterThan(0));
    });

    test('計算前の nationalPensionYearlyProvider は null', () {
      final container = ProviderContainer();
      final yearly = container.read(nationalPensionYearlyProvider);

      expect(yearly, isNull);
    });

    test('計算前の nationalPensionMonthlyProvider は null', () {
      final container = ProviderContainer();
      final monthly = container.read(nationalPensionMonthlyProvider);

      expect(monthly, isNull);
    });

    test('paymentMonths 未設定で contributionRateProvider は null', () {
      final container = ProviderContainer();
      final rate = container.read(contributionRateProvider);

      expect(rate, isNull);
    });

    test('計算前の pensionByAgeChartProvider は null', () {
      final container = ProviderContainer();
      final chartData = container.read(pensionByAgeChartProvider);

      expect(chartData, isNull);
    });

    test('計算後の pensionByAgeChartProvider は60〜100歳の41件', () async {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);
      await notifier.calculatePension();

      final chartData = container.read(pensionByAgeChartProvider);

      expect(chartData, isNotNull);
      expect(chartData!.length, equals(41));
      expect(chartData.first.age, equals(60));
      expect(chartData.last.age, equals(100));
    });

    test('chartProvider: 受給開始年齢前は公的年金0円、以降は年金あり（iDeCoなし）', () async {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      notifier.setCurrentAge(35);
      notifier.setPaymentMonths(360);
      notifier.setDesiredPensionStartAge(70);
      await notifier.calculatePension();

      final chartData = container.read(pensionByAgeChartProvider)!;

      // 60〜69歳は公的年金0（iDeCoなしのため idecoMonthly も0）
      for (final d in chartData.where((d) => d.age < 70)) {
        expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 受給開始前は0');
        expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: iDeCoなしは0');
      }
      // 70歳以降は > 0
      for (final d in chartData.where((d) => d.age >= 70)) {
        expect(d.basicPensionMonthly, greaterThan(0), reason: '${d.age}歳: 受給開始後は年金あり');
      }
    });

    test('chartProvider: 2段階iDeCoモデル - Phase 1(60〜64)はiDeCoのみ、Phase 2(65〜)は公的年金+iDeCo', () async {
      final container = ProviderContainer();
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      // iDeCo付き設定（大きなFVでPhase 1を乗り越えられる条件）
      notifier.setCurrentAge(25);
      notifier.setPaymentMonths(480);
      notifier.setDesiredPensionStartAge(65);
      notifier.setIdecoMonthlyContribution(68000);
      notifier.setIdecoAnnualReturnRate(5.0);
      notifier.setMonthlyLivingExpenses(200000);
      await notifier.calculatePension();

      final chartData = container.read(pensionByAgeChartProvider)!;

      // Phase 1 (60〜64歳): 公的年金0、iDeCoは生活費を表示
      for (final d in chartData.where((d) => d.age < 65)) {
        expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: Phase 1 公的年金0');
        expect(d.idecoMonthly, greaterThan(0), reason: '${d.age}歳: Phase 1 iDeCo > 0');
      }

      // Phase 2 (65歳以降): 公的年金あり
      for (final d in chartData.where((d) => d.age >= 65 && d.age < 90)) {
        expect(d.basicPensionMonthly, greaterThan(0), reason: '${d.age}歳: Phase 2 公的年金あり');
      }
    });

    test('calculatePension: 計算中にエラーが発生した場合、エラー状態に遷移する', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pensionFormNotifierProvider.notifier);

      // 不正な paymentMonths (-1) を設定 → null チェックは通るが
      // PensionCalculationService が ArgumentError を投げる
      notifier.setCurrentAge(30);
      notifier.setPaymentMonths(-1);

      await notifier.calculatePension();

      final state = container.read(pensionFormNotifierProvider);
      expect(state.error, contains('エラーが発生しました'));
      expect(state.isLoading, false);
    });
  });

  group('PensionFormState copyWith', () {
    /// デシジョンテーブル: copyWith の null 処理
    ///
    /// | # | 引数指定   | 既存値  | 期待結果  |
    /// |---|-----------|--------|----------|
    /// | 1 | 指定なし   | あり    | 既存値維持 |
    /// | 2 | null指定   | あり    | null     |
    /// | 3 | 新値指定   | あり    | 新値     |
    /// | 4 | 新値指定   | null   | 新値     |

    test('引数指定なしでは既存値が維持される', () {
      const original = PensionFormState(
        currentAge: 35,
        paymentMonths: 360,
        occupationalPaymentMonths: 240,
        monthlySalary: 300000,
        bonus: 500000,
        desiredPensionStartAge: 70,
      );

      final copied = original.copyWith();

      expect(copied.currentAge, equals(35));
      expect(copied.paymentMonths, equals(360));
      expect(copied.occupationalPaymentMonths, equals(240));
      expect(copied.monthlySalary, equals(300000));
      expect(copied.bonus, equals(500000));
      expect(copied.desiredPensionStartAge, equals(70));
    });

    test('error に null を明示的に指定すると null になる', () {
      const original = PensionFormState(error: 'エラーメッセージ');

      final copied = original.copyWith(error: null);

      expect(copied.error, isNull);
    });

    test('result に null を明示的に指定すると null になる', () {
      // ignore: use a PensionResult to set up
      final original = PensionFormState(
        result: _createMockResult(),
      );

      final copied = original.copyWith(result: null);

      expect(copied.result, isNull);
    });

    test('新値を指定するとその値になる', () {
      const original = PensionFormState(currentAge: 30);

      final copied = original.copyWith(currentAge: 50);

      expect(copied.currentAge, equals(50));
    });
  });
}
