import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/usecases/calculate_pension_use_case.dart';

void main() {
  group('CalculatePensionUseCase', () {
    /// デシジョンテーブル: 計算モード選択
    ///
    /// | # | occMonths | salary | bonus  | 期待モード     | 基礎年金 | 厚生年金 |
    /// |---|-----------|--------|--------|---------------|---------|---------|
    /// | 1 | 0         | null   | null   | 基礎年金のみ   | > 0     | == 0    |
    /// | 2 | 0         | 300000 | 500000 | 基礎年金のみ   | > 0     | == 0    |
    /// | 3 | 360       | null   | 500000 | 基礎年金のみ   | > 0     | == 0    |
    /// | 4 | 360       | 300000 | null   | 基礎年金のみ   | > 0     | == 0    |
    /// | 5 | 360       | 300000 | 500000 | 基礎+厚生     | > 0     | > 0     |
    /// | 6 | 1         | 100000 | 0      | 基礎+厚生     | > 0     | > 0     |

    test('ケース1: occMonths=0, salary=null, bonus=null → 基礎年金のみ', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
        occupationalPaymentMonths: 0,
        monthlySalary: null,
        bonus: null,
      );

      expect(result.basicPensionMonthly, greaterThan(0));
      expect(result.occupationalPensionMonthly, equals(0.0));
    });

    test('ケース2: occMonths=0, salary指定, bonus指定 → occMonths=0なので基礎年金のみ', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
        occupationalPaymentMonths: 0,
        monthlySalary: 300000,
        bonus: 500000,
      );

      expect(result.basicPensionMonthly, greaterThan(0));
      expect(result.occupationalPensionMonthly, equals(0.0));
    });

    test('ケース3: occMonths>0, salaryなし → 基礎年金のみ（条件不足）', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
        occupationalPaymentMonths: 360,
        monthlySalary: null,
        bonus: 500000,
      );

      expect(result.basicPensionMonthly, greaterThan(0));
      expect(result.occupationalPensionMonthly, equals(0.0));
    });

    test('ケース4: occMonths>0, bonusなし → 基礎年金のみ（条件不足）', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
        occupationalPaymentMonths: 360,
        monthlySalary: 300000,
        bonus: null,
      );

      expect(result.basicPensionMonthly, greaterThan(0));
      expect(result.occupationalPensionMonthly, equals(0.0));
    });

    test('ケース5: occMonths>0, salary指定, bonus指定 → 基礎+厚生年金', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
        occupationalPaymentMonths: 360,
        monthlySalary: 300000,
        bonus: 500000,
      );

      expect(result.basicPensionMonthly, greaterThan(0));
      expect(result.occupationalPensionMonthly, greaterThan(0));
      expect(result.totalPensionMonthly,
          closeTo(result.basicPensionMonthly + result.occupationalPensionMonthly, 0.01));
    });

    test('ケース6: occMonths=1, salary最小, bonus=0 → 基礎+厚生年金', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
        occupationalPaymentMonths: 1,
        monthlySalary: 100000,
        bonus: 0,
      );

      expect(result.basicPensionMonthly, greaterThan(0));
      expect(result.occupationalPensionMonthly, greaterThan(0));
    });

    test('受給開始年齢60歳（繰上げ）で調整率 < 1.0', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 60,
      );

      expect(result.adjustmentRate, lessThan(0.8));
      expect(result.pensionStartAge, equals(60));
    });

    test('受給開始年齢75歳（繰下げ最大）で調整率 > 1.0', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 75,
      );

      expect(result.adjustmentRate, greaterThan(1.8));
      expect(result.pensionStartAge, equals(75));
    });

    test('受給開始年齢65歳（標準）で調整率 == 1.0', () {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: 480,
        desiredPensionStartAge: 65,
      );

      expect(result.adjustmentRate, equals(1.0));
    });

    group('iDeCo+投資信託の複合ルーティング', () {
      test('iDeCo+投資信託（厚生なし）: 両方のFVが正の値', () {
        final result = CalculatePensionUseCase.execute(
          paymentMonths: 480,
          desiredPensionStartAge: 65,
          idecoMonthlyContribution: 23000,
          idecoCurrentAge: 30,
          idecoAnnualReturnRate: 3.0,
          investmentTrustMonthlyContribution: 30000,
          investmentTrustCurrentAge: 30,
          investmentTrustAnnualReturnRate: 5.0,
          investmentTrustWithdrawalStartAge: 55,
          monthlyLivingExpenses: 200000,
          targetAge: 100,
        );

        // 基礎年金は正の値
        expect(result.basicPensionMonthly, greaterThan(0));
        // 厚生年金は0
        expect(result.occupationalPensionMonthly, equals(0.0));
        // iDeCo FV > 0
        expect(result.idecoFutureValue, greaterThan(0));
        // IT FV > 0
        expect(result.investmentTrustFutureValue, greaterThan(0));
      });

      test('iDeCo+投資信託+厚生年金: 3つの年金ソースが全て正の値', () {
        final result = CalculatePensionUseCase.execute(
          paymentMonths: 480,
          desiredPensionStartAge: 65,
          occupationalPaymentMonths: 360,
          monthlySalary: 300000,
          bonus: 500000,
          idecoMonthlyContribution: 23000,
          idecoCurrentAge: 30,
          idecoAnnualReturnRate: 3.0,
          investmentTrustMonthlyContribution: 30000,
          investmentTrustCurrentAge: 30,
          investmentTrustAnnualReturnRate: 5.0,
          investmentTrustWithdrawalStartAge: 55,
          monthlyLivingExpenses: 300000,
          targetAge: 100,
        );

        // 基礎年金
        expect(result.basicPensionMonthly, greaterThan(0));
        // 厚生年金
        expect(result.occupationalPensionMonthly, greaterThan(0));
        // iDeCo FV
        expect(result.idecoFutureValue, greaterThan(0));
        // IT FV
        expect(result.investmentTrustFutureValue, greaterThan(0));
        // 生活費
        expect(result.monthlyLivingExpenses, 300000);
      });
    });
  });
}
