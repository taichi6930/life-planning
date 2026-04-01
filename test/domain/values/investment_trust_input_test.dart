import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/investment_trust_input.dart';

void main() {
  group('InvestmentTrustInput - 定数', () {
    test('デフォルト引出開始年齢は60歳', () {
      expect(InvestmentTrustInput.defaultWithdrawalStartAge, 60);
    });
  });

  group('InvestmentTrustInput - コンストラクタとデフォルト値', () {
    test('必須パラメータのみで生成可能', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
      );
      expect(input.monthlyContribution, 30000);
      expect(input.currentAge, 30);
      expect(input.contributionEndAge, 60); // デフォルト: withdrawalStartAge と同じ
      expect(input.expectedAnnualReturnRate, 5.0);
      expect(input.withdrawalStartAge, 60); // デフォルト60歳
      expect(input.currentBalance, 0);
    });

    test('全パラメータ指定で生成', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 50000,
        currentAge: 25,
        contributionEndAge: 55,
        expectedAnnualReturnRate: 7.0,
        withdrawalStartAge: 50,
        currentBalance: 1000000,
      );
      expect(input.monthlyContribution, 50000);
      expect(input.currentAge, 25);
      expect(input.contributionEndAge, 55);
      expect(input.expectedAnnualReturnRate, 7.0);
      expect(input.withdrawalStartAge, 50);
      expect(input.currentBalance, 1000000);
    });

    test('60歳以上でも生成可能', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 10000,
        currentAge: 65,
        contributionEndAge: 70,
        withdrawalStartAge: 65,
      );
      expect(input.currentAge, 65);
      expect(input.withdrawalStartAge, 65);
    });

    test('早期引出（50歳引出開始）設定可能', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 100000,
        currentAge: 30,
        withdrawalStartAge: 50,
      );
      expect(input.withdrawalStartAge, 50);
      expect(input.contributionEndAge, 50); // withdrawalStartAge と同じにデフォルト
    });

    test('contributionEndAge を withdrawalStartAge より早く設定可能', () {
      // 45歳で積立停止、60歳から引出開始（積立停止後も運用継続）
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 60,
      );
      expect(input.contributionEndAge, 45);
      expect(input.withdrawalStartAge, 60);
    });
  });

  group('InvestmentTrustInput - 拠出月数計算', () {
    test('30歳・引出開始60歳（デフォルト）で360ヶ月', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
      );
      expect(input.contributionMonths, 360);
    });

    test('20歳・引出開始60歳で480ヶ月', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 20,
      );
      expect(input.contributionMonths, 480);
    });

    test('30歳・拠出終了45歳・引出開始60歳で180ヶ月（早期積立停止）', () {
      // 積立を45歳で停止し、残高を60歳まで運用継続
      // 拠出月数は30〜45歳の180ヶ月
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 60,
      );
      expect(input.contributionMonths, 180);
    });

    test('30歳・引出開始50歳で240ヶ月（早期引出）', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 100000,
        currentAge: 30,
        withdrawalStartAge: 50,
      );
      expect(input.contributionMonths, 240);
    });

    test('引出開始年齢が現在年齢以下の場合は0ヶ月', () {
      // すでに引出開始年齢を過ぎている場合
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 65,
        contributionEndAge: 65,
        withdrawalStartAge: 65,
      );
      expect(input.contributionMonths, 0);
    });
  });

  group('InvestmentTrustInput - 月利計算', () {
    test('年利5.0%の場合、月利は約0.004167', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 5.0,
      );
      expect(input.monthlyReturnRate, closeTo(0.004167, 0.0001));
    });

    test('年利0%の場合、月利は0', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.monthlyReturnRate, 0.0);
    });

    test('年利3%の場合、月利は約0.0025', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 3.0,
      );
      expect(input.monthlyReturnRate, closeTo(0.0025, 0.0001));
    });
  });

  group('InvestmentTrustInput - 将来価値（FV）計算', () {
    test('利回り0%の場合は単純積算', () {
      // 月額30,000円 × 360ヶ月（30〜60歳）= 10,800,000円
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.futureValue, closeTo(10800000, 1));
    });

    test('利回り0%の場合は単純積算（既存残高あり）', () {
      // 月額30,000円 × 360ヶ月 + 残高500,000円 = 11,300,000円
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
        currentBalance: 500000,
      );
      expect(input.futureValue, closeTo(11300000, 1));
    });

    test('利回り5%・月額30,000円・30歳〜60歳のFV', () {
      // 複利計算の結果は元本（10,800,000円）より多い
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 5.0,
      );
      expect(input.futureValue, greaterThan(10800000));
      expect(input.futureValue, greaterThan(24000000)); // 約2,500万円超
    });

    test('利回りあり・既存残高ありの場合、残高なしより多い', () {
      const noBalance = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 5.0,
      );
      const withBalance = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 5.0,
        currentBalance: 1000000,
      );
      expect(withBalance.futureValue, greaterThan(noBalance.futureValue));
      expect(withBalance.futureValue - noBalance.futureValue, greaterThan(1000000));
    });

    test('早期積立停止後の運用（積立停止→運用継続→引出）', () {
      // 45歳で積立停止、60歳から引出 → 30〜45歳分の拠出（180ヶ月）のFV
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 60,
        expectedAnnualReturnRate: 0.0,
      );
      // 利回り0%なので: 30,000 × 180 = 5,400,000円
      expect(input.futureValue, closeTo(5400000, 1));
    });

    test('ギャップ期間の複利運用（拠出終了45歳→引出開始60歳、利回り5%）', () {
      // 拠出: 30歳〜45歳（contributionEndAge=45）= 180ヶ月
      // ギャップ: 45歳〜60歳（引出開始）= 180ヶ月の複利運用のみ
      const withGap = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 60,
        expectedAnnualReturnRate: 5.0,
      );
      // 比較: 同じ拠出期間だがギャップなし（引出開始45歳）
      const noGap = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 45,
        expectedAnnualReturnRate: 5.0,
      );
      // 両方とも拠出月数は同じ（180ヶ月）
      expect(withGap.contributionMonths, noGap.contributionMonths);
      expect(withGap.contributionMonths, 180);
      // ギャップ期間の複利運用により、withGapの方がFVが大きい
      expect(withGap.futureValue, greaterThan(noGap.futureValue));
      // ギャップ分の倍率 = (1 + 0.05/12)^180 ≈ 2.1137
      final gapMultiplier = withGap.futureValue / noGap.futureValue;
      expect(gapMultiplier, closeTo(2.1137, 0.05));
    });

    test('ギャップ期間あり・利回り0%の場合はFV変わらず', () {
      const withGap = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 60,
        expectedAnnualReturnRate: 0.0,
      );
      const noGap = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 45,
        expectedAnnualReturnRate: 0.0,
      );
      // 利回り0%なので同額
      expect(withGap.futureValue, closeTo(noGap.futureValue, 1));
    });

    test('ギャップ期間の複利運用（既存残高あり）', () {
      const withGap = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 60,
        expectedAnnualReturnRate: 5.0,
        currentBalance: 1000000,
      );
      const noGap = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 45,
        withdrawalStartAge: 45,
        expectedAnnualReturnRate: 5.0,
        currentBalance: 1000000,
      );
      // ギャップ期間の複利運用でFVが大きくなる
      expect(withGap.futureValue, greaterThan(noGap.futureValue));
      // 全体にギャップ倍率がかかる
      final gapMultiplier = withGap.futureValue / noGap.futureValue;
      expect(gapMultiplier, closeTo(2.1137, 0.05));
    });

    test('既存残高のみ（新規拠出なし）のFV', () {
      // 60歳・既存残高1,000万円・拠出0（既に引出開始年齢）
      const input = InvestmentTrustInput(
        monthlyContribution: 1,
        currentAge: 60,
        contributionEndAge: 60,
        withdrawalStartAge: 60,
        expectedAnnualReturnRate: 0.0,
        currentBalance: 10000000,
      );
      // 拠出月数0なので、残高のみ = 10,000,000円
      expect(input.contributionMonths, 0);
      expect(input.futureValue, closeTo(10000000, 1));
    });
  });

  group('InvestmentTrustInput - isValid() デシジョンテーブル', () {
    /// | # | monthlyContribution | currentAge | endAge | rate | startAge | 結果  |
    /// |---|---------------------|------------|--------|------|----------|-------|
    /// | 1 | 30000               | 30         | 60     | 5.0  | 60       | true  |
    /// | 2 | 0                   | 30         | 60     | 5.0  | 60       | false |
    /// | 3 | -1                  | 30         | 60     | 5.0  | 60       | false |
    /// | 4 | 30000               | -1         | 60     | 5.0  | 60       | false |
    /// | 5 | 30000               | 30         | 30     | 5.0  | 60       | false |
    /// | 6 | 30000               | 30         | 60     | -0.1 | 60       | false |
    /// | 7 | 30000               | 30         | 60     | 20.1 | 60       | false |
    /// | 8 | 30000               | 30         | 60     | 5.0  | -1       | false |
    /// | 9 | 30000               | 60         | 70     | 5.0  | 60       | true  |（60歳以上OK）
    /// |10 | 30000               | 30         | 50     | 5.0  | 60       | true  |（早期積立停止OK）

    test('ケース1: 有効な標準入力 → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
      );
      expect(input.isValid(), isTrue);
    });

    test('ケース2: 拠出額0 → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 0,
        currentAge: 30,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース3: 拠出額マイナス → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: -1,
        currentAge: 30,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース4: 年齢マイナス → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: -1,
        contributionEndAge: 60,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース5: 拠出終了年齢が現在年齢と同じ → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 30,
        withdrawalStartAge: 60,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース6: 年利マイナス → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: -0.1,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース7: 年利20.1%超 → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 20.1,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース8: 引出開始年齢マイナス → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        withdrawalStartAge: -1,
        contributionEndAge: 10,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース9: 60歳以上での新規積立 → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 60,
        contributionEndAge: 70,
        withdrawalStartAge: 60,
      );
      expect(input.isValid(), isTrue);
    });

    test('ケース10: 早期積立停止（contributionEndAge < withdrawalStartAge） → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        contributionEndAge: 50,
        withdrawalStartAge: 60,
      );
      expect(input.isValid(), isTrue);
    });

    test('残高0（デフォルト） → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        currentBalance: 0,
      );
      expect(input.isValid(), isTrue);
    });

    test('残高正値 → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        currentBalance: 5000000,
      );
      expect(input.isValid(), isTrue);
    });

    test('残高マイナス → false', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        currentBalance: -1,
      );
      expect(input.isValid(), isFalse);
    });

    test('年利0%（元本保証型） → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.isValid(), isTrue);
    });

    test('年利20%（上限値） → true', () {
      const input = InvestmentTrustInput(
        monthlyContribution: 30000,
        currentAge: 30,
        expectedAnnualReturnRate: 20.0,
      );
      expect(input.isValid(), isTrue);
    });
  });
}
