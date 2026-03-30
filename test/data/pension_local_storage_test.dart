import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/data/pension_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PensionStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('初期状態では全てnull（desiredPensionStartAgeはデフォルト65）', () async {
      final data = await PensionStorage.loadPensionFormData();

      expect(data.currentAge, isNull);
      expect(data.paymentMonths, isNull);
      expect(data.occupationalPaymentMonths, isNull);
      expect(data.monthlySalary, isNull);
      expect(data.bonus, isNull);
      expect(data.desiredPensionStartAge, equals(65));
    });

    test('全フィールドを保存して読み込めること', () async {
      await PensionStorage.savePensionFormData(
        currentAge: 35,
        paymentMonths: 360,
        occupationalPaymentMonths: 240,
        monthlySalary: 300000,
        bonus: 500000,
        desiredPensionStartAge: 70,
      );

      final data = await PensionStorage.loadPensionFormData();

      expect(data.currentAge, equals(35));
      expect(data.paymentMonths, equals(360));
      expect(data.occupationalPaymentMonths, equals(240));
      expect(data.monthlySalary, equals(300000));
      expect(data.bonus, equals(500000));
      expect(data.desiredPensionStartAge, equals(70));
    });

    test('一部のフィールドだけ保存した場合、未保存はnul', () async {
      await PensionStorage.savePensionFormData(
        currentAge: 40,
        paymentMonths: 480,
      );

      final data = await PensionStorage.loadPensionFormData();

      expect(data.currentAge, equals(40));
      expect(data.paymentMonths, equals(480));
      expect(data.occupationalPaymentMonths, isNull);
      expect(data.monthlySalary, isNull);
      expect(data.bonus, isNull);
      expect(data.desiredPensionStartAge, equals(65));
    });

    test('clearで全データを削除できる', () async {
      await PensionStorage.savePensionFormData(
        currentAge: 35,
        paymentMonths: 360,
        occupationalPaymentMonths: 240,
        monthlySalary: 300000,
        bonus: 500000,
        desiredPensionStartAge: 70,
      );

      await PensionStorage.clearPensionFormData();

      final data = await PensionStorage.loadPensionFormData();

      expect(data.currentAge, isNull);
      expect(data.paymentMonths, isNull);
      expect(data.occupationalPaymentMonths, isNull);
      expect(data.monthlySalary, isNull);
      expect(data.bonus, isNull);
      expect(data.desiredPensionStartAge, equals(65));
    });

    test('nullフィールドは保存をスキップする', () async {
      // 最初にデータを保存
      await PensionStorage.savePensionFormData(
        currentAge: 35,
        paymentMonths: 360,
      );

      // nullで上書き保存 → 既存値が維持される
      await PensionStorage.savePensionFormData(
        currentAge: null,
        paymentMonths: null,
      );

      final data = await PensionStorage.loadPensionFormData();
      expect(data.currentAge, equals(35));
      expect(data.paymentMonths, equals(360));
    });
  });

  group('PensionFormDataMap', () {
    test('デフォルト値が正しい', () {
      final map = PensionFormDataMap();

      expect(map.currentAge, isNull);
      expect(map.paymentMonths, isNull);
      expect(map.occupationalPaymentMonths, isNull);
      expect(map.monthlySalary, isNull);
      expect(map.bonus, isNull);
      expect(map.desiredPensionStartAge, equals(65));
    });

    test('全パラメータを指定して生成できる', () {
      final map = PensionFormDataMap(
        currentAge: 30,
        paymentMonths: 240,
        occupationalPaymentMonths: 120,
        monthlySalary: 250000,
        bonus: 400000,
        desiredPensionStartAge: 68,
      );

      expect(map.currentAge, equals(30));
      expect(map.paymentMonths, equals(240));
      expect(map.occupationalPaymentMonths, equals(120));
      expect(map.monthlySalary, equals(250000));
      expect(map.bonus, equals(400000));
      expect(map.desiredPensionStartAge, equals(68));
    });
  });
}
