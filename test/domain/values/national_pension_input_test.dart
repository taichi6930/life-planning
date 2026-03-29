import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/national_pension_input.dart';

/// ## デシジョンテーブル（NationalPensionInput テストスイート）
///
/// 国民年金計算入力の検証ロジックを複数の条件組み合わせで網羅的にテスト
///
/// ### A. 基本フィールド検証（fullContribution / exemption fields）
///
/// | No | fullContribution | exemptionFields | 期待される動作                     |
/// |----|-----------------|-----------------|----------------------------------|
/// | A1 | 0               | 全て 0          | isValid() = true（最小有効）      |
/// | A2 | -1              | 0               | isValid() = false（負数検出）     |
/// | A3 | 480             | 0               | isValid() = true（最大納付）      |
/// | A4 | 240             | fullExempt=100  | isValid() = true（mixed）        |
/// | A5 | 240             | fullExempt=-10  | isValid() = false（負の免除）     |
/// | A6 | 300             | fullExempt=-1   | isValid() = false（セキュリティ）|
///
/// ### B. 有効納付月数計算（effectiveContributionMonths）
///
/// | No | fullContribution | fullExempt | threeQuarter | half  | quarter | studentDeferment | 期待値                      |
/// |----|-----------------|------------|-------------|-------|---------|------------------|---------------------------|
/// | B1 | 0               | 0          | 0           | 0     | 0       | 0                | 0.0                       |
/// | B2 | 100             | 0          | 0           | 0     | 0       | 0                | 100.0（フル納付のみ）       |
/// | B3 | 0               | 100        | 0           | 0     | 0       | 0                | 50.0（100 × 1/2）          |
/// | B4 | 0               | 0          | 100         | 0     | 0       | 0                | 62.5（100 × 5/8）          |
/// | B5 | 0               | 0          | 0           | 100   | 0       | 0                | 75.0（100 × 3/4）          |
/// | B6 | 0               | 0          | 0           | 0     | 100     | 0                | 87.5（100 × 7/8）          |
/// | B7 | 240             | 100        | 0           | 0     | 0       | 0                | 290.0（混合計算）           |
/// | B8 | 300             | 80         | 80          | 80    | 40      | 0                | 385.0（全タイプ混合）       |
/// | B9 | 240             | 100        | 0           | 0     | 0       | 48               | 290.0（studentDeferment非計上）|
///
/// ### C. isValid() 複合条件（年齢 × 有効月数）
///
/// | No | age | effective | 期待される動作                    |
/// |----|-----|-----------|----------------------------------|
/// | C1 | 65  | 0         | true（標準受給、最小納付）        |
/// | C2 | 65  | 480       | true（標準受給、最大納付）        |
/// | C3 | 60  | 240       | true（早期受給下限OK）            |
/// | C4 | 75  | 240       | true（繰下げ受給上限OK）          |
/// | C5 | 59  | 240       | false（年齢下限未満）             |
/// | C6 | 76  | 240       | false（年齢上限超過）             |
/// | C7 | 65  | 481       | false（有効月数超過480月）        |
/// | C8 | 65  | -1        | false（負の有効月数）             |
/// | C9 | 60  | 480       | true（早期受給+フル納付）         |
/// | C10| 75  | 480       | true（繰下げ受給+フル納付）      |
///
/// ### D. getPensionAdjustmentRate() 調整率計算（年齢別）
///
/// | No | desiredAge | monthsDiff | 計算式（abbreviation）         | 期待値 |
/// |----|-----------|-----------|------------------------------|--------|
/// | D1 | 60        | -60       | 1.0 - (0.004 × 60)           | 0.76   |
/// | D2 | 62        | -36       | 1.0 - (0.004 × 36)           | 0.856  |
/// | D3 | 64        | -12       | 1.0 - (0.004 × 12)           | 0.952  |
/// | D4 | 65        | 0         | 1.0（標準受給）                | 1.0    |
/// | D5 | 66        | 12        | 1.0 + (0.007 × 12)           | 1.084  |
/// | D6 | 68        | 36        | 1.0 + (0.007 × 36)           | 1.252  |
/// | D7 | 70        | 60        | 1.0 + (0.007 × 60)           | 1.42   |
/// | D8 | 75        | 120       | 1.0 + (0.007 × 120)          | 1.84   |
///
/// ### E. 境界値テスト（boundary conditions）
///
/// | No | テスト対象           | 入力値    | 期待される動作              |
/// |----|---------------------|---------|---------------------------|
/// | E1 | fullContribution     | 0       | 有効（下限境界）            |
/// | E2 | fullContribution     | 480     | 有効（上限境界）            |
/// | E3 | fullContribution     | 481     | 無効（上限超過）            |
/// | E4 | desiredPensionStartAge| 60      | 有効（下限境界）            |
/// | E5 | desiredPensionStartAge| 75      | 有効（上限境界）            |
/// | E6 | desiredPensionStartAge| 59      | 無効（下限未満）            |
/// | E7 | desiredPensionStartAge| 76      | 無効（上限超過）            |
/// | E8 | effectiveContribution| 480     | 有効（上限境界）            |
/// | E9 | effectiveContribution| 480.1   | 無効（上限超過）            |
///
/// ### F. 実践的シナリオ（real-world use cases）
///
/// | No | シナリオ             | 組み合わせ条件                              | 期待される動作       |
/// |----|---------------------|------------------------------------------|------------------|
/// | F1 | 失業&免除経験        | fullContribution=380, fullExempt=100      | isValid()=true   |
/// | F2 | 学生期間含む         | fullContribution=432, studentDeferment=48 | effective=432    |
/// | F3 | 多様な免除タイプ      | 全exemption fieldsを使用                  | 複雑な計算検証    |
/// | F4 | 限界事例：ちょうど480月 | fullContribution=300, fullExempt=360     | effective=480    |
/// | F5 | 早期受給シナリオ      | age=60, fullContribution=240              | adjust=0.76      |
/// | F6 | 繰下げ受給シナリオ    | age=75, fullContribution=240              | adjust=1.84      |
///
/// ### G. 負の値セキュリティテスト（negative value security）
///
/// | No | フィールド                        | 入力値 | 期待される動作      |
/// |----|----------------------------------|--------|------------------|
/// | G1 | fullContribution                 | -1     | isValid()=false   |
/// | G2 | fullExempt                       | -10    | isValid()=false   |
/// | G3 | threeQuarterExempt               | -5     | isValid()=false   |
/// | G4 | halfExempt                       | -20    | isValid()=false   |
/// | G5 | quarterExempt                    | -5     | isValid()=false   |
/// | G6 | studentDeferment                 | -20    | isValid()=false   |

void main() {
  /// ### A. 基本フィールド検証（fullContribution / exemption fields）
  ///
  /// | No | fullContribution | exemptionValue | 期待される動作                     |
  /// |----|-----------------|----------------|----------------------------------|
  /// | A1 | 0               | 0（全て）      | isValid() = true（最小有効）      |
  /// | A2 | 240             | 0              | isValid() = true（正の値）        |
  /// | A3 | 480             | 0              | isValid() = true（フル納付）      |
  /// | A4 | -1              | 0              | isValid() = false（負数検出）     |
  /// | A5 | 240             | fullExempt=100 | isValid() = true（混合）          |
  /// | A6 | 240             | fullExempt=-10 | isValid() = false（負の免除）     |
  /// | A7 | 240             | quarterExempt=-5 | isValid() = false（セキュリティ）|
  /// | A8 | 240             | studentDeferment=-20 | isValid() = false（負の学生納付）|
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
    /// ### B1. 全額免除パターン（fullExempt のみを使用）
    ///
    /// | No | fullContribution | fullExempt | 計算式              | 期待値  |
    /// |----|-----------------|------------|-------------------|--------|
    /// | B1 | 0               | 0          | 0                 | 0.0    |
    /// | B2 | 0               | 100        | 100 × 1/2 = 50    | 50.0   |
    /// | B3 | 240             | 100        | 240 + (100 × 1/2) | 290.0  |
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
    /// ### B2. 各免除タイプ別の計算
    ///
    /// | No | fullContribution | exemptionType     | 月数 | 計算式          | 期待値   |
    /// |----|-----------------|-------------------|------|---------------|---------|
    /// | B2a| 0               | threeQuarterExempt| 100  | 100 × 5/8 = 62.5 | 62.5  |
    /// | B2b| 0               | halfExempt        | 100  | 100 × 3/4 = 75   | 75.0  |
    /// | B2c| 0               | quarterExempt     | 100  | 100 × 7/8 = 87.5 | 87.5  |
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
    /// ### B3. 複数の免除タイプを組み合わせ
    ///
    /// | No | fullContribution | fullExempt | threeQuarter | half | quarter | studentDeferment | 計算式                                | 期待値  |
    /// |----|-----------------|------------|-------------|------|---------|-----------------|--------------------------------------|--------|
    /// | B3a| 240             | 100        | 0           | 0    | 0       | 0               | 240 + 50 = 290                       | 290.0  |
    /// | B3b| 240             | 80         | 0           | 100  | 0       | 0               | 240 + 40 + 75 = 355                  | 355.0  |
    /// | B3c| 200             | 80         | 80          | 80   | 40      | 0               | 200 + 40 + 50 + 60 + 35 = 385        | 385.0  |
    /// | B3d| 300             | 160        | 40          | 0    | 0       | 0               | 300 + 80 + 25 = 405                  | 405.0  |
    /// | B3e| 240             | 100        | 0           | 0    | 0       | 48              | 240 + 50（48 は非計上）= 290         | 290.0  |
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
    /// ### C. isValid() の複合条件検証
    ///
    /// | No | fullContribution | effective | age | expected | 説明                            |
    /// |----|-----------------|-----------|-----|----------|-------------------------------|
    /// | C1 | 0               | 0.0       | 65  | true     | 最小有効（全ゼロ、標準受給）      |
    /// | C2 | 480             | 480.0     | 65  | true     | 最大有効（フル納付、標準受給）    |
    /// | C3 | 240             | 240.0     | 60  | true     | 年齢下限OK（60歳）               |
    /// | C4 | 240             | 240.0     | 75  | true     | 年齢上限OK（75歳）               |
    /// | C5 | -1              | -1.0      | 65  | false    | 負の納付月数                     |
    /// | C6 | 481             | 481.0     | 65  | false    | 有効月数超過（>480月）           |
    /// | C7 | 240             | 240.0     | 59  | false    | 年齢下限未満（59歳）             |
    /// | C8 | 240             | 240.0     | 76  | false    | 年齢上限超過（76歳）             |
    /// | C9 | 250             | 481.0     | 65  | false    | 複合超過（有効月数>480）         |
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
    /// ### D. 受給開始年齢別の調整率計算
    ///
    /// | No | desiredAge | monthsDiff | 区分       | 計算式                  | 期待値 |
    /// |----|-----------|-----------|----------|------------------------|--------|
    /// | D1 | 60        | -60       | 繰上げ5年  | 1.0 - (0.004 × 60)     | 0.76   |
    /// | D2 | 62        | -36       | 繰上げ3年  | 1.0 - (0.004 × 36)     | 0.856  |
    /// | D3 | 64        | -12       | 繰上げ1年  | 1.0 - (0.004 × 12)     | 0.952  |
    /// | D4 | 65        | 0         | 標準受給   | 1.0（減額なし）        | 1.0    |
    /// | D5 | 66        | 12        | 繰下げ1年  | 1.0 + (0.007 × 12)     | 1.084  |
    /// | D6 | 70        | 60        | 繰下げ5年  | 1.0 + (0.007 × 60)     | 1.42   |
    /// | D7 | 75        | 120       | 繰下げ10年 | 1.0 + (0.007 × 120)    | 1.84   |
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
    /// ### E. 年金定数と計算の一貫性
    ///
    /// | No | 定数名                              | 期待値      | 説明                  |
    /// |----|-------------------------------------|-----------|----------------------|
    /// | E1 | basicPensionMonthlyAmount           | 69,308.0  | 2025年度基本月額      |
    /// | E2 | getCurrentBasicPensionAmount()      | 69,308.0  | 月額スタティック取得  |
    /// | E3 | getCurrentBasicPensionAnnualAmount()| 831,696.0 | 月額 × 12             |
    /// | E4 | 年額 = 月額 × 12の関係              | 一致       | 計算の整合性検証      |
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
    /// ### F. シシテム定数の定義確認
    ///
    /// | No | 定数                    | 期待値 | 説明                         |
    /// |----|------------------------|--------|--------------------------|
    /// | F1 | pensionStartAge        | 65     | 標準受給開始年齢              |
    /// | F2 | fullContributionMonths | 480    | 完全納付期間（40年 = 12×40）|
    test('pensionStartAge: 65歳', () {
      expect(NationalPensionInput.pensionStartAge, 65);
    });

    test('fullContributionMonths: 480ヶ月', () {
      expect(NationalPensionInput.fullContributionMonths, 480);
    });
  });

  group('NationalPensionInput - 実践的シナリオ', () {
    /// ### G. リアル・ユースケース（real-world scenarios）
    ///
    /// | No | シナリオ名              | 条件                                    | 期待値                  |
    /// |----|----------------------|----------------------------------------|------------------------|
    /// | G1 | 失業&免除経験          | fc=380, fullExempt=100                | effective=430, valid✓  |
    /// | G2 | 困窮期間（多様な免除）   | fc=300, 全exemption混合                | effective=412.5, valid✓|
    /// | G3 | 60歳早期受給           | fc=240, 複数免除, age=60              | adjust=0.76            |
    /// | G4 | 75歳繰下げ受給         | fc=240, 複数免除, age=75              | adjust=1.84            |
    /// | G5 | 完全フル納付           | fc=480, age=65                        | effective=480, adjust=1.0|
    /// | G6 | 学生期間含む           | fc=432, studentDeferment=48           | effective=432, valid✓  |
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
    /// ### H. exemption flag の動作確認
    ///
    /// | No | exemptionTotal | hasPaymentSuspension | 説明                    |
    /// |----|-----------------|---------------------|----------------------|
    /// | H1 | > 0（あり）    | true                | 免除期間がある場合の表示|
    /// | H2 | 0（なし）      | false               | 免除なし（フル納付）    |
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
    /// ### I. 調整率の境界値検証
    ///
    /// | No | テスト対象               | 条件                        | 期待値                   |
    /// |----|------------------------|-----------------------------|------------------------|
    /// | I1 | 全年齢（60-75）の規則性  | 全てのageで調整率を計算      | 0.76 ≤ rate ≤ 1.84    |
    /// | I2 | 繰上げ受給の均一性       | age=60の場合                | rate < 1.0              |
    /// | I3 | 繰下げ受給の均一性       | age=75の場合                | rate > 1.0              |
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
    /// ### J. 学生納付特例（納付猶予）の特殊処理
    ///
    /// | No | fullContribution | studentDeferment | 計算式                              | 期待値  |
    /// |----|-----------------|-----------------|-----------------------------------|--------|
    /// | J1 | 0               | 48              | 48 は effectiveContribution に非計上 | 0.0    |
    /// | J2 | 240             | 48              | 240（48 は除外される）             | 240.0  |
    /// | Note| studentDeferment は追納待機中のため、納付月数に含まれない特殊フィールド |
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
    /// ### K. オプショナルフィールドのデフォルト値の確認
    ///
    /// | No | シナリオ           | 指定フィールド   | 期待値（省略フィールド）           |
    /// |----|------------------|-----------------|----------------------------------|
    /// | K1 | デフォルト全て使用 | なし            | 全exemption = 0, studentDef = 0 |
    /// | K2 | 一部フィールド指定 | fullExempt=100  | 他 = 0（自動デフォルト）         |
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
    /// ### L. 全年齢（60-75）の調整率ルーチン検証
    ///
    /// | No | age | 区分       | monthsDiff | 計算式                    | 期待値 |
    /// |----|-----|----------|-----------|-------------------------|--------|
    /// | L1 | 60  | 繰上げ5年  | -60       | 1.0 - (0.004 × 60)      | 0.76   |
    /// | L2 | 61  | 繰上げ4年  | -48       | 1.0 - (0.004 × 48)      | 0.808  |
    /// | L3 | 62  | 繰上げ3年  | -36       | 1.0 - (0.004 × 36)      | 0.856  |
    /// | L4 | 64  | 繰上げ1年  | -12       | 1.0 - (0.004 × 12)      | 0.952  |
    /// | L5 | 65  | 標準       | 0         | 1.0                     | 1.0    |
    /// | L6 | 66  | 繰下げ1年  | 12        | 1.0 + (0.007 × 12)      | 1.084  |
    /// | L7 | 68  | 繰下げ3年  | 36        | 1.0 + (0.007 × 36)      | 1.252  |
    /// | L8 | 70  | 繰下げ5年  | 60        | 1.0 + (0.007 × 60)      | 1.42   |
    /// | L9 | 75  | 繰下げ10年 | 120       | 1.0 + (0.007 × 120)     | 1.84   |
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
    /// ### M. isValid()の複合条件の全パターン検証
    ///
    /// | No | condition                    | fullContribution | fullExempt | age | expected | 説明                         |
    /// |----|------------------------------|-----------------|-----------|-----|----------|---------------------------|
    /// | M1 | ✓ 最小有効                  | 0               | 0         | 65  | true     | 全ゼロ、標準受給             |
    /// | M2 | ✓ 最大有効                  | 480             | 0         | 65  | true     | フル納付、標準受給           |
    /// | M3 | ✓ 年齢下限                  | 240             | 0         | 60  | true     | 年齢60（下限OK）             |
    /// | M4 | ✓ 年齢上限                  | 240             | 0         | 75  | true     | 年齢75（上限OK）             |
    /// | M5 | ✓ 免除混合                  | 300             | 360       | 65  | true     | 有効月数=480               |
    /// | M6 | ✗ 負の納付                  | -1              | 0         | 65  | false    | fullContribution < 0         |
    /// | M7 | ✗ 有効月数超過              | 481             | 0         | 65  | false    | effective > 480              |
    /// | M8 | ✗ 負の免除                  | 240             | -10       | 65  | false    | fullExempt < 0               |
    /// | M9 | ✗ 年齢下限未満              | 240             | 0         | 59  | false    | age < 60                     |
    /// | M10| ✗ 年齢上限超過              | 240             | 0         | 76  | false    | age > 75                     |
    /// | M11| ✗ 複合超過                  | 250             | 462       | 65  | false    | 250 + 231 = 481 > 480        |
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
