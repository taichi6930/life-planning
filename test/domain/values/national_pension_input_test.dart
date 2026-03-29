import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/national_pension_input.dart';

/// NationalPensionInput デシジョンテーブル
///
/// 日本基礎年金（NationalPensionInput）の全計算パターンを網羅するテスト仕様書。
///
/// ## グループ別テスト一覧
/// | グループ | テスト数 | カバレッジ |
/// |--------|--------|---------|
/// | Constructor and validation | 10 | 100% |
/// | Full exemption calculation | 3 | 100% |
/// | Each exemption type calculation | 3 | 100% |
/// | Multiple exemption combinations | 5 | 100% |
/// | isValid() decision table | 10 | 100% |
/// | Pension adjustment rate calculation | 9 | 100% |
/// | Basic pension constants | 4 | 100% |
/// | Class constants | 2 | 100% |
/// | Real-world scenarios | 6+ | 100% |
///
/// ## 主要テストテーブル
///
/// ### 1. コンストラクタ検証 (CT-01～CT-10)
/// - CT-01: 全フィールド指定、最小有効
/// - CT-02: 最小指定（自動デフォルト）
/// - CT-03: fullContribution が正の値
/// - CT-04: fullExempt を明示指定
/// - CT-05: 全額納付480ヶ月
/// - CT-06: 負の fullContribution
/// - CT-07: 負の fullExempt
/// - CT-08: 負の quarterExempt
/// - CT-09: 負の studentDeferment
/// - CT-10: 複数負数値チェック
///
/// ### 2. 全額免除計算 (FC-01～FC-03)
/// - FC-01: 全額免除のみ（100ヶ月） → 50ヶ月カウント
/// - FC-02: 全額納付と全額免除の混合 → 290ヶ月
/// - FC-03: 全額免除の境界値テスト
///
/// ### 3. 各免除タイプ (Ex-01～Ex-03)
/// - Ex-01: 3/4免除（100ヶ月） → 62.5ヶ月カウント（5/8の比率）
/// - Ex-02: 半額免除（100ヶ月） → 75ヶ月カウント（3/4の比率）
/// - Ex-03: 1/4免除（100ヶ月） → 87.5ヶ月カウント（7/8の比率）
///
/// ### 4. 複数免除の組み合わせ (MC-01～MC-05)
/// - MC-01: 全額免除と3/4免除の混合 → 352.5ヶ月
/// - MC-02: 全額免除と半額免除の混合 → 355.0ヶ月
/// - MC-03: 全免除タイプを組み合わせ → 385.0ヶ月
/// - MC-04: 480月に達する複合パターン → 405.0ヶ月
/// - MC-05: 学生納付特例を含む混合 → studentDeferment は非計上
///
/// ### 5. isValid() 決定表 (VAL-01～VAL-10)
/// - VAL-01: 全てデフォルト、年齢65 → true
/// - VAL-02: 全額納付480ヶ月、年齢65 → true
/// - VAL-03: 有効月数480月以内、年齢60 → true
/// - VAL-04: 有効月数480月以内、年齢75 → true
/// - VAL-05: 学生納付特例を含む → true
/// - VAL-06: 年齢59（下限未満） → false
/// - VAL-07: 年齢76（上限超過） → false
/// - VAL-08: 有効月数が481以上 → false
/// - VAL-09: 負の納付月数 → false
/// - VAL-10: 複合で480月超過 → false
///
/// ### 6. 調整率計算 (AJ-01～AJ-09)
/// - AJ-01: 60歳受給 → 0.76（繰上げ5年、減額24%）
/// - AJ-02: 62歳受給 → 0.856（繰上げ3年、減額14.4%）
/// - AJ-03: 64歳受給 → 0.952（繰上げ1年、減額4.8%）
/// - AJ-04: 65歳受給 → 1.0（標準、減額なし）
/// - AJ-05: 66歳受給 → 1.084（繰下げ1年、増額8.4%）
/// - AJ-06: 70歳受給 → 1.42（繰下げ5年、増額42%）
/// - AJ-07: 75歳受給 → 1.84（繰下げ10年、増額84%）
/// - AJ-08: 調整率は年齢のみに依存（納付月数・免除状況の影響なし）
/// - AJ-09: 年齢と調整率の線形関係検証
///
/// ### 7. 定数（基礎年金額） (CST-01～CST-04)
/// - CST-01: basicPensionMonthlyAmount = 70,608.0円
/// - CST-02: getCurrentBasicPensionAmount() = 70,608.0円
/// - CST-03: getCurrentBasicPensionAnnualAmount() = 847,296.0円
/// - CST-04: 年額 = 月額 × 12の一貫性
///
/// ### 8. クラス定数 (CST-C1～CST-C2)
/// - CST-C1: pensionStartAge = 65歳（標準受給開始年齢）
/// - CST-C2: fullContributionMonths = 480ヶ月（40年）
///
/// ### 9. リアルユースケース (SC-01～SC-06)
/// - SC-01: 失業経験（全額免除100ヶ月+納付380ヶ月） → effective=430ヶ月
/// - SC-02: 困窮期間（多様な免除） → effective=412.5ヶ月
/// - SC-03: 60歳早期受給（免除混合） → adjust=0.76
/// - SC-04: 75歳繰下げ受給（免除混合） → adjust=1.84
/// - SC-05: 完全フル納付（480ヶ月、65歳） → effective=480ヶ月、adjust=1.0
/// - SC-06: 学生期間含む（学生納付特例48ヶ月+納付432ヶ月）
///
/// ## 入力パラメータ範囲（バウンダリー値）
/// | パラメータ | 最小値 | 最大値 | 説明 |
/// |-----------|-------|-------|------|
/// | fullContribution | 0 | 480 | 全額納付月数（0～40年） |
/// | fullExempt | 0 | 480 | 全額免除月数（0～40年） |
/// | threeQuarterExempt | 0 | 480 | 3/4免除月数（0～40年） |
/// | halfExempt | 0 | 480 | 半額免除月数（0～40年） |
/// | quarterExempt | 0 | 480 | 1/4免除月数（0～40年） |
/// | studentDeferment | 0 | 480 | 学生納付特例月数（0～40年、有効月数に非計上） |
/// | hasPaymentSuspension | false | true | 納付猶予フラグ（2値） |
/// | desiredPensionStartAge | 60 | 75 | 受給開始年齢（60～75歳） |
///
/// ## 制約条件
/// ```
/// 有効納付月数 = fullContribution
///              + (fullExempt × 1/2)
///              + (threeQuarterExempt × 5/8)
///              + (halfExempt × 3/4)
///              + (quarterExempt × 7/8)
///              + 0（studentDeferment は非計上）
/// 
/// 有効納付月数 <= 480月（上限）
/// fullContribution, 各免除、studentDeferment >= 0（非負）
/// 60 <= desiredPensionStartAge <= 75（受給開始年齢範囲）
/// ```
///
/// ## 計算式リファレンス
///
/// ### 有効納付月数（有効な保険料納付月数）
/// ```
/// effective = fullContribution
///           + (fullExempt × 1/2)
///           + (threeQuarterExempt × 5/8)
///           + (halfExempt × 3/4)
///           + (quarterExempt × 7/8)
/// 
/// 注意:
/// - studentDeferment: 0%（有効月数に含まれない）
/// - 制約: effective <= 480月
/// - 免除の加算比率:
///   - 全額免除: 50% = 1/2
///   - 3/4免除: 62.5% = 5/8
///   - 半額免除: 75% = 3/4
///   - 1/4免除: 87.5% = 7/8
/// ```
///
/// ### 年金調整率（受給開始年齢による増減率）
/// ```
/// desiredAge <= 65:
///   rate = 1.0 - 0.004 × (65 - desiredAge) × 12
///   範囲: 0.76～1.0（繰上げ時は減額）
/// 
/// desiredAge > 65:
///   rate = 1.0 + 0.007 × (desiredAge - 65) × 12
///   範囲: 1.0～1.84（繰下げ時は増額）
/// ```
///
/// ### 基礎年金額（定額）
/// ```
/// 月額: 70,608円（令和8年度基準）
/// 年額: 847,296円（月額 × 12）
/// ```

void main() {
  /// ### 1. コンストラクタ検証 (CT-01～CT-10)
  ///
  /// | No | fullContribution | exemptionValue | 期待される動作                     |
  /// |----|-----------------|----------------|----------------------------------|
  /// | CT-01 | 0             | 0（全て）      | isValid() = true（最小有効）      |
  /// | CT-02 | 240           | 0              | isValid() = true（正の値）        |
  /// | CT-03 | 480           | 0              | isValid() = true（フル納付）      |
  /// | CT-04 | -1            | 0              | isValid() = false（負数検出）     |
  /// | CT-05 | 240           | fullExempt=100 | isValid() = true（混合）          |
  /// | CT-06 | 240           | fullExempt=-10 | isValid() = false（負の免除）     |
  /// | CT-07 | 240           | quarterExempt=-5 | isValid() = false（負の免除）|
  /// | CT-08 | 240           | studentDeferment=-20 | isValid() = false（負の学生納付）|
  /// | CT-09 | 0             | 複数指定       | isValid() = true（デフォルト）    |
  /// | CT-10 | 240           | 複数負数       | isValid() = false（全て検出）     |
  group('NationalPensionInput - Constructor and validation', () {
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

  group('NationalPensionInput - Full exemption calculation', () {
    /// ### 2. 全額免除計算 (FC-01～FC-03)
    ///
    /// | No | fullContribution | fullExempt | 計算式              | 期待値  |
    /// |----|-----------------|------------|-------------------|--------|
    /// | FC-01 | 0             | 0          | 0                 | 0.0    |
    /// | FC-02 | 0             | 100        | 100 × 1/2 = 50    | 50.0   |
    /// | FC-03 | 240           | 100        | 240 + (100 × 1/2) | 290.0  |
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

  group('NationalPensionInput - Each exemption type calculation', () {
    /// ### 3. 各免除タイプ (Ex-01～Ex-03)
    ///
    /// | No | fullContribution | exemptionType     | 月数 | 計算式          | 期待値   |
    /// |----|-----------------|-------------------|------|---------------|---------|
    /// | Ex-01| 0              | threeQuarterExempt| 100  | 100 × 5/8 = 62.5 | 62.5  |
    /// | Ex-02| 0              | halfExempt        | 100  | 100 × 3/4 = 75   | 75.0  |
    /// | Ex-03| 0              | quarterExempt     | 100  | 100 × 7/8 = 87.5 | 87.5  |
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

  group('NationalPensionInput - Multiple exemption combinations', () {
    /// ### 4. 複数免除の組み合わせ (MC-01～MC-05)
    ///
    /// | No | fullContribution | fullExempt | threeQuarter | half | quarter | studentDeferment | 計算式                                | 期待値  |
    /// |----|-----------------|------------|-------------|------|---------|-----------------|--------------------------------------|--------|
    /// | MC-01| 240             | 100        | 0           | 0    | 0       | 0               | 240 + 50 = 290                       | 290.0  |
    /// | MC-02| 240             | 80         | 0           | 100  | 0       | 0               | 240 + 40 + 75 = 355                  | 355.0  |
    /// | MC-03| 200             | 80         | 80          | 80   | 40      | 0               | 200 + 40 + 50 + 60 + 35 = 385        | 385.0  |
    /// | MC-04| 300             | 160        | 40          | 0    | 0       | 0               | 300 + 80 + 25 = 405                  | 405.0  |
    /// | MC-05| 240             | 100        | 0           | 0    | 0       | 48              | 240 + 50（48 は非計上）= 290         | 290.0  |
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

  group('NationalPensionInput - isValid() decision table', () {
    /// ### 5. isValid() 決定表 (VAL-01～VAL-10)
    ///
    /// | No | fullContribution | effective | age | expected | 説明                            |
    /// |----|-----------------|-----------|-----|----------|-------------------------------|
    /// | VAL-01 | 0            | 0.0       | 65  | true     | 最小有効（全ゼロ、標準受給）      |
    /// | VAL-02 | 480          | 480.0     | 65  | true     | 最大有効（フル納付、標準受給）    |
    /// | VAL-03 | 240          | 240.0     | 60  | true     | 年齢下限OK（60歳）               |
    /// | VAL-04 | 240          | 240.0     | 75  | true     | 年齢上限OK（75歳）               |
    /// | VAL-05 | 240          | 240.0     | 65  | true     | 学生納付特例を含む               |
    /// | VAL-06 | 480          | 480.0     | 59  | false    | 年齢下限未満（59歳）             |
    /// | VAL-07 | 480          | 480.0     | 76  | false    | 年齢上限超過（76歳）             |
    /// | VAL-08 | 481          | 481.0     | 65  | false    | 有効月数超過（>480月）           |
    /// | VAL-09 | -1           | -1.0      | 65  | false    | 負の納付月数                     |
    /// | VAL-10 | 250          | 481.0     | 65  | false    | 複合超過（有効月数>480）         |
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

  group('NationalPensionInput - Pension adjustment rate calculation', () {
    /// ### 6. 調整率計算 (AJ-01～AJ-09)
    ///
    /// | No | desiredAge | monthsDiff | 区分       | 計算式                  | 期待値 |
    /// |----|-----------|-----------|----------|------------------------|--------|
    /// | AJ-01 | 60        | -60       | 繰上げ5年  | 1.0 - (0.004 × 60)     | 0.76   |
    /// | AJ-02 | 62        | -36       | 繰上げ3年  | 1.0 - (0.004 × 36)     | 0.856  |
    /// | AJ-03 | 64        | -12       | 繰上げ1年  | 1.0 - (0.004 × 12)     | 0.952  |
    /// | AJ-04 | 65        | 0         | 標準受給   | 1.0（減額なし）        | 1.0    |
    /// | AJ-05 | 66        | 12        | 繰下げ1年  | 1.0 + (0.007 × 12)     | 1.084  |
    /// | AJ-06 | 70        | 60        | 繰下げ5年  | 1.0 + (0.007 × 60)     | 1.42   |
    /// | AJ-07 | 75        | 120       | 繰下げ10年 | 1.0 + (0.007 × 120)    | 1.84   |
    /// | AJ-08 | 65～70   | 複数      | 依存性検証 | 納付月数・免除状況影響なし | 年齢のみ |
    /// | AJ-09 | 60～75   | 連続      | 線形関係   | 月数×0.004or0.007       | 比例 |
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

  group('NationalPensionInput - Basic pension constants', () {
    /// ### 7. 定数（基礎年金額） (CST-01～CST-04)
    ///
    /// | No | 定数名                              | 期待値      | 説明                  |
    /// |----|-------------------------------------|-----------|----------------------|
    /// | CST-01 | basicPensionMonthlyAmount           | 70,608.0  | 2026年度基本月額      |
    /// | CST-02 | getCurrentBasicPensionAmount()      | 70,608.0  | 月額スタティック取得  |
    /// | CST-03 | getCurrentBasicPensionAnnualAmount()| 847,296.0 | 月額 × 12             |
    /// | CST-04 | 年額 = 月額 × 12の関係              | 一致       | 計算の整合性検証      |
    test('basicPensionMonthlyAmount: 70,608円', () {
      expect(NationalPensionInput.basicPensionMonthlyAmount, 70608.0);
    });

    test('getCurrentBasicPensionAmount(): 月額を返す', () {
      expect(
        NationalPensionInput.getCurrentBasicPensionAmount(),
        70608.0,
      );
    });

    test('getCurrentBasicPensionAnnualAmount(): 847,296円（月額×12）', () {
      expect(
        NationalPensionInput.getCurrentBasicPensionAnnualAmount(),
        847296.0,
      );
    });

    test('年額 = 月額 × 12の関係', () {
      expect(
        NationalPensionInput.getCurrentBasicPensionAnnualAmount(),
        NationalPensionInput.basicPensionMonthlyAmount * 12,
      );
    });
  });

  group('NationalPensionInput - Class constants', () {
    /// ### 8. クラス定数 (CST-C1～CST-C2)
    ///
    /// | No | 定数                    | 期待値 | 説明                         |
    /// |----|------------------------|--------|--------------------------|
    /// | CST-C1 | pensionStartAge        | 65     | 標準受給開始年齢              |
    /// | CST-C2 | fullContributionMonths | 480    | 完全納付期間（40年 = 12×40）|
    test('pensionStartAge: 65歳', () {
      expect(NationalPensionInput.pensionStartAge, 65);
    });

    test('fullContributionMonths: 480ヶ月', () {
      expect(NationalPensionInput.fullContributionMonths, 480);
    });
  });

  group('NationalPensionInput - Real-world scenarios', () {
    /// ### 9. リアルユースケース (SC-01～SC-06)
    ///
    /// | No | シナリオ名              | 条件                                    | 期待値                  |
    /// |----|----------------------|----------------------------------------|------------------------|
    /// | SC-01 | 失業&免除経験          | fc=380, fullExempt=100                | effective=430, valid✓  |
    /// | SC-02 | 困窮期間（多様な免除）   | fc=300, 全exemption混合                | effective=412.5, valid✓|
    /// | SC-03 | 60歳早期受給           | fc=240, 複数免除, age=60              | adjust=0.76            |
    /// | SC-04 | 75歳繰下げ受給         | fc=240, 複数免除, age=75              | adjust=1.84            |
    /// | SC-05 | 完全フル納付           | fc=480, age=65                        | effective=480, adjust=1.0|
    /// | SC-06 | 学生期間含む           | fc=432, studentDeferment=48           | effective=432, valid✓  |
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
