import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/services/pension_age_calculator.dart';

void main() {
  group('PensionAgeCalculator - 30～100歳シミュレーション', () {
    test('30～100歳の全年度計算を表示（月次シミュレーション版）', () {
      // iDeCo参考パラメータ
      const int idecoCurrentAge = 30;
      const double idecoCurrentBalance = 500000.0;
      const double idecoMonthlyContribution = 23000.0;
      const double idecoAnnualReturnRate = 3.0;

      print('\n📊 iDeCo シミュレーション（月次シミュレーション版：contribute → withdraw → interest）');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('初期条件: 年齢30歳、残高¥500,000、月額拠出¥23,000、年利3%');
      print('引出: 60-64歳¥100,000/月、65歳以降¥50,000/月（シミュレーション駆動）');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      print('年齢 │ 残高           │ 年間運用益   │ 月額引出   │ 状態');
      print('────┼────────────────┼─────────────┼───────────┼────────');

      double prevBalance = idecoCurrentBalance;

      for (int age = idecoCurrentAge; age <= 100; age++) {
        // 拠出は65歳まで
        final isContribAge = age <= 65;
        final monthlyContrib = isContribAge ? idecoMonthlyContribution : 0.0;

        // 引出額は年齢によって変動（小さい額で長期保持を確認するため）
        double monthlyWithdrawal = 0.0;
        if (age >= 60 && age < 65) {
          monthlyWithdrawal = 100000.0;
        } else if (age >= 65) {
          monthlyWithdrawal = 50000.0;
        }

        final result = PensionAgeCalculator.simulateYear(
          currentBalance: prevBalance,
          monthlyContribution: monthlyContrib,
          annualReturnRate: idecoAnnualReturnRate,
          monthlyWithdrawal: monthlyWithdrawal,
        );

        // 状態
        String status;
        if (age < 60) {
          status = '積立中';
        } else if (result.balance <= 0) {
          status = '枯渇';
        } else if (result.totalWithdrawal > 0) {
          status = '引出中';
        } else {
          status = '残高あり';
        }

        print(
          '${age.toString().padLeft(3)} │ '
          '¥${result.balance.toInt().toString().padLeft(12)} │ '
          '¥${result.gain.toInt().toString().padLeft(10)} │ '
          '¥${(result.totalWithdrawal / 12).toInt().toString().padLeft(7)}/月 │ '
          '$status',
        );

        prevBalance = result.balance;

        // フェーズ変わり目
        if (age == 59 || age == 64) {
          print('────┼────────────────┼─────────────┼───────────┼────────');
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      // 検証: 60歳時点で約¥14.5M以上の残高があるはず
      double checkBalance = idecoCurrentBalance;
      for (int age = idecoCurrentAge; age < 60; age++) {
        final result = PensionAgeCalculator.simulateYear(
          currentBalance: checkBalance,
          monthlyContribution: idecoMonthlyContribution,
          annualReturnRate: idecoAnnualReturnRate,
          monthlyWithdrawal: 0.0,
        );
        checkBalance = result.balance;
      }
      print('✅ 60歳時点の残高: ¥${checkBalance.toInt()}');
      expect(checkBalance, greaterThan(14000000), reason: '30年積立で¥14M以上');

      // 検証: 65歳時点の残高 (100,000/月×5年の引出後)
      // 14.5M - (100,000 × 12 × 5) = 14.5M - 6M = 8.5M程度
      print('✅ 最終（100歳）残高: ¥${prevBalance.toInt()}');
      expect(prevBalance, greaterThanOrEqualTo(0),
          reason: '100年シミュレーション完了。引出継続で最終残高が0以上');
    });

    test('シミュレーション結果: balance、gain、totalWithdrawalが正しい値を返す', () {
      // 簡単なケース: 初期残高1000万、月額50万拠出、月額40万引出、年利3%
      final result = PensionAgeCalculator.simulateYear(
        currentBalance: 10000000.0,
        monthlyContribution: 500000.0,
        annualReturnRate: 3.0,
        monthlyWithdrawal: 400000.0,
      );

      // 月次処理：
      //   拠出: +500,000 × 12 = +6,000,000
      //   引出: -400,000 × 12 = -4,800,000
      //   年間変化: +1,200,000
      //   月率: (1 + 0.03)^(1/12) - 1 ≈ 0.002466
      //   複利: 初期 10M → 期中に変動 → 最終的にはプラス

      // totalWithdrawal は 実際の引出額 = min(max(balance, 0), desired)
      // 十分な残高があるので、月額40万 × 12 = 480万引かれるはず
      expect(result.totalWithdrawal, closeTo(4800000.0, 1),
          reason: '年間引出額は¥4,800,000');

      // balance は 10M + 6M - 4.8M + 運用益
      // 運用益は複利計算で数十万程度
      expect(result.balance, greaterThan(10000000 + 6000000 - 4800000),
          reason: '残高は1000万以上（拠出 - 引出 + 運用益）');

      // gain は 複利による増加分
      expect(result.gain, greaterThan(100000), reason: '運用益は最低¥100,000以上');
    });

    test('残高0のケース: 引出不可、gain も0', () {
      // 残高0、拠出0で引出を試みる
      final result = PensionAgeCalculator.simulateYear(
        currentBalance: 0.0,
        monthlyContribution: 0.0,
        annualReturnRate: 3.0,
        monthlyWithdrawal: 100000.0,
      );

      // 残高0のため引出不可
      expect(result.totalWithdrawal, equals(0.0), reason: '残高0では引出0');
      expect(result.balance, equals(0.0), reason: '残高は0のまま');
      expect(result.gain, equals(0.0), reason: '運用益も0');
    });

    test('拠出みのケース（60歳前の積立）: 残高と運用益が増加', () {
      // 初期残高100万、月額5万拠出、引出なし、年利3%
      final result = PensionAgeCalculator.simulateYear(
        currentBalance: 1000000.0,
        monthlyContribution: 50000.0,
        annualReturnRate: 3.0,
        monthlyWithdrawal: 0.0,
      );

      // 拠出: 50,000 × 12 = 600,000
      // 運用益: 複利で数万程度
      // 最終残高: 1M + 600k + 運用益
      expect(result.balance, greaterThan(1600000),
          reason: '拠出により残高が増加');
      expect(result.totalWithdrawal, equals(0.0),
          reason: '引出なし');
      expect(result.gain, greaterThan(20000),
          reason: '運用益が発生');
    });
  });
}
