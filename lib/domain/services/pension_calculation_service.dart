import 'package:life_planning/domain/values/national_pension_input.dart';
import 'package:life_planning/domain/values/occupational_pension_input.dart';
import 'package:life_planning/domain/values/pension_result.dart';

/// 年金額を計算するドメインサービス
///
/// 基礎年金・厚生年金の複雑な計算ロジックを集約。
/// 値オブジェクト（NationalPensionInput, OccupationalPensionInput）を入力として、
/// 年金額を計算し PensionResult を返す。
class PensionCalculationService {
  /// 基礎年金計算ロジック
  ///
  /// 入力されたパラメータの妥当性を確認し、以下の計算を実行：
  ///
  /// 1. 有効納付月数の計算（免除期間の比率を反映）
  /// 2. 納付率の計算（有効納付月数 / 480）
  /// 3. 基本月額 × 納付率で基礎年金月額を算出
  /// 4. 受給開始年齢に基づく調整率（繰上げ/繰下げ）を反映
  /// 5. 月額から年額を計算
  ///
  /// 戻り値: PensionResult
  /// 例外: ArgumentError (入力値が不正な場合)
  static PensionResult calculateNationalPension(
    NationalPensionInput input,
  ) {
    // 入力値の妥当性チェック
    if (!input.isValid()) {
      throw ArgumentError('無効なNationalPensionInput値です');
    }

    // 有効納付月数を計算（免除期間の比率を反映）
    final effectiveMonths = input.effectiveContributionMonths;

    // 納付率を計算（上限480月）
    final contributionRate = effectiveMonths / NationalPensionInput.fullContributionMonths;

    // 基本月額から実際の基礎年金月額を計算
    final basicMonthlyAmount = NationalPensionInput.getCurrentBasicPensionAmount();
    final unadjustedMonthly = basicMonthlyAmount * contributionRate;

    // 受給開始年齢に基づく調整率を計算
    final adjustmentRate = input.getPensionAdjustmentRate();

    // 調整率を反映した月額
    final adjustedMonthly = unadjustedMonthly * adjustmentRate;

    // 年額を計算
    final annualAmount = adjustedMonthly * 12;

    return PensionResult(
      basicPensionMonthly: adjustedMonthly,
      basicPensionAnnual: annualAmount,
      occupationalPensionMonthly: 0.0,
      occupationalPensionAnnual: 0.0,
      totalPensionMonthly: adjustedMonthly,
      totalPensionAnnual: annualAmount,
      adjustmentRate: adjustmentRate,
      pensionStartAge: input.desiredPensionStartAge,
    );
  }

  /// 厚生年金計算ロジック
  ///
  /// 入力されたパラメータの妥当性を確認し、以下の計算を実行：
  ///
  /// 1. 報酬比例部分（2003年4月以降）を計算
  /// 2. 報酬比例部分（2003年3月以前）を計算（存在する場合）
  /// 3. 加給年金（配偶者・子）を計算
  /// 4. 基礎年金部分を含める（厚生年金加入者は基礎年金も受給）
  /// 5. 受給開始年齢に基づく調整率（繰上げ/繰下げ）を反映
  /// 6. 月額から年額を計算
  ///
  /// 戻り値: PensionResult
  /// 例外: ArgumentError (入力値が不正な場合)
  static PensionResult calculateOccupationalPension(
    OccupationalPensionInput input,
  ) {
    // 入力値の妥当性チェック
    if (!input.isValid()) {
      throw ArgumentError('無効なOccupationalPensionInput値です');
    }

    // 1. 報酬比例部分（2003年4月以降）を計算
    final remunerationBased2003 = 
        (input.averageMonthlyReward * input.enrollmentMonths +
         input.averageBonusReward * (input.enrollmentMonths / 12)) *
        OccupationalPensionInput.pensionRateMonthly;

    // 2. 報酬比例部分（2003年3月以前）を計算
    final remunerationBasedBefore2003 = 
        input.averageMonthlyRewardBefore2003 *
        input.enrollmentMonthsBefore2003 *
        OccupationalPensionInput.pensionRateBefore2003;

    // 合計報酬比例部分（年額）
    final totalRemunerationBased = remunerationBased2003 + remunerationBasedBefore2003;

    // 3. 加給年金を計算
    final spousalSupplement = input.hasSpouse 
        ? OccupationalPensionInput.spousalSupplementMonthly 
        : 0.0;

    final childSupplement = _calculateChildSupplement(input.numberOfChildren);

    final totalSupplementMonthly = spousalSupplement + childSupplement;
    final totalSupplementAnnual = totalSupplementMonthly * 12;

    // 4. 基礎年金部分を含める（厚生年金加入者も基礎年金を受給対象）
    final basicPensionMonthly = NationalPensionInput.getCurrentBasicPensionAmount();
    final basicPensionAnnual = basicPensionMonthly * 12;

    // 5. 受給開始年齢に基づく調整率を計算
    final adjustmentRate = input.getPensionAdjustmentRate();

    // 報酬比例部分に調整率を適用（年額）
    final adjustedRemunerationBased = totalRemunerationBased * adjustmentRate;

    // 基礎年金に調整率を適用（年額）
    final adjustedBasicAnnual = basicPensionAnnual * adjustmentRate;

    // 加給年金に調整率を適用（年額）
    final adjustedSupplementAnnual = totalSupplementAnnual * adjustmentRate;

    // 6. 月額を計算
    final occupationalMonthlyWithoutBasic = (adjustedRemunerationBased + adjustedSupplementAnnual) / 12;
    final basicMonthlyAdjusted = adjustedBasicAnnual / 12;
    
    final totalMonthly = basicMonthlyAdjusted + occupationalMonthlyWithoutBasic;
    final totalAnnual = totalMonthly * 12;

    return PensionResult(
      basicPensionMonthly: basicMonthlyAdjusted,
      basicPensionAnnual: adjustedBasicAnnual,
      occupationalPensionMonthly: occupationalMonthlyWithoutBasic,
      occupationalPensionAnnual: adjustedRemunerationBased + adjustedSupplementAnnual,
      totalPensionMonthly: totalMonthly,
      totalPensionAnnual: totalAnnual,
      adjustmentRate: adjustmentRate,
      pensionStartAge: input.desiredPensionStartAge,
    );
  }

  /// 複合年金計算（基礎年金 + 厚生年金）
  ///
  /// 両方の年金を受給する場合の統合結果を返す。
  /// (実質的には厚生年金計算と同じだが、概念的に区別するために提供)
  static PensionResult calculateCombinedPension(
    NationalPensionInput nationalPensionInput,
    OccupationalPensionInput occupationalPensionInput,
  ) {
    if (!nationalPensionInput.isValid()) {
      throw ArgumentError('無効なNationalPensionInput値です');
    }
    if (!occupationalPensionInput.isValid()) {
      throw ArgumentError('無効なOccupationalPensionInput値です');
    }

    // 厚生年金計算は既に基礎年金を含んでいるため、厚生年金側の計算を使用
    // （厚生年金加入者は自動的に基礎年金も受給対象）
    return calculateOccupationalPension(occupationalPensionInput);
  }

  /// 子供手当の計算ロジック
  ///
  /// - 第1・第2子: 各 ¥76,700/年
  /// - 第3子以降: 各 ¥25,600/年
  ///
  /// 例：3人の子がいる場合
  /// = ¥76,700 × 2 + ¥25,600 × 1 = ¥179,000/年
  /// = ¥14,916.67/月
  static double _calculateChildSupplement(int numberOfChildren) {
    if (numberOfChildren <= 0) {
      return 0.0;
    }

    double supplement = 0.0;

    // 第1・第2子の補助
    final first2Children = numberOfChildren >= 2 ? 2 : numberOfChildren;
    supplement += first2Children * OccupationalPensionInput.childSupplementFirst2ndMonthly;

    // 第3子以降の補助
    if (numberOfChildren > 2) {
      final third = numberOfChildren - 2;
      supplement += third * OccupationalPensionInput.childSupplementThirdMonthly;
    }

    return supplement;
  }
}
