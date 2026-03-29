import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/national_pension_input.dart';

void main() {
  group('NationalPensionInput - フィールド検証', () {
    test('全フィールド指定（fullContribution = 0）', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        fullExempt: 0,
        threeQuarterExempt: 0,
        halfExempt: 0,
        quarterExempt: 0,
        studentDeferment: 0,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('最小指定（免除フィールドはデフォルト0）', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.fullExempt, 0);
      expect(input.threeQuarterExempt, 0);
      expect(input.halfExempt, 0);
      expect(input.quarterExempt, 0);
      expect(input.studentDeferment, 0);
      expect(input.isValid(), true);
    });

    test('fullContribution が正の値', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('fullExempt を明示指定', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        fullExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('全額納付480ヶ月', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('全フィールド負数だと無効（fullContribution）', () {
      final input = NationalPensionInput(
        fullContribution: -1,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), false);
    });

    test('fullExempt が負数だと無効', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: -10,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), false);
    });

    test('quarterExempt が負数だと無効', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        quarterExempt: -5,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), false);
    });

    test('studentDeferment が負数だと無効', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        studentDeferment: -20,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), false);
    });
  });

  group('NationalPensionInput - 有効納付月数計算（全額免除）', () {
    test('全額免除のみ（100ヶ月）: 50ヶ月カウント', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        fullExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 100 × 1/2 = 50.0
      expect(input.effectiveContributionMonths, 50.0);
    });

    test('全額納付と全額免除の混合', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 240 + (100 × 1/2) = 240 + 50 = 290
      expect(input.effectiveContributionMonths, 290.0);
    });
  });

  group('NationalPensionInput - 有効納付月数計算（各免除タイプ）', () {
    test('3/4免除のみ（100ヶ月）: 62.5ヶ月カウント', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        threeQuarterExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 100 × 5/8 = 62.5
      expect(input.effectiveContributionMonths, 62.5);
    });

    test('半額免除のみ（100ヶ月）: 75ヶ月カウント', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        halfExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 100 × 3/4 = 75.0
      expect(input.effectiveContributionMonths, 75.0);
    });

    test('1/4免除のみ（100ヶ月）: 87.5ヶ月カウント', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        quarterExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 100 × 7/8 = 87.5
      expect(input.effectiveContributionMonths, 87.5);
    });
  });

  group('NationalPensionInput - 複数免除の組み合わせ計算', () {
    test('全額免除と3/4免除の混合', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 100,
        threeQuarterExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 240 + (100 × 1/2) + (100 × 5/8) = 240 + 50 + 62.5 = 352.5
      expect(input.effectiveContributionMonths, 352.5);
    });

    test('全額免除と半額免除の混合', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 80,
        halfExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 240 + (80 × 1/2) + (100 × 3/4) = 240 + 40 + 75 = 355
      expect(input.effectiveContributionMonths, 355.0);
    });

    test('全免除タイプを組み合わせ', () {
      final input = NationalPensionInput(
        fullContribution: 200,
        fullExempt: 80,
        threeQuarterExempt: 80,
        halfExempt: 80,
        quarterExempt: 40,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 200 + (80 × 1/2) + (80 × 5/8) + (80 × 3/4) + (40 × 7/8)
      // = 200 + 40 + 50 + 60 + 35
      // = 385
      expect(input.effectiveContributionMonths, 385.0);
    });

    test('480月に達する複合パターン', () {
      final input = NationalPensionInput(
        fullContribution: 300,
        fullExempt: 160,
        threeQuarterExempt: 40,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 300 + (160 × 1/2) + (40 × 5/8) = 300 + 80 + 25 = 405
      expect(input.effectiveContributionMonths, 405.0);
      expect(input.isValid(), true);
    });

    test('学生納付特例と免除の混合', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 100,
        studentDeferment: 48,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // 有効納付月数には studentDeferment は含まれない
      // = 240 + (100 × 1/2) = 240 + 50 = 290
      expect(input.effectiveContributionMonths, 290.0);
      expect(input.isValid(), true);
    });
  });

  group('NationalPensionInput - isValid() 決定表', () {
    test('有効: 全てデフォルト、年齢65', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('有効: 全額納付480ヶ月、年齢65', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('有効: 有効納付月数480月以内、年齢60', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 160,
        threeQuarterExempt: 160,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 60,
      );
      // effective = 240 + 80 + 100 = 420
      expect(input.isValid(), true);
    });

    test('有効: 有効納付月数480月以内、年齢75', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 75,
      );
      expect(input.isValid(), true);
    });

    test('有効: 学生納付特例を含む', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        studentDeferment: 48,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), true);
    });

    test('無効: 年齢59（下限未満）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 59,
      );
      expect(input.isValid(), false);
    });

    test('無効: 年齢76（上限超過）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 76,
      );
      expect(input.isValid(), false);
    });

    test('無効: 有効納付月数が481以上', () {
      final input = NationalPensionInput(
        fullContribution: 481,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), false);
    });

    test('無効: 負の納付月数', () {
      final input = NationalPensionInput(
        fullContribution: -1,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.isValid(), false);
    });

    test('無効: 複合で480月超過', () {
      final input2 = NationalPensionInput(
        fullContribution: 250,
        fullExempt: 462,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // effective = 250 + (462 × 1/2) = 250 + 231 = 481 (超過)
      expect(input2.isValid(), false);
    });
  });

  group('NationalPensionInput - getPensionAdjustmentRate()', () {
    test('60歳受給: 0.76（繰上げ5年）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 60,
      );
      expect(input.getPensionAdjustmentRate(), closeTo(0.76, 0.001));
    });

    test('62歳受給: 0.856（繰上げ3年）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 62,
      );
      expect(input.getPensionAdjustmentRate(), closeTo(0.856, 0.001));
    });

    test('64歳受給: 0.952（繰上げ1年）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 64,
      );
      expect(input.getPensionAdjustmentRate(), closeTo(0.952, 0.001));
    });

    test('65歳受給: 1.0（標準、減額なし）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.getPensionAdjustmentRate(), 1.0);
    });

    test('66歳受給: 1.084（繰下げ1年）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 66,
      );
      expect(input.getPensionAdjustmentRate(), closeTo(1.084, 0.001));
    });

    test('70歳受給: 1.42（繰下げ5年）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 70,
      );
      expect(input.getPensionAdjustmentRate(), closeTo(1.42, 0.001));
    });

    test('75歳受給: 1.84（繰下げ10年）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 75,
      );
      expect(input.getPensionAdjustmentRate(), closeTo(1.84, 0.001));
    });

    test('調整率は受給開始年齢のみに依存', () {
      final input1 = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 70,
      );
      final input2 = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 100,
        threeQuarterExempt: 80,
        halfExempt: 80,
        quarterExempt: 40,
        studentDeferment: 48,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 70,
      );
      expect(input1.getPensionAdjustmentRate(), input2.getPensionAdjustmentRate());
    });
  });

  group('NationalPensionInput - 基礎年金額定数', () {
    test('basicPensionMonthlyAmount: 69,308円', () {
      expect(NationalPensionInput.basicPensionMonthlyAmount, 69308.0);
    });

    test('getCurrentBasicPensionAmount(): 月額を返す', () {
      expect(
        NationalPensionInput.getCurrentBasicPensionAmount(),
        69308.0,
      );
    });

    test('getCurrentBasicPensionAnnualAmount(): 831,696円（月額×12）', () {
      expect(
        NationalPensionInput.getCurrentBasicPensionAnnualAmount(),
        831696.0,
      );
    });

    test('年額 = 月額 × 12の関係', () {
      expect(
        NationalPensionInput.getCurrentBasicPensionAnnualAmount(),
        NationalPensionInput.basicPensionMonthlyAmount * 12,
      );
    });
  });

  group('NationalPensionInput - クラス定数', () {
    test('pensionStartAge: 65歳', () {
      expect(NationalPensionInput.pensionStartAge, 65);
    });

    test('fullContributionMonths: 480ヶ月', () {
      expect(NationalPensionInput.fullContributionMonths, 480);
    });
  });

  group('NationalPensionInput - 実践的シナリオ', () {
    test('シナリオA: 失業経験（全額免除100ヶ月+納付380ヶ月）', () {
      final input = NationalPensionInput(
        fullContribution: 380,
        fullExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // effective = 380 + (100 × 1/2) = 380 + 50 = 430ヶ月
      expect(input.effectiveContributionMonths, 430.0);
      expect(input.isValid(), true);
      expect(input.getPensionAdjustmentRate(), 1.0);
    });

    test('シナリオB: 困窮期間（多様な免除+納付）', () {
      final input = NationalPensionInput(
        fullContribution: 300,
        fullExempt: 60,
        threeQuarterExempt: 60,
        halfExempt: 60,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      // effective = 300 + 30 + 37.5 + 45 = 412.5
      expect(input.effectiveContributionMonths, 412.5);
      expect(input.isValid(), true);
    });

    test('シナリオC: 60歳早期受給（免除混合）', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 80,
        threeQuarterExempt: 100,
        halfExempt: 60,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 60,
      );
      // effective = 240 + 40 + 62.5 + 45 = 387.5
      expect(input.effectiveContributionMonths, 387.5);
      expect(input.getPensionAdjustmentRate(), closeTo(0.76, 0.001));
      expect(input.isValid(), true);
    });

    test('シナリオD: 75歳繰下げ受給（免除混合）', () {
      final input = NationalPensionInput(
        fullContribution: 350,
        fullExempt: 80,
        threeQuarterExempt: 40,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 75,
      );
      // effective = 350 + 40 + 25 = 415
      expect(input.effectiveContributionMonths, 415.0);
      expect(input.getPensionAdjustmentRate(), closeTo(1.84, 0.001));
      expect(input.isValid(), true);
    });

    test('シナリオE: 完全フル納付（480ヶ月、65歳）', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.effectiveContributionMonths, 480.0);
      expect(input.getPensionAdjustmentRate(), 1.0);
      expect(input.isValid(), true);
    });

    test('シナリオF: 学生期間と後の納付（学生納付特例48ヶ月+納付432ヶ月）', () {
      final input = NationalPensionInput(
        fullContribution: 432,
        studentDeferment: 48,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      // 学生納付特例は effectiveContributionMonths に含まれない
      // effective = 432
      expect(input.effectiveContributionMonths, 432.0);
      expect(input.isValid(), true);
    });
  });

  group('NationalPensionInput - hasPaymentSuspension フラグ', () {
    test('免除期間がある場合、hasPaymentSuspension = true', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 100,
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      expect(input.hasPaymentSuspension, true);
      expect(input.isValid(), true);
    });

    test('免除期間がない場合、hasPaymentSuspension = false', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.hasPaymentSuspension, false);
      expect(input.isValid(), true);
    });
  });

  group('NationalPensionInput - 調整率の範囲', () {
    test('全年齢（60-75）で調整率が0.76～1.84の範囲内', () {
      for (int age = 60; age <= 75; age++) {
        final input = NationalPensionInput(
          fullContribution: 480,
          hasPaymentSuspension: false,
          desiredPensionStartAge: age,
        );
        final rate = input.getPensionAdjustmentRate();
        expect(rate, greaterThanOrEqualTo(0.76));
        expect(rate, lessThanOrEqualTo(1.84));
      }
    });

    test('60歳: 調整率 < 1.0', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 60,
      );
      expect(input.getPensionAdjustmentRate(), lessThan(1.0));
    });

    test('75歳: 調整率 > 1.0', () {
      final input = NationalPensionInput(
        fullContribution: 480,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 75,
      );
      expect(input.getPensionAdjustmentRate(), greaterThan(1.0));
    });
  });

  group('NationalPensionInput - 学生納付特例（studentDeferment）', () {
    test('学生納付特例のみ: effectiveContributionMonths に含まれない', () {
      final input = NationalPensionInput(
        fullContribution: 0,
        studentDeferment: 48,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      // 学生納付特例はカウントされない
      expect(input.effectiveContributionMonths, 0.0);
      expect(input.isValid(), true);
    });

    test('学生納付特例と納付の混合', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        studentDeferment: 48,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      // effective = 240（学生納付特例はカウントされない）
      expect(input.effectiveContributionMonths, 240.0);
      expect(input.isValid(), true);
    });
  });

  group('NationalPensionInput - optional フィールドのデフォルト値', () {
    test('全免除フィールドがデフォルト0', () {
      final input = NationalPensionInput(
        fullContribution: 100,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );
      expect(input.fullExempt, 0);
      expect(input.threeQuarterExempt, 0);
      expect(input.halfExempt, 0);
      expect(input.quarterExempt, 0);
      expect(input.studentDeferment, 0);
    });

    test('一部フィールドのみ指定', () {
      final input = NationalPensionInput(
        fullContribution: 240,
        fullExempt: 100,
        // その他はデフォルト
        hasPaymentSuspension: true,
        desiredPensionStartAge: 65,
      );
      expect(input.fullExempt, 100);
      expect(input.threeQuarterExempt, 0);
      expect(input.halfExempt, 0);
      expect(input.quarterExempt, 0);
      expect(input.studentDeferment, 0);
    });
  });

  group('NationalPensionInput - デシジョンテーブル (年齢と調整率)', () {
    // 【決定表】受給開始年齢 → 調整率の計算
    // 列: age, monthsDiff, 期待される計算式, 期待値
    final decisionTable = <Map<String, dynamic>>[
      {
        'age': 60,
        'months_diff': -60,
        'formula': '1.0 - (0.004 × 60) = 1.0 - 0.24 = 0.76',
        'expected': 0.76,
      },
      {
        'age': 61,
        'months_diff': -48,
        'formula': '1.0 - (0.004 × 48) = 1.0 - 0.192 = 0.808',
        'expected': 0.808,
      },
      {
        'age': 62,
        'months_diff': -36,
        'formula': '1.0 - (0.004 × 36) = 1.0 - 0.144 = 0.856',
        'expected': 0.856,
      },
      {
        'age': 64,
        'months_diff': -12,
        'formula': '1.0 - (0.004 × 12) = 1.0 - 0.048 = 0.952',
        'expected': 0.952,
      },
      {
        'age': 65,
        'months_diff': 0,
        'formula': '1.0 (標準受給)',
        'expected': 1.0,
      },
      {
        'age': 66,
        'months_diff': 12,
        'formula': '1.0 + (0.007 × 12) = 1.0 + 0.084 = 1.084',
        'expected': 1.084,
      },
      {
        'age': 68,
        'months_diff': 36,
        'formula': '1.0 + (0.007 × 36) = 1.0 + 0.252 = 1.252',
        'expected': 1.252,
      },
      {
        'age': 70,
        'months_diff': 60,
        'formula': '1.0 + (0.007 × 60) = 1.0 + 0.42 = 1.42',
        'expected': 1.42,
      },
      {
        'age': 75,
        'months_diff': 120,
        'formula': '1.0 + (0.007 × 120) = 1.0 + 0.84 = 1.84',
        'expected': 1.84,
      },
    ];

    for (final row in decisionTable) {
      test('年齢 ${row['age']}: ${row['formula']} → ${row['expected']}', () {
        final input = NationalPensionInput(
          fullContribution: 480,
          hasPaymentSuspension: false,
          desiredPensionStartAge: row['age'] as int,
        );
        expect(
          input.getPensionAdjustmentRate(),
          closeTo(row['expected'] as double, 0.001),
        );
      });
    }
  });

  group('NationalPensionInput - デシジョンテーブル (isValid() 条件)', () {
    // 【決定表】複数条件の組み合わせによる妥当性チェック
    // 列: fullContribution, exemption, age, 期待値, 説明
    final decisionTable = <Map<String, dynamic>>[
      // 有効なケース（✓）
      {
        'fullContribution': 0,
        'fullExempt': 0,
        'age': 65,
        'expected': true,
        'desc': '✓ 最小有効: 全ゼロ、年齢65',
      },
      {
        'fullContribution': 480,
        'fullExempt': 0,
        'age': 65,
        'expected': true,
        'desc': '✓ 最大有効: フル納付480月、年齢65',
      },
      {
        'fullContribution': 240,
        'fullExempt': 0,
        'age': 60,
        'expected': true,
        'desc': '✓ 年齢下限: 年齢60（下限OK）',
      },
      {
        'fullContribution': 240,
        'fullExempt': 0,
        'age': 75,
        'expected': true,
        'desc': '✓ 年齢上限: 年齢75（上限OK）',
      },
      {
        'fullContribution': 300,
        'fullExempt': 360,
        'age': 65,
        'expected': true,
        'desc': '✓ 免除混合: 300 + (360 × 1/2) = 480',
      },

      // 無効なケース（✗）
      {
        'fullContribution': -1,
        'fullExempt': 0,
        'age': 65,
        'expected': false,
        'desc': '✗ 負の納付月数: fullContribution < 0',
      },
      {
        'fullContribution': 481,
        'fullExempt': 0,
        'age': 65,
        'expected': false,
        'desc': '✗ 有効月数超過: 481 > 480',
      },
      {
        'fullContribution': 240,
        'fullExempt': -10,
        'age': 65,
        'expected': false,
        'desc': '✗ 負の免除月数: fullExempt < 0',
      },
      {
        'fullContribution': 240,
        'fullExempt': 0,
        'age': 59,
        'expected': false,
        'desc': '✗ 年齢下限未満: 59 < 60',
      },
      {
        'fullContribution': 240,
        'fullExempt': 0,
        'age': 76,
        'expected': false,
        'desc': '✗ 年齢上限超過: 76 > 75',
      },
      {
        'fullContribution': 250,
        'fullExempt': 462,
        'age': 65,
        'expected': false,
        'desc': '✗ 複合超過: 250 + (462 × 1/2) = 481 > 480',
      },
    ];

    for (final row in decisionTable) {
      test(row['desc'] as String, () {
        final input = NationalPensionInput(
          fullContribution: row['fullContribution'] as int,
          fullExempt: row['fullExempt'] as int,
          hasPaymentSuspension: (row['fullExempt'] as int) > 0 ? true : false,
          desiredPensionStartAge: row['age'] as int,
        );
        expect(input.isValid(), row['expected'] as bool);
      });
    }
  });
}
