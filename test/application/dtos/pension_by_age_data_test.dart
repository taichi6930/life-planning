import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/application/dtos/pension_by_age_data.dart';

void main() {
  group('PensionByAgeData', () {
    test('totalMonthly は basicPensionMonthly + occupationalPensionMonthly', () {
      const data = PensionByAgeData(
        age: 65,
        basicPensionMonthly: 70608,
        occupationalPensionMonthly: 50000,
      );

      expect(data.totalMonthly, equals(120608));
    });

    test('厚生年金が0の場合、totalMonthly == basicPensionMonthly', () {
      const data = PensionByAgeData(
        age: 65,
        basicPensionMonthly: 70608,
        occupationalPensionMonthly: 0,
      );

      expect(data.totalMonthly, equals(70608));
    });

    test('age が正しく保持される', () {
      const data = PensionByAgeData(
        age: 75,
        basicPensionMonthly: 100000,
        occupationalPensionMonthly: 0,
      );

      expect(data.age, equals(75));
    });
  });
}
