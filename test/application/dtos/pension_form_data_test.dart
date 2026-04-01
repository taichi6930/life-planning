import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/application/dtos/pension_form_data.dart';

void main() {
  group('PensionFormDataMap', () {
    test('デフォルト値が正しい', () {
      final map = PensionFormDataMap();

      expect(map.currentAge, isNull);
      expect(map.paymentMonths, isNull);
      expect(map.occupationalPaymentMonths, isNull);
      expect(map.monthlySalary, isNull);
      expect(map.bonus, isNull);
      expect(map.desiredPensionStartAge, equals(65));
      expect(map.idecoMonthlyContribution, equals(0));
      expect(map.idecoAnnualReturnRate, equals(3.0));
      expect(map.idecoCurrentBalance, equals(0));
      expect(map.monthlyLivingExpenses, equals(0));
      expect(map.targetAge, equals(100));
    });

    test('全パラメータを指定して生成できる', () {
      final map = PensionFormDataMap(
        currentAge: 30,
        paymentMonths: 240,
        occupationalPaymentMonths: 120,
        monthlySalary: 250000,
        bonus: 400000,
        desiredPensionStartAge: 68,
        idecoMonthlyContribution: 23000,
        idecoAnnualReturnRate: 5.0,
        idecoCurrentBalance: 1000000,
        monthlyLivingExpenses: 200000,
        targetAge: 95,
      );

      expect(map.currentAge, equals(30));
      expect(map.paymentMonths, equals(240));
      expect(map.occupationalPaymentMonths, equals(120));
      expect(map.monthlySalary, equals(250000));
      expect(map.bonus, equals(400000));
      expect(map.desiredPensionStartAge, equals(68));
      expect(map.idecoMonthlyContribution, equals(23000));
      expect(map.idecoAnnualReturnRate, equals(5.0));
      expect(map.idecoCurrentBalance, equals(1000000));
      expect(map.monthlyLivingExpenses, equals(200000));
      expect(map.targetAge, equals(95));
    });

    test('一部フィールドのみ指定した場合、残りはデフォルト値', () {
      final map = PensionFormDataMap(currentAge: 40);

      expect(map.currentAge, equals(40));
      expect(map.paymentMonths, isNull);
      expect(map.desiredPensionStartAge, equals(65));
    });
  });
}
