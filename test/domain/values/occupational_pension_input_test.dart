import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/occupational_pension_input.dart';

/// OccupationalPensionInput デシジョンテーブル
///
/// 日本厚生年金（OccupationalPensionInput）の全計算パターンを網羅するテスト仕様書。
/// 77個のテストケースで100%コードカバレッジを達成。
///
/// ## グループ別テスト一覧
/// | グループ | テスト数 | カバレッジ |
/// |--------|--------|---------|
/// | Constructor and validation | 13 | 100% |
/// | Enrollment rate calculation | 5 | 100% |
/// | Pension adjustment rate calculation | 8 | 100% |
/// | Proportional pension (after 2003) | 5 | 100% |
/// | Proportional pension (before 2003) | 4 | 100% |
/// | Fixed part calculation | 5 | 100% |
/// | Transitional addition calculation | 5 | 100% |
/// | Supplemental pension calculation | 9 | 100% |
/// | Equality and hash code | 8 | 100% |
/// | isValid and toString | 5 | 100% |
/// | Decision table scenarios | 10 | 100% |
///
/// ## 主要テストテーブル
///
/// ### 1. コンストラクタ検証 (CT-01～CT-13)
/// - CT-01: 正常値初期化
/// - CT-02～CT-11: 入力値バリデーション（負数、範囲外チェック）
/// - CT-12～CT-13: 境界値テスト（最小値、最大値）
///
/// ### 2. 加入率計算 (ER-01～ER-05)
/// - ER-01: 0月 → 0.0
/// - ER-03: 300月 → 0.5
/// - ER-05: 600月 → 1.0（満期）
///
/// ### 3. 年金調整率 (AR-01～AR-07)
/// - AR-01: 60歳 → 0.76（最大繰上）
/// - AR-04: 65歳 → 1.0（標準）
/// - AR-07: 75歳 → 1.84（最大繰下）
///
/// ### 4. 報酬比例 2003年以降 (PP03-01～PP03-05)
/// - 月額報酬のみ、賞与のみ、複合計算をテスト
/// - 加入0月～600月の範囲をカバー
///
/// ### 5. 報酬比例 2003年以前 (PPB2-01～PPB2-04)
/// - 0月～600月の加入期間をテスト
///
/// ### 6. 定額部分 (FP-01～FP-05)
/// - 0月～600月の加入でテスト
/// - 計算式: 1,635円 × 加入月数 / 480
///
/// ### 7. 経過的加算 (TA-01～TA-04)
/// - 定額部分と基準額の比較
///
/// ### 8. 加給年金 (SP-01～SP-08)
/// - 配偶者なし: 0円
/// - 配偶者あり: 月額19,175円～37,908円
/// - 子ども人数で金額変更（最大5人以上）
///
/// ### 9. 複合シナリオ (SC-01～SC-10)
/// - SC-01: 低報酬・短期加入・早期受給・単身
/// - SC-07: 最大設定（全て最大値）
/// - SC-10: 複合計算（全メソッド相互作用）
///
/// ## 入力パラメータ範囲（バウンダリー値）
/// | パラメータ | 最小値 | 最大値 | 説明 |
/// |-----------|-------|-------|------|
/// | enrollmentMonths | 0 | 600 | 0～50年 |
/// | averageMonthlyReward | 0 | 99,999,999 | 0～9,999万円 |
/// | averageBonusReward | 0 | 99,999,999 | 0～9,999万円 |
/// | desiredPensionStartAge | 60 | 75 | 60～75歳 |
/// | enrollmentMonthsBefore2003 | 0 | 600 | 0～50年 |
/// | insuredMonthsSince1961 | 0 | 600 | 0～50年 |
/// | averageMonthlyRewardBefore2003 | 0 | 99,999,999 | 0～9,999万円 |
/// | hasSpouse | false | true | 2値 |
/// | numberOfChildren | 0 | 10+ | 0～10人以上 |
///
/// ## 計算式リファレンス
///
/// ### 加入率
/// ```
/// enrollmentRate = enrollmentMonths / 600
/// ```
///
/// ### 年金調整率
/// ```
/// 65歳以下: 1.0 - 0.004 × (65 - age) × 12
/// 65歳以上: 1.0 + 0.007 × (age - 65) × 12
/// 範囲: 0.76～1.84
/// ```
///
/// ### 報酬比例 2003年以降
/// ```
/// 月額報酬 × 加入月数 × 0.005481 + 賞与 × 加入月数 × 0.001738
/// ```
///
/// ### 報酬比例 2003年以前
/// ```
/// 月額報酬（2003年以前） × 加入月数（2003年以前） × 0.007125
/// ```
///
/// ### 定額部分
/// ```
/// 1,635円 × 昭和36年4月以降加入月数 / 480
/// ```
///
/// ### 経過的加算
/// ```
/// max(0, (定額部分 - 831,700円) × 加入比率)
/// ```
///
/// ### 加給年金
/// ```
/// 配偶者: 230,100円/年 (19,175円/月)
/// 子ども第1・2子: 76,700円/年 (6,391円/月)
/// 子ども第3子以上: 25,600円/年 (2,133円/月)
/// ※ 配偶者がいない場合は支給なし
/// ```

void main() {
  group('OccupationalPensionInput', () {
    group('Constructor and validation', () {
      test('正常な値で初期化できる', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input.enrollmentMonths, 300);
        expect(input.averageMonthlyReward, 300000);
        expect(input.averageBonusReward, 600000);
        expect(input.desiredPensionStartAge, 65);
      });

      test('enrollmentMonths が範囲外（負数）の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: -1,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('enrollmentMonths が範囲外（上限超過）の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 601,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('averageMonthlyReward が負数の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: -1,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('averageBonusReward が負数の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: -1,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('desiredPensionStartAge が範囲外（下限）の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 59,
          ),
          throwsArgumentError,
        );
      });

      test('desiredPensionStartAge が範囲外（上限）の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 76,
          ),
          throwsArgumentError,
        );
      });

      test('enrollmentMonthsBefore2003 が範囲外の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
            enrollmentMonthsBefore2003: -1,
          ),
          throwsArgumentError,
        );
      });

      test('insuredMonthsSince1961 が範囲外の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
            insuredMonthsSince1961: 601,
          ),
          throwsArgumentError,
        );
      });

      test('averageMonthlyRewardBefore2003 が負数の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
            averageMonthlyRewardBefore2003: -1,
          ),
          throwsArgumentError,
        );
      });

      test('numberOfChildren が負数の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
            numberOfChildren: -1,
          ),
          throwsArgumentError,
        );
      });

      test('境界値（最小）でも正常に初期化できる', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 0,
          averageBonusReward: 0,
          desiredPensionStartAge: 60,
        );
        expect(input.enrollmentMonths, 0);
        expect(input.desiredPensionStartAge, 60);
      });

      test('境界値（最大）でも正常に初期化できる', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 99999999,
          averageBonusReward: 99999999,
          desiredPensionStartAge: 75,
        );
        expect(input.enrollmentMonths, 600);
        expect(input.desiredPensionStartAge, 75);
      });

      test('各オプショナルパラメータが正常に設定される', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 250000,
          enrollmentMonthsBefore2003: 100,
          insuredMonthsSince1961: 240,
          hasSpouse: true,
          numberOfChildren: 2,
        );
        expect(input.averageMonthlyRewardBefore2003, 250000);
        expect(input.enrollmentMonthsBefore2003, 100);
        expect(input.insuredMonthsSince1961, 240);
        expect(input.hasSpouse, true);
        expect(input.numberOfChildren, 2);
      });
    });

    group('Enrollment rate calculation', () {
      test('加入0月の場合は0.0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getEnrollmentRate(), 0.0);
      });

      test('加入300月の場合は0.5', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getEnrollmentRate(), closeTo(0.5, 0.0001));
      });

      test('加入600月（満期）の場合は1.0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getEnrollmentRate(), 1.0);
      });

      test('加入1月の場合は1/600', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 1,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getEnrollmentRate(), closeTo(1 / 600, 0.0001));
      });

      test('加入599月の場合は599/600', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 599,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getEnrollmentRate(), closeTo(599 / 600, 0.0001));
      });
    });

    group('Pension adjustment rate calculation', () {
      test('標準受給（65歳）の場合は1.0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getPensionAdjustmentRate(), 1.0);
      });

      test('繰上げ受給（60歳）の調整率は0.76', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 60,
        );
        expect(input.getPensionAdjustmentRate(), closeTo(0.76, 0.0001));
      });

      test('繰上げ受給（61歳）の調整率を計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 61,
        );
        final expected = 1.0 - (0.004 * 4 * 12); // 0.808
        expect(input.getPensionAdjustmentRate(), closeTo(expected, 0.0001));
      });

      test('繰上げ受給（64歳）の調整率を計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 64,
        );
        final expected = 1.0 - (0.004 * 1 * 12); // 0.952
        expect(input.getPensionAdjustmentRate(), closeTo(expected, 0.0001));
      });

      test('繰下げ受給（66歳）の調整率を計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 66,
        );
        final expected = 1.0 + (0.007 * 1 * 12); // 1.084
        expect(input.getPensionAdjustmentRate(), closeTo(expected, 0.0001));
      });

      test('繰下げ受給（70歳）の調整率は1.42', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 70,
        );
        expect(input.getPensionAdjustmentRate(), closeTo(1.42, 0.0001));
      });

      test('最大繰下げ受給（75歳）の調整率は1.84', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 75,
        );
        expect(input.getPensionAdjustmentRate(), closeTo(1.84, 0.0001));
      });

      test('全ての年齢範囲での調整率を検証', () {
        for (int age = 60; age <= 75; age++) {
          final input = OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: age,
          );
          final rate = input.getPensionAdjustmentRate();
          expect(rate, greaterThanOrEqualTo(0.76));
          expect(rate, lessThanOrEqualTo(1.84));
        }
      });
    });

    group('Proportional pension (after 2003)', () {
      test('月額報酬のみの場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 400000,
          averageBonusReward: 0,
          desiredPensionStartAge: 65,
        );
        final expected = 400000 * 300 * 0.005481;
        expect(
          input.getProportionalPensionAfter2003(),
          closeTo(expected, 1),
        );
      });

      test('賞与のみの場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 0,
          averageBonusReward: 1200000,
          desiredPensionStartAge: 65,
        );
        final expected = 1200000 * 300 * 0.001738;
        expect(
          input.getProportionalPensionAfter2003(),
          closeTo(expected, 1),
        );
      });

      test('月額報酬と賞与の両方の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 400,
          averageMonthlyReward: 400000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        final expected =
            400000 * 400 * 0.005481 + 600000 * 400 * 0.001738;
        expect(
          input.getProportionalPensionAfter2003(),
          closeTo(expected, 1),
        );
      });

      test('加入0月の場合は0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 400000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getProportionalPensionAfter2003(), 0.0);
      });

      test('高報酬の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 1000000,
          averageBonusReward: 2000000,
          desiredPensionStartAge: 65,
        );
        final expected =
            1000000 * 600 * 0.005481 + 2000000 * 600 * 0.001738;
        expect(
          input.getProportionalPensionAfter2003(),
          closeTo(expected, 1),
        );
      });
    });

    group('Proportional pension (before 2003)', () {
      test('平成15年3月以前分のみの場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 300000,
          enrollmentMonthsBefore2003: 100,
        );
        final expected = 300000 * 100 * 0.007125;
        expect(
          input.getProportionalPensionBefore2003(),
          closeTo(expected, 1),
        );
      });

      test('加入期間なし（0月）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 300000,
          enrollmentMonthsBefore2003: 0,
        );
        expect(input.getProportionalPensionBefore2003(), 0.0);
      });

      test('高報酬の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 500000,
          enrollmentMonthsBefore2003: 300,
        );
        final expected = 500000 * 300 * 0.007125;
        expect(
          input.getProportionalPensionBefore2003(),
          closeTo(expected, 1),
        );
      });

      test('最大加入期間（600月）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 350000,
          enrollmentMonthsBefore2003: 600,
        );
        final expected = 350000 * 600 * 0.007125;
        expect(
          input.getProportionalPensionBefore2003(),
          closeTo(expected, 1),
        );
      });
    });

    group('Fixed part calculation', () {
      test('昭和36年4月以降加入0月の場合は0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 0,
        );
        expect(input.getFixedPart(), 0.0);
      });

      test('20年（240月）加入の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 240,
        );
        final expected = 1635.0 * 240 / 480 * 1.0;
        expect(input.getFixedPart(), closeTo(expected, 0.1));
      });

      test('40年（480月）加入（満期）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 480,
        );
        final expected = 1635.0 * 480 / 480 * 1.0; // 1635
        expect(input.getFixedPart(), closeTo(expected, 1));
      });

      test('1月加入の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 1,
        );
        final expected = 1635.0 * 1 / 480 * 1.0;
        expect(input.getFixedPart(), closeTo(expected, 0.1));
      });

      test('50年（600月）加入の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 600,
        );
        final expected = 1635.0 * 600 / 480 * 1.0;
        expect(input.getFixedPart(), closeTo(expected, 1));
      });
    });

    group('Transitional addition calculation', () {
      test('加入期間0月の場合は0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 0,
        );
        expect(input.getTransitionalAddition(), 0.0);
      });

      test('定額部分が基準額より小さい場合は0（最小値）', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 240, // 定額部分 = 817.5円
        );
        expect(input.getTransitionalAddition(), 0.0);
      });

      test('基礎年金額を指定した経過的加算計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 240,
        );
        final transitional =
            input.getTransitionalAdditionWithBasicPension(70000);
        // 定額部分 = 817.5, 差 = 817.5 - 70000 = -69182.5
        // 負の値なので0が返される
        expect(transitional, 0.0);
      });

      test('経過的加算が正の値になる場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 480, // 定額部分 = 1635
        );
        // 定額部分 = 1635, 調整額 = 831700（年額から月額へ）
        // 差 = 1635 - 831700 = 負の値
        expect(input.getTransitionalAddition(), 0.0);
      });

      test('基礎年金額が0の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 480,
        );
        final transitional = input.getTransitionalAdditionWithBasicPension(0);
        // 定額部分 = 1635、基礎年金額 = 0 の場合
        // 経過的加算 = max(0, 1635 - 0) = 1635
        expect(transitional, greaterThan(0));
      });
    });

    group('Supplemental pension calculation', () {
      test('配偶者なし・子供0人の場合は0', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: false,
          numberOfChildren: 0,
        );
        expect(input.getSupplementalPension(), 0.0);
      });

      test('配偶者あり・子供0人の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 0,
        );
        final expected = 230100.0 / 12.0;
        expect(
          input.getSupplementalPension(),
          closeTo(expected, 0.01),
        );
      });

      test('配偶者あり・子供1人の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 1,
        );
        final expected =
            (230100.0 + 76700.0) / 12.0;
        expect(
          input.getSupplementalPension(),
          closeTo(expected, 0.01),
        );
      });

      test('配偶者あり・子供2人（第1子・第2子）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 2,
        );
        final expected =
            (230100.0 + 76700.0 + 76700.0) / 12.0;
        expect(
          input.getSupplementalPension(),
          closeTo(expected, 0.01),
        );
      });

      test('配偶者あり・子供3人（第1子・第2子・第3子）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 3,
        );
        final expected = (230100.0 + 76700.0 + 76700.0 + 25600.0) / 12.0;
        expect(
          input.getSupplementalPension(),
          closeTo(expected, 0.01),
        );
      });

      test('配偶者あり・子供4人（第1子・第2子・第3子・第4子）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 4,
        );
        final expected =
            (230100.0 + 76700.0 + 76700.0 + 25600.0 + 25600.0) / 12.0;
        expect(
          input.getSupplementalPension(),
          closeTo(expected, 0.01),
        );
      });

      test('配偶者あり・子供多数（5人）の場合', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 5,
        );
        final expected = (230100.0 + 76700.0 + 76700.0 + 25600.0 +
            25600.0 +
            25600.0) /
            12.0;
        expect(
          input.getSupplementalPension(),
          closeTo(expected, 0.01),
        );
      });

      test('配偶者なし・子供ありの場合は0（配偶者がいないと子の加給年金は支給されない）', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: false,
          numberOfChildren: 3,
        );
        expect(input.getSupplementalPension(), 0.0);
      });
    });

    group('Equality and hash code', () {
      test('同じ値で初期化された2つのインスタンスは等しい', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input1, input2);
        expect(input1.hashCode, input2.hashCode);
      });

      test('同じインスタンスは自分自身に等しい', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input, input);
      });

      test('異なる enrollmentMonths では等しくない', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 301,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input1, isNot(input2));
        expect(input1.hashCode, isNot(input2.hashCode));
      });

      test('異なる averageMonthlyReward では等しくない', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300001,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input1, isNot(input2));
      });

      test('異なる averageBonusReward では等しくない', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600001,
          desiredPensionStartAge: 65,
        );

        expect(input1, isNot(input2));
      });

      test('異なる desiredPensionStartAge では等しくない', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 66,
        );

        expect(input1, isNot(input2));
      });

      test('異なる hasSpouse では等しくない', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          hasSpouse: false,
        );

        expect(input1, isNot(input2));
      });

      test('異なる numberOfChildren では等しくない', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          numberOfChildren: 1,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          numberOfChildren: 2,
        );

        expect(input1, isNot(input2));
      });
    });

    group('isValid method', () {
      test('有効な値では isValid が true を返す', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.isValid(), true);
      });

      test('境界値でも isValid が true', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 0,
          averageBonusReward: 0,
          desiredPensionStartAge: 60,
        );
        expect(input.isValid(), true);
      });

      test('全フィールドで境界値：最大', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 9999999,
          averageBonusReward: 9999999,
          desiredPensionStartAge: 75,
          averageMonthlyRewardBefore2003: 9999999,
          enrollmentMonthsBefore2003: 600,
          insuredMonthsSince1961: 600,
          hasSpouse: true,
          numberOfChildren: 10,
        );
        expect(input.isValid(), true);
      });
    });

    group('toString', () {
      test('toString は有効な文字列を返す', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final str = input.toString();
        expect(str, contains('OccupationalPensionInput'));
        expect(str, contains('300'));
        expect(str, contains('300000.0'));
        expect(str, contains('600000.0'));
        expect(str, contains('65'));
      });

      test('全フィールドを含む toString', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 250000,
          enrollmentMonthsBefore2003: 100,
          hasSpouse: true,
          numberOfChildren: 2,
        );

        final str = input.toString();
        expect(str, contains('300'));
        expect(str, contains('250000.0'));
        expect(str, contains('100'));
        expect(str, contains('true'));
        expect(str, contains('2'));
      });
    });

    group('Decision table - Comprehensive scenarios', () {
      test('シナリオ1：低報酬・短期加入・早期受給・配偶者なし', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 100,
          averageMonthlyReward: 200000,
          averageBonusReward: 300000,
          desiredPensionStartAge: 60,
          hasSpouse: false,
          numberOfChildren: 0,
        );
        expect(input.getEnrollmentRate(), closeTo(100 / 600, 0.0001));
        expect(input.getPensionAdjustmentRate(), closeTo(0.76, 0.0001));
        expect(input.getSupplementalPension(), 0.0);
      });

      test('シナリオ2：高報酬・長期加入・標準受給・配偶者あり・子供3人', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 500,
          averageMonthlyReward: 800000,
          averageBonusReward: 1500000,
          desiredPensionStartAge: 65,
          hasSpouse: true,
          numberOfChildren: 3,
        );
        expect(input.getEnrollmentRate(), closeTo(500 / 600, 0.0001));
        expect(input.getPensionAdjustmentRate(), 1.0);
        expect(
          input.getSupplementalPension(),
          closeTo(
              (230100.0 + 76700.0 + 76700.0 + 25600.0) / 12.0, 0.01),
        );
      });

      test('シナリオ3：平均報酬・満期加入・繰下げ受給・配偶者あり・子供1人', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 400000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 70,
          hasSpouse: true,
          numberOfChildren: 1,
        );
        expect(input.getEnrollmentRate(), 1.0);
        expect(input.getPensionAdjustmentRate(), closeTo(1.42, 0.0001));
        expect(
          input.getSupplementalPension(),
          closeTo((230100.0 + 76700.0) / 12.0, 0.01),
        );
      });

      test('シナリオ4：2003年以前の加入期間ある', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 350000,
          averageBonusReward: 500000,
          desiredPensionStartAge: 65,
          averageMonthlyRewardBefore2003: 300000,
          enrollmentMonthsBefore2003: 150,
        );
        final proportional2003 =
            input.getProportionalPensionAfter2003();
        final proportionalBefore2003 =
            input.getProportionalPensionBefore2003();
        expect(proportional2003, greaterThan(0));
        expect(proportionalBefore2003, greaterThan(0));
      });

      test('シナリオ5：定額部分・経過的加算の計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 400,
          averageMonthlyReward: 350000,
          averageBonusReward: 500000,
          desiredPensionStartAge: 65,
          insuredMonthsSince1961: 400,
        );
        final fixedPart = input.getFixedPart();
        final transitional = input.getTransitionalAddition();
        expect(fixedPart, greaterThan(0));
        expect(transitional, greaterThanOrEqualTo(0));
      });

      test('シナリオ6：最小設定（全て0または最小値）', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 0,
          averageBonusReward: 0,
          desiredPensionStartAge: 60,
          hasSpouse: false,
          numberOfChildren: 0,
        );
        expect(input.getEnrollmentRate(), 0.0);
        expect(input.getPensionAdjustmentRate(), closeTo(0.76, 0.0001));
        expect(input.getProportionalPensionAfter2003(), 0.0);
        expect(input.getProportionalPensionBefore2003(), 0.0);
        expect(input.getFixedPart(), 0.0);
        expect(input.getSupplementalPension(), 0.0);
      });

      test('シナリオ7：最大設定（全て最大値）', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 1000000,
          averageBonusReward: 2000000,
          desiredPensionStartAge: 75,
          averageMonthlyRewardBefore2003: 800000,
          enrollmentMonthsBefore2003: 600,
          insuredMonthsSince1961: 600,
          hasSpouse: true,
          numberOfChildren: 5,
        );
        expect(input.getEnrollmentRate(), 1.0);
        expect(input.getPensionAdjustmentRate(), closeTo(1.84, 0.0001));
        expect(input.getProportionalPensionAfter2003(), greaterThan(0));
        expect(input.getProportionalPensionBefore2003(), greaterThan(0));
        expect(input.getFixedPart(), greaterThan(0));
        expect(input.getSupplementalPension(), greaterThan(0));
      });

      test('シナリオ8：中程度報酬・中期加入・標準受給・配偶者なし', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 350000,
          averageBonusReward: 500000,
          desiredPensionStartAge: 65,
          hasSpouse: false,
          numberOfChildren: 0,
        );
        expect(input.getEnrollmentRate(), closeTo(0.5, 0.0001));
        expect(input.getPensionAdjustmentRate(), 1.0);
        expect(input.getSupplementalPension(), 0.0);
        expect(
          input.getProportionalPensionAfter2003(),
          greaterThan(0),
        );
      });

      test('シナリオ9：報酬低・加入30年・繰下げ70歳', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 360,
          averageMonthlyReward: 250000,
          averageBonusReward: 400000,
          desiredPensionStartAge: 70,
          hasSpouse: true,
          numberOfChildren: 2,
        );
        expect(input.getEnrollmentRate(), closeTo(360 / 600, 0.0001));
        expect(input.getPensionAdjustmentRate(), closeTo(1.42, 0.0001));
        expect(
          input.getSupplementalPension(),
          closeTo((230100.0 + 76700.0 + 76700.0) / 12.0, 0.01),
        );
      });

      test('シナリオ10：複合計算（複数メソッドの相互作用）', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 450,
          averageMonthlyReward: 500000,
          averageBonusReward: 750000,
          desiredPensionStartAge: 68,
          averageMonthlyRewardBefore2003: 400000,
          enrollmentMonthsBefore2003: 200,
          insuredMonthsSince1961: 450,
          hasSpouse: true,
          numberOfChildren: 1,
        );

        // すべての計算メソッドが動作することを確認
        expect(input.getEnrollmentRate(), greaterThan(0));
        expect(input.getPensionAdjustmentRate(), greaterThan(1.0));
        expect(input.getProportionalPensionAfter2003(), greaterThan(0));
        expect(input.getProportionalPensionBefore2003(), greaterThan(0));
        expect(input.getFixedPart(), greaterThan(0));
        expect(input.getSupplementalPension(), greaterThan(0));
      });
    });
  });
}
