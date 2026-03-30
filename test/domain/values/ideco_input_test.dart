import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/ideco_input.dart';

void main() {
  group('IdecoInput - 定数', () {
    test('自営業者の上限月額は75,000円（2025年改正）', () {
      expect(IdecoInput.maxMonthlyContributionSelfEmployed, 75000);
    });

    test('企業年金なし会社員の上限月額は62,000円（2025年改正）', () {
      expect(IdecoInput.maxMonthlyContributionEmployee, 62000);
    });

    test('企業型DCのみ加入の合算上限は62,000円（2025年改正）', () {
      expect(IdecoInput.maxMonthlyContributionEmployeeWithDCOnly, 62000);
    });

    test('DB・DC併用/公務員の合算上限は62,000円（2025年改正）', () {
      expect(IdecoInput.maxMonthlyContributionWithDBOrPublic, 62000);
    });

    test('加入可能最小年齢は20歳', () {
      expect(IdecoInput.minJoinAge, 20);
    });

    test('拠出終了年齢は70歳（2025年改正）', () {
      expect(IdecoInput.maxContributionEndAge, 70);
    });

    test('受給開始最低年齢は60歳', () {
      expect(IdecoInput.minPensionReceiptAge, 60);
    });

    test('受給開始最大年齢は75歳', () {
      expect(IdecoInput.maxPensionReceiptAge, 75);
    });

  });

  group('IdecoInput - コンストラクタとデフォルト値', () {
    test('必須パラメータのみで生成可能', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
      );
      expect(input.monthlyContribution, 23000);
      expect(input.currentAge, 30);
      expect(input.contributionEndAge, 70);
      expect(input.expectedAnnualReturnRate, 3.0);
      expect(input.pensionStartAge, 60); // デフォルトは60歳（iDeCo受給開始最低年齢）
    });

    test('全パラメータ指定で生成', () {
      const input = IdecoInput(
        monthlyContribution: 68000,
        currentAge: 25,
        contributionEndAge: 60,
        expectedAnnualReturnRate: 5.0,
        pensionStartAge: 70,
      );
      expect(input.monthlyContribution, 68000);
      expect(input.currentAge, 25);
      expect(input.contributionEndAge, 60);
      expect(input.expectedAnnualReturnRate, 5.0);
      expect(input.pensionStartAge, 70);
    });
  });

  group('IdecoInput - 拠出月数計算', () {
    test('30歳〜70歳で480ヶ月（2025年改正後デフォルト）', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
      );
      expect(input.contributionMonths, 480);
    });

    test('20歳〜70歳で600ヶ月（2025年改正後デフォルト）', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 20,
      );
      expect(input.contributionMonths, 600);
    });

    test('40歳〜60歳（終了年齢カスタム）で240ヶ月', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 40,
        contributionEndAge: 60,
      );
      expect(input.contributionMonths, 240);
    });
  });

  group('IdecoInput - 月利計算', () {
    test('年利3.0%の場合、月利は0.0025', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 3.0,
      );
      expect(input.monthlyReturnRate, closeTo(0.0025, 0.0001));
    });

    test('年利0%の場合、月利は0', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.monthlyReturnRate, 0.0);
    });
  });

  group('IdecoInput - 将来価値（FV）計算', () {
    test('利回り0%の場合は単純積算（既存残高あり）', () {
      // 月額23,000円 × 480ヶ月 + 残高500,000円 = 11,540,000円
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
        currentBalance: 500000,
      );
      expect(input.futureValue, closeTo(11540000, 1));
    });

    test('利回り0%の場合は単純積算', () {
      // 月額23,000円 × 480ヶ月 = 11,040,000円
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.futureValue, closeTo(11040000, 1));
    });

    test('利回り3%・月額23,000円・30歳〜65歳のFV（既存残高あり）', () {
      // 既存残高1,000,000円 + 毎月拠出分のFV
      const noBalance = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 3.0,
      );
      const withBalance = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 3.0,
        currentBalance: 1000000,
      );
      // 既存残高ありの方が大きい
      expect(withBalance.futureValue, greaterThan(noBalance.futureValue));
      // 既存残高分（複利運用後）が上乗せされる
      expect(withBalance.futureValue - noBalance.futureValue, greaterThan(1000000));
    });

    test('利回り3%・月額23,000円・30歳〜70歳のFV', () {
      // FV = 23000 × ((1+0.0025)^480 - 1) / 0.0025
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 3.0,
      );
      // 複利計算の結果は元本（1,104万円）より多い
      expect(input.futureValue, greaterThan(11040000)); // 利回りありなので元本より多い
      expect(input.futureValue, greaterThan(15000000));
    });

    test('短期間・少額拠出のFV', () {
      // 月額5,000円 × 120ヶ月（10年）、利回り0%
      const input = IdecoInput(
        monthlyContribution: 5000,
        currentAge: 60,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.futureValue, closeTo(600000, 1));
    });
  });

  group('IdecoInput - isValid() デシジョンテーブル', () {
    /// | # | monthlyContribution | currentAge | endAge | rate | startAge | 結果  |
    /// |---|---------------------|------------|--------|------|----------|-------|
    /// | 1 | 23000               | 30         | 65     | 3.0  | 65       | true  |
    /// | 2 | 0                   | 30         | 65     | 3.0  | 65       | false |
    /// | 3 | -1                  | 30         | 65     | 3.0  | 65       | false |
    /// | 4 | 23000               | 19         | 65     | 3.0  | 65       | false |
    /// | 5 | 23000               | 70         | 70     | 3.0  | 65       | false |
    /// | 6 | 23000               | 30         | 30     | 3.0  | 65       | false |
    /// | 7 | 23000               | 30         | 71     | 3.0  | 65       | false |
    /// | 8 | 23000               | 30         | 65     | -0.1 | 65       | false |
    /// | 9 | 23000               | 30         | 65     | 20.1 | 65       | false |
    /// |10 | 23000               | 30         | 65     | 3.0  | 59       | false |
    /// |11 | 23000               | 30         | 65     | 3.0  | 76       | false |

    test('ケース1: 有効な標準入力 → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
      );
      expect(input.isValid(), isTrue);
    });

    test('現在の投資残高0（デフォルト） → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        currentBalance: 0,
      );
      expect(input.isValid(), isTrue);
    });

    test('現在の投資残高正値 → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        currentBalance: 5000000,
      );
      expect(input.isValid(), isTrue);
    });

    test('現在の投資残高マイナス → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        currentBalance: -1,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース2: 拠出額0 → false', () {
      const input = IdecoInput(
        monthlyContribution: 0,
        currentAge: 30,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース3: 拠出額マイナス → false', () {
      const input = IdecoInput(
        monthlyContribution: -1,
        currentAge: 30,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース4: 年齢19歳（下限未満） → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 19,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース5: 年齢70歳（拠出終了年齢以上） → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 70,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース6: 拠出終了年齢が現在年齢と同じ → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        contributionEndAge: 30,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース7: 拠出終了年齢が上限超過 → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        contributionEndAge: 71,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース8: 利回りマイナス → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: -0.1,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース9: 利回り上限超過 → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 20.1,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース10: 受給開始年齢が下限未満 → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        pensionStartAge: 59,
      );
      expect(input.isValid(), isFalse);
    });

    test('ケース11: 受給開始年齢が上限超過 → false', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        pensionStartAge: 76,
      );
      expect(input.isValid(), isFalse);
    });

    test('境界値: 年齢20歳（下限OK） → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 20,
      );
      expect(input.isValid(), isTrue);
    });

    test('境界値: 年齢64歳（上限OK） → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 64,
      );
      expect(input.isValid(), isTrue);
    });

    test('境界値: 利回り0%（元本保証型OK） → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.isValid(), isTrue);
    });

    test('境界値: 利回り20%（上限OK） → true', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 20.0,
      );
      expect(input.isValid(), isTrue);
    });
  });

  group('IdecoInput - 実世界シナリオ', () {
    test('シナリオA: 会社員（企業年金なし）30歳、月額23,000円、利回り3%', () {
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 30,
        expectedAnnualReturnRate: 3.0,
      );
      expect(input.isValid(), isTrue);
      expect(input.contributionMonths, 480); // 30〜70歳（2025年改正後）
      // 複利運用であれば元本（1,104万円）より大きい
      expect(input.futureValue, greaterThan(11040000));
    });

    test('シナリオB: 自営業者25歳、月額68,000円、利回り5%', () {
      const input = IdecoInput(
        monthlyContribution: 68000,
        currentAge: 25,
        expectedAnnualReturnRate: 5.0,
      );
      expect(input.isValid(), isTrue);
      expect(input.contributionMonths, 540); // 25〜70歳（2025年改正後）
      // 高額拠出+高利回りで大きなFV
      expect(input.futureValue, greaterThan(36720000)); // 元本=68000*540
    });

    test('シナリオC: 元本保証型（利回り0%）50歳開始、月額23,000円', () {
      // 50歳〜70歳 = 20年 = 240ヶ月（2025年改正後）
      // FV = 23000 × 240 = 5,520,000円
      const input = IdecoInput(
        monthlyContribution: 23000,
        currentAge: 50,
        expectedAnnualReturnRate: 0.0,
      );
      expect(input.isValid(), isTrue);
      expect(input.contributionMonths, 240);
      expect(input.futureValue, closeTo(5520000, 1));
    });
  });
}
