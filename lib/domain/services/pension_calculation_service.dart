import 'dart:math' as math;

import 'package:life_planning/domain/values/ideco_input.dart';
import 'package:life_planning/domain/values/investment_trust_input.dart';
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
      // coverage:ignore-line
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

  /// 厚生年金計算ロジック（報酬比例部分＋加給年金のみ）
  ///
  /// 基礎年金は別途 calculateNationalPension() で計算する。
  /// 両方を合算する場合は calculateCombinedPension() を使用する。
  ///
  /// 入力されたパラメータの妥当性を確認し、以下の計算を実行：
  ///
  /// 1. 報酬比例部分（2003年4月以降）を計算
  /// 2. 報酬比例部分（2003年3月以前）を計算（存在する場合）
  /// 3. 加給年金（配偶者・子）を計算
  /// 4. 受給開始年齢に基づく調整率（繰上げ/繰下げ）を反映
  /// 5. 月額から年額を計算
  ///
  /// 戻り値: PensionResult（基礎年金部分は0）
  /// 例外: ArgumentError (入力値が不正な場合)
  static PensionResult calculateOccupationalPension(
    OccupationalPensionInput input,
  ) {
    // 入力値の妥当性チェック
    if (!input.isValid()) {
      // coverage:ignore-line
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

    // 4. 受給開始年齢に基づく調整率を計算
    final adjustmentRate = input.getPensionAdjustmentRate();

    // 報酬比例部分に調整率を適用（年額）
    final adjustedRemunerationBased = totalRemunerationBased * adjustmentRate;

    // 加給年金に調整率を適用（年額）
    final adjustedSupplementAnnual = totalSupplementAnnual * adjustmentRate;

    // 5. 月額を計算（厚生年金部分のみ、基礎年金は含まない）
    final occupationalMonthly = (adjustedRemunerationBased + adjustedSupplementAnnual) / 12;
    final occupationalAnnual = adjustedRemunerationBased + adjustedSupplementAnnual;

    return PensionResult(
      basicPensionMonthly: 0.0,
      basicPensionAnnual: 0.0,
      occupationalPensionMonthly: occupationalMonthly,
      occupationalPensionAnnual: occupationalAnnual,
      totalPensionMonthly: occupationalMonthly,
      totalPensionAnnual: occupationalAnnual,
      adjustmentRate: adjustmentRate,
      pensionStartAge: input.desiredPensionStartAge,
    );
  }

  /// 複合年金計算（基礎年金 + 厚生年金）
  ///
  /// 基礎年金と厚生年金を別々に計算し、合算した結果を返す。
  /// 基礎年金は納付月数に基づき、厚生年金は報酬比例部分＋加給年金。
  static PensionResult calculateCombinedPension(
    NationalPensionInput nationalPensionInput,
    OccupationalPensionInput occupationalPensionInput,
  ) {
    // 基礎年金を個別に計算（納付月数を反映）
    final nationalResult = calculateNationalPension(nationalPensionInput);

    // 厚生年金を個別に計算（報酬比例部分＋加給年金のみ）
    final occupationalResult = calculateOccupationalPension(occupationalPensionInput);

    // 合算
    final totalMonthly = nationalResult.basicPensionMonthly + occupationalResult.occupationalPensionMonthly;
    final totalAnnual = nationalResult.basicPensionAnnual + occupationalResult.occupationalPensionAnnual;

    return PensionResult(
      basicPensionMonthly: nationalResult.basicPensionMonthly,
      basicPensionAnnual: nationalResult.basicPensionAnnual,
      occupationalPensionMonthly: occupationalResult.occupationalPensionMonthly,
      occupationalPensionAnnual: occupationalResult.occupationalPensionAnnual,
      totalPensionMonthly: totalMonthly,
      totalPensionAnnual: totalAnnual,
      adjustmentRate: nationalResult.adjustmentRate,
      pensionStartAge: nationalPensionInput.desiredPensionStartAge,
    );
  }

  /// iDeCo年金計算（単体）
  ///
  /// iDeCo の積立額を計算し、生活費の不足分を補填するモデルで
  /// 充足判定を行う。受給中も運用を継続するモデル。
  ///
  /// [monthlyLivingExpenses] 月額生活費（円）
  /// [targetAge] 想定寿命（歳）
  ///
  /// 不足分 = 生活費 - 公的年金（この単体メソッドでは公的年金0）
  /// iDeCo枯渇年齢 = 受給開始年齢 + _monthsUntilExhaustion(FV, 不足分, r) / 12
  static PensionResult calculateIdeco(
    IdecoInput input, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    if (!input.isValid()) {
      // coverage:ignore-line
      throw ArgumentError('無効なIdecoInput値です');
    }

    final fv = input.futureValue;
    final r = input.monthlyReturnRate;
    const publicPensionMonthly = 0.0;
    final shortfall = monthlyLivingExpenses > 0
        ? (monthlyLivingExpenses - publicPensionMonthly)
        : 0.0;
    final effectiveShortfall = shortfall > 0 ? shortfall : 0.0;

    double exhaustionAge = 0.0;
    bool isSufficient = true;
    double idecoMonthly = 0.0;

    if (effectiveShortfall > 0 && fv > 0) {
      idecoMonthly = effectiveShortfall;
      // 運用しながら引き出す → 年金現価公式で枯渇月数を計算
      final months = _monthsUntilExhaustion(fv, effectiveShortfall, r);
      exhaustionAge = months == double.infinity
          ? double.infinity
          : input.pensionStartAge + months / 12.0;
      isSufficient = exhaustionAge >= targetAge;
    }

    return PensionResult(
      basicPensionMonthly: 0.0,
      basicPensionAnnual: 0.0,
      occupationalPensionMonthly: 0.0,
      occupationalPensionAnnual: 0.0,
      idecoMonthly: idecoMonthly,
      idecoAnnual: idecoMonthly * 12,
      monthlyLivingExpenses: monthlyLivingExpenses,
      monthlyShortfall: effectiveShortfall,
      idecoFutureValue: fv,
      idecoExhaustionAge: exhaustionAge,
      targetAge: targetAge,
      isIdecoSufficient: isSufficient,
      totalPensionMonthly: idecoMonthly,
      totalPensionAnnual: idecoMonthly * 12,
      adjustmentRate: 1.0,
      pensionStartAge: input.pensionStartAge,
    );
  }

  /// 複合年金計算（基礎年金 + 厚生年金 + iDeCo）2段階モデル
  ///
  /// 60歳〜公的年金受給開始年齢まではiDeCoのみで生活費を賄い、
  /// 公的年金受給開始後は「生活費 - 公的年金」の不足分をiDeCoで補填する。
  /// 受給中も運用を継続するため年金現価公式を使用。
  ///
  /// 【Phase 1】iDeCo受給開始（60歳）〜 公的年金受給開始年齢
  ///   - 月額iDeCo引出 = 月額生活費（全額）、残高は運用継続
  ///   - Phase 1終了時残高 = _balanceAfterDrawdown(FV, 月額生活費, r, n1)
  ///
  /// 【Phase 2】公的年金受給開始〜 想定寿命
  ///   - 月額不足分 = 月額生活費 - (基礎年金 + 厚生年金)
  ///   - iDeCoで不足分を補填（運用継続）
  ///
  /// iDeCo枯渇年齢:
  ///   - Phase 1中に枯渇: idecoStartAge + _monthsUntilExhaustion(FV, 生活費, r) / 12
  ///   - Phase 2で枯渇:  publicStartAge + _monthsUntilExhaustion(Phase1後残高, 不足分, r) / 12
  static PensionResult calculateCombinedPensionWithIdeco(
    NationalPensionInput nationalPensionInput,
    OccupationalPensionInput occupationalPensionInput,
    IdecoInput idecoInput, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    final base = calculateCombinedPension(nationalPensionInput, occupationalPensionInput);
    final fv = idecoInput.futureValue;
    final r = idecoInput.monthlyReturnRate;
    final publicPensionMonthly = base.basicPensionMonthly + base.occupationalPensionMonthly;

    // 2段階モデル: iDeCo受給開始（60歳）〜公的年金受給開始の期間を計算
    final idecoStartAge = idecoInput.pensionStartAge;
    final publicStartAge = nationalPensionInput.desiredPensionStartAge;
    final prePensionMonths = publicStartAge > idecoStartAge
        ? (publicStartAge - idecoStartAge) * 12
        : 0;

    // Phase 2の不足分（公的年金受給開始以降）
    final phase2ShortfallRaw = monthlyLivingExpenses > 0
        ? monthlyLivingExpenses - publicPensionMonthly
        : 0.0;
    final phase2Shortfall = phase2ShortfallRaw > 0 ? phase2ShortfallRaw : 0.0;

    double exhaustionAge = 0.0;
    bool isSufficient = true;
    double idecoMonthly = 0.0;

    if (monthlyLivingExpenses > 0 && fv > 0) {
      // Phase 1: iDeCo受給開始〜公的年金受給開始（運用しながら生活費を全額引き出す）
      final remainingAfterPhase1 =
          _balanceAfterDrawdown(fv, monthlyLivingExpenses, r, prePensionMonths);

      if (remainingAfterPhase1 <= 0) {
        // Phase 1中にiDeCoが枯渇
        final months = _monthsUntilExhaustion(fv, monthlyLivingExpenses, r);
        exhaustionAge = idecoStartAge + months / 12.0;
        isSufficient = exhaustionAge >= targetAge;
        idecoMonthly = 0.0; // Phase 2ではiDeCo枯渇済み
      } else if (phase2Shortfall > 0) {
        // Phase 2: 公的年金受給開始以降、運用しながら不足分を補填
        idecoMonthly = phase2Shortfall;
        final months = _monthsUntilExhaustion(remainingAfterPhase1, phase2Shortfall, r);
        exhaustionAge = months == double.infinity
            ? double.infinity
            : publicStartAge.toDouble() + months / 12.0;
        isSufficient = exhaustionAge >= targetAge;
      } else {
        // 公的年金だけで生活費を賄える（iDeCoは余剰）
        isSufficient = true;
        idecoMonthly = 0.0;
      }
    }

    return PensionResult(
      basicPensionMonthly: base.basicPensionMonthly,
      basicPensionAnnual: base.basicPensionAnnual,
      occupationalPensionMonthly: base.occupationalPensionMonthly,
      occupationalPensionAnnual: base.occupationalPensionAnnual,
      idecoMonthly: idecoMonthly,
      idecoAnnual: idecoMonthly * 12,
      monthlyLivingExpenses: monthlyLivingExpenses,
      monthlyShortfall: phase2Shortfall,
      idecoFutureValue: fv,
      idecoExhaustionAge: exhaustionAge,
      targetAge: targetAge,
      isIdecoSufficient: isSufficient,
      totalPensionMonthly: base.basicPensionMonthly + base.occupationalPensionMonthly + idecoMonthly,
      totalPensionAnnual: base.basicPensionAnnual + base.occupationalPensionAnnual + idecoMonthly * 12,
      adjustmentRate: base.adjustmentRate,
      pensionStartAge: base.pensionStartAge,
    );
  }

  /// 基礎年金 + iDeCo（厚生年金なし）2段階モデル
  ///
  /// 自営業者・第1号被保険者向けシミュレーション。
  /// 60歳〜公的年金受給開始年齢まではiDeCoのみで生活費を賄い、
  /// 公的年金受給開始後は不足分をiDeCoで補填する。受給中も運用継続。
  ///
  /// 詳細は calculateCombinedPensionWithIdeco のコメントを参照。
  static PensionResult calculateNationalPensionWithIdeco(
    NationalPensionInput nationalPensionInput,
    IdecoInput idecoInput, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    final base = calculateNationalPension(nationalPensionInput);
    final fv = idecoInput.futureValue;
    final r = idecoInput.monthlyReturnRate;
    final publicPensionMonthly = base.basicPensionMonthly;

    // 2段階モデル: iDeCo受給開始（60歳）〜公的年金受給開始の期間を計算
    final idecoStartAge = idecoInput.pensionStartAge;
    final publicStartAge = nationalPensionInput.desiredPensionStartAge;
    final prePensionMonths = publicStartAge > idecoStartAge
        ? (publicStartAge - idecoStartAge) * 12
        : 0;

    // Phase 2の不足分（公的年金受給開始以降）
    final phase2ShortfallRaw = monthlyLivingExpenses > 0
        ? monthlyLivingExpenses - publicPensionMonthly
        : 0.0;
    final phase2Shortfall = phase2ShortfallRaw > 0 ? phase2ShortfallRaw : 0.0;

    double exhaustionAge = 0.0;
    bool isSufficient = true;
    double idecoMonthly = 0.0;

    if (monthlyLivingExpenses > 0 && fv > 0) {
      // Phase 1: iDeCo受給開始〜公的年金受給開始（運用しながら生活費を全額引き出す）
      final remainingAfterPhase1 =
          _balanceAfterDrawdown(fv, monthlyLivingExpenses, r, prePensionMonths);

      if (remainingAfterPhase1 <= 0) {
        // Phase 1中にiDeCoが枯渇
        final months = _monthsUntilExhaustion(fv, monthlyLivingExpenses, r);
        exhaustionAge = idecoStartAge + months / 12.0;
        isSufficient = exhaustionAge >= targetAge;
        idecoMonthly = 0.0; // Phase 2ではiDeCo枯渇済み
      } else if (phase2Shortfall > 0) {
        // Phase 2: 公的年金受給開始以降、運用しながら不足分を補填
        idecoMonthly = phase2Shortfall;
        final months = _monthsUntilExhaustion(remainingAfterPhase1, phase2Shortfall, r);
        exhaustionAge = months == double.infinity
            ? double.infinity
            : publicStartAge.toDouble() + months / 12.0;
        isSufficient = exhaustionAge >= targetAge;
      } else {
        // 公的年金だけで生活費を賄える（iDeCoは余剰）
        isSufficient = true;
        idecoMonthly = 0.0;
      }
    }

    return PensionResult(
      basicPensionMonthly: base.basicPensionMonthly,
      basicPensionAnnual: base.basicPensionAnnual,
      occupationalPensionMonthly: 0.0,
      occupationalPensionAnnual: 0.0,
      idecoMonthly: idecoMonthly,
      idecoAnnual: idecoMonthly * 12,
      monthlyLivingExpenses: monthlyLivingExpenses,
      monthlyShortfall: phase2Shortfall,
      idecoFutureValue: fv,
      idecoExhaustionAge: exhaustionAge,
      targetAge: targetAge,
      isIdecoSufficient: isSufficient,
      totalPensionMonthly: base.basicPensionMonthly + idecoMonthly,
      totalPensionAnnual: base.basicPensionAnnual + idecoMonthly * 12,
      adjustmentRate: base.adjustmentRate,
      pensionStartAge: base.pensionStartAge,
    );
  }

  // ---------------------------------------------------------------------------
  // iDeCo 引き出し計算ヘルパー（運用しながら引き出すモデル）
  // ---------------------------------------------------------------------------

  /// 運用しながら毎月引き出すときの枯渇月数を計算（年金現価逆算式）
  ///
  /// n = -ln(1 - PV·r/W) / ln(1+r)  [r > 0, W > PV·r の場合]
  /// n = PV / W                       [r = 0 の場合]
  /// 戻り値 double.infinity           [W ≤ PV·r: 運用益が引出額を超えるため永久に持つ]
  ///
  /// [balance]           引き出し開始時の残高
  /// [monthlyWithdrawal] 月額引き出し額
  /// [monthlyRate]       月利（例: 年利3% → 0.0025）
  static double _monthsUntilExhaustion(
    double balance,
    double monthlyWithdrawal,
    double monthlyRate,
  ) {
    if (monthlyWithdrawal <= 0) return double.infinity;
    if (balance <= 0) return 0;
    if (monthlyRate <= 0) return balance / monthlyWithdrawal;
    // 毎月利回りが引き出し額以上 → 永久に枯渇しない
    if (balance * monthlyRate >= monthlyWithdrawal) return double.infinity;
    // 標準年金現価逆算: n = -ln(1 - PV·r/W) / ln(1+r)
    return -math.log(1 - balance * monthlyRate / monthlyWithdrawal) /
        math.log(1 + monthlyRate);
  }

  /// 運用しながら毎月引き出した後の残高を計算
  ///
  /// B = PV·(1+r)^n - W·((1+r)^n - 1)/r  [r > 0]
  /// B = PV - W·n                          [r = 0]
  ///
  /// [balance]           開始残高
  /// [monthlyWithdrawal] 月額引き出し額
  /// [monthlyRate]       月利
  /// [months]            引き出し月数
  static double _balanceAfterDrawdown(
    double balance,
    double monthlyWithdrawal,
    double monthlyRate,
    int months,
  ) {
    if (months <= 0) return balance;
    if (monthlyRate <= 0) {
      final remaining = balance - monthlyWithdrawal * months;
      return remaining > 0 ? remaining : 0;
    }
    final factor = math.pow(1 + monthlyRate, months).toDouble();
    final remaining =
        balance * factor - monthlyWithdrawal * (factor - 1) / monthlyRate;
    return remaining > 0 ? remaining : 0;
  }

  // ---------------------------------------------------------------------------
  // 投資信託 引き出し計算ヘルパーは iDeCo と共通の _monthsUntilExhaustion / _balanceAfterDrawdown を使用
  // ---------------------------------------------------------------------------

  /// 投資信託計算（単体）
  ///
  /// 投資信託の積立額を計算し、生活費の不足分を補填するモデルで
  /// 充足判定を行う。受給中も運用を継続するモデル。
  ///
  /// iDeCoとの違い: 引出開始年齢に制限なし（60歳未満でも引出可能）
  ///
  /// [monthlyLivingExpenses] 月額生活費（円）
  /// [targetAge] 想定寿命（歳）
  static PensionResult calculateInvestmentTrust(
    InvestmentTrustInput input, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    if (!input.isValid()) {
      // coverage:ignore-line
      throw ArgumentError('無効なInvestmentTrustInput値です');
    }

    final fv = input.futureValue;
    final r = input.monthlyReturnRate;
    const publicPensionMonthly = 0.0;
    final shortfall = monthlyLivingExpenses > 0
        ? (monthlyLivingExpenses - publicPensionMonthly)
        : 0.0;
    final effectiveShortfall = shortfall > 0 ? shortfall : 0.0;

    double exhaustionAge = 0.0;
    bool isSufficient = true;
    double itMonthly = 0.0;

    if (effectiveShortfall > 0 && fv > 0) {
      itMonthly = effectiveShortfall;
      final months = _monthsUntilExhaustion(fv, effectiveShortfall, r);
      exhaustionAge = months == double.infinity
          ? double.infinity
          : input.withdrawalStartAge + months / 12.0;
      isSufficient = exhaustionAge >= targetAge;
    }

    return PensionResult(
      basicPensionMonthly: 0.0,
      basicPensionAnnual: 0.0,
      occupationalPensionMonthly: 0.0,
      occupationalPensionAnnual: 0.0,
      monthlyLivingExpenses: monthlyLivingExpenses,
      monthlyShortfall: effectiveShortfall,
      investmentTrustMonthly: itMonthly,
      investmentTrustAnnual: itMonthly * 12,
      investmentTrustFutureValue: fv,
      investmentTrustExhaustionAge: exhaustionAge,
      isInvestmentTrustSufficient: isSufficient,
      targetAge: targetAge,
      totalPensionMonthly: itMonthly,
      totalPensionAnnual: itMonthly * 12,
      adjustmentRate: 1.0,
      pensionStartAge: input.withdrawalStartAge,
    );
  }

  /// 基礎年金 + 投資信託（厚生年金なし）2段階モデル
  ///
  /// 自営業者・第1号被保険者向けシミュレーション。
  /// 引出開始〜公的年金受給開始年齢まで投資信託で生活費を全額賄い、
  /// 公的年金受給開始後は不足分を投資信託で補填する。受給中も運用継続。
  ///
  /// 詳細は calculateCombinedPensionWithInvestmentTrust のコメントを参照。
  static PensionResult calculateNationalPensionWithInvestmentTrust(
    NationalPensionInput nationalPensionInput,
    InvestmentTrustInput investmentTrustInput, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    final base = calculateNationalPension(nationalPensionInput);
    return _applyInvestmentTrustToBase(
      base: base,
      investmentTrustInput: investmentTrustInput,
      monthlyLivingExpenses: monthlyLivingExpenses,
      targetAge: targetAge,
      occupationalPensionMonthly: 0.0,
      occupationalPensionAnnual: 0.0,
    );
  }

  /// 複合年金計算（基礎年金 + 厚生年金 + 投資信託）2段階モデル
  ///
  /// 引出開始〜公的年金受給開始年齢まで投資信託で生活費を全額賄い、
  /// 公的年金受給開始後は「生活費 - 公的年金」の不足分を投資信託で補填する。
  /// 受給中も運用を継続するため年金現価公式を使用。
  ///
  /// 【Phase 1】投資信託引出開始〜公的年金受給開始年齢
  ///   - 月額引出 = 月額生活費（全額）、残高は運用継続
  ///
  /// 【Phase 2】公的年金受給開始〜想定寿命
  ///   - 月額不足分 = 月額生活費 - （基礎年金 + 厚生年金）
  ///   - 投資信託で不足分を補填（運用継続）
  static PensionResult calculateCombinedPensionWithInvestmentTrust(
    NationalPensionInput nationalPensionInput,
    OccupationalPensionInput occupationalPensionInput,
    InvestmentTrustInput investmentTrustInput, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    final base = calculateCombinedPension(nationalPensionInput, occupationalPensionInput);
    return _applyInvestmentTrustToBase(
      base: base,
      investmentTrustInput: investmentTrustInput,
      monthlyLivingExpenses: monthlyLivingExpenses,
      targetAge: targetAge,
      occupationalPensionMonthly: base.occupationalPensionMonthly,
      occupationalPensionAnnual: base.occupationalPensionAnnual,
    );
  }

  /// 投資信託2段階モデルの共通ロジック
  ///
  /// iDeCoの2段階モデルと同様の計算ロジック。
  /// Phase 1: 引出開始〜公的年金受給開始（生活費全額を投資信託から引き出す）
  /// Phase 2: 公的年金受給開始以降（不足分を投資信託で補填）
  static PensionResult _applyInvestmentTrustToBase({
    required PensionResult base,
    required InvestmentTrustInput investmentTrustInput,
    required double monthlyLivingExpenses,
    required int targetAge,
    required double occupationalPensionMonthly,
    required double occupationalPensionAnnual,
  }) {
    final fv = investmentTrustInput.futureValue;
    final r = investmentTrustInput.monthlyReturnRate;
    final publicPensionMonthly = base.basicPensionMonthly + occupationalPensionMonthly;

    // 2段階モデル: 投資信託引出開始〜公的年金受給開始の期間を計算
    final itStartAge = investmentTrustInput.withdrawalStartAge;
    final publicStartAge = base.pensionStartAge;
    final prePensionMonths = publicStartAge > itStartAge
        ? (publicStartAge - itStartAge) * 12
        : 0;

    // Phase 2の不足分（公的年金受給開始以降）
    final phase2ShortfallRaw = monthlyLivingExpenses > 0
        ? monthlyLivingExpenses - publicPensionMonthly
        : 0.0;
    final phase2Shortfall = phase2ShortfallRaw > 0 ? phase2ShortfallRaw : 0.0;

    double exhaustionAge = 0.0;
    bool isSufficient = true;
    double itMonthly = 0.0;

    if (monthlyLivingExpenses > 0 && fv > 0) {
      // Phase 1: 引出開始〜公的年金受給開始（運用しながら生活費を全額引き出す）
      final remainingAfterPhase1 =
          _balanceAfterDrawdown(fv, monthlyLivingExpenses, r, prePensionMonths);

      if (remainingAfterPhase1 <= 0) {
        // Phase 1中に投資信託が枯渇
        final months = _monthsUntilExhaustion(fv, monthlyLivingExpenses, r);
        exhaustionAge = itStartAge + months / 12.0;
        isSufficient = exhaustionAge >= targetAge;
        itMonthly = 0.0;
      } else if (phase2Shortfall > 0) {
        // Phase 2: 公的年金受給開始以降、運用しながら不足分を補填
        itMonthly = phase2Shortfall;
        final months = _monthsUntilExhaustion(remainingAfterPhase1, phase2Shortfall, r);
        exhaustionAge = months == double.infinity
            ? double.infinity
            : publicStartAge.toDouble() + months / 12.0;
        isSufficient = exhaustionAge >= targetAge;
      } else {
        // 公的年金だけで生活費を賄える（投資信託は余剰）
        isSufficient = true;
        itMonthly = 0.0;
      }
    }

    return PensionResult(
      basicPensionMonthly: base.basicPensionMonthly,
      basicPensionAnnual: base.basicPensionAnnual,
      occupationalPensionMonthly: occupationalPensionMonthly,
      occupationalPensionAnnual: occupationalPensionAnnual,
      monthlyLivingExpenses: monthlyLivingExpenses,
      monthlyShortfall: phase2Shortfall,
      investmentTrustMonthly: itMonthly,
      investmentTrustAnnual: itMonthly * 12,
      investmentTrustFutureValue: fv,
      investmentTrustExhaustionAge: exhaustionAge,
      isInvestmentTrustSufficient: isSufficient,
      targetAge: targetAge,
      totalPensionMonthly: base.basicPensionMonthly + occupationalPensionMonthly + itMonthly,
      totalPensionAnnual: base.basicPensionAnnual + occupationalPensionAnnual + itMonthly * 12,
      adjustmentRate: base.adjustmentRate,
      pensionStartAge: base.pensionStartAge,
    );
  }

  /// 基礎年金 + iDeCo + 投資信託（厚生年金なし）複合モデル
  ///
  /// iDeCoと投資信託を併用するケース。
  /// 投資信託はiDeCoのバックアップとして機能する:
  ///   - 引出開始〜60歳: 投資信託が生活費をカバー
  ///   - 60歳〜公的年金受給開始: iDeCoがカバー、投資信託は運用のみ
  ///   - 公的年金受給開始〜iDeCo枯渇: iDeCoが不足分をカバー、投資信託は運用のみ
  ///   - iDeCo枯渇後: 投資信託が不足分をカバー
  static PensionResult calculateNationalPensionWithIdecoAndInvestmentTrust(
    NationalPensionInput nationalPensionInput,
    IdecoInput idecoInput,
    InvestmentTrustInput investmentTrustInput, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    final base = calculateNationalPension(nationalPensionInput);
    return _applyIdecoAndInvestmentTrustToBase(
      base: base,
      idecoInput: idecoInput,
      investmentTrustInput: investmentTrustInput,
      monthlyLivingExpenses: monthlyLivingExpenses,
      targetAge: targetAge,
      occupationalPensionMonthly: 0.0,
      occupationalPensionAnnual: 0.0,
    );
  }

  /// 複合年金計算（基礎年金 + 厚生年金 + iDeCo + 投資信託）複合モデル
  ///
  /// iDeCoと投資信託を併用するケース。
  /// 投資信託はiDeCoのバックアップとして機能する:
  ///   - 引出開始〜60歳: 投資信託が生活費をカバー
  ///   - 60歳〜公的年金受給開始: iDeCoがカバー、投資信託は運用のみ
  ///   - 公的年金受給開始〜iDeCo枯渇: iDeCoが不足分をカバー、投資信託は運用のみ
  ///   - iDeCo枯渇後: 投資信託が不足分をカバー
  static PensionResult calculateCombinedPensionWithIdecoAndInvestmentTrust(
    NationalPensionInput nationalPensionInput,
    OccupationalPensionInput occupationalPensionInput,
    IdecoInput idecoInput,
    InvestmentTrustInput investmentTrustInput, {
    double monthlyLivingExpenses = 0.0,
    int targetAge = 100,
  }) {
    final base = calculateCombinedPension(nationalPensionInput, occupationalPensionInput);
    return _applyIdecoAndInvestmentTrustToBase(
      base: base,
      idecoInput: idecoInput,
      investmentTrustInput: investmentTrustInput,
      monthlyLivingExpenses: monthlyLivingExpenses,
      targetAge: targetAge,
      occupationalPensionMonthly: base.occupationalPensionMonthly,
      occupationalPensionAnnual: base.occupationalPensionAnnual,
    );
  }

  /// iDeCo + 投資信託 複合モデルの共通ロジック
  ///
  /// iDeCoは独立した2段階モデルで計算し、投資信託はiDeCoのバックアップとして機能。
  ///
  /// 【iDeCo】標準2段階モデル（投資信託と独立して計算）
  ///   Phase 1b: 60歳 → 公的年金受給開始（生活費全額をカバー）
  ///   Phase 2: 公的年金受給開始以降（不足分をカバー）
  ///
  /// 【投資信託】iDeCoバックアップモデル
  ///   Step 1: 引出開始 → 60歳（生活費全額をカバー）
  ///   Step 2: 60歳 → iDeCo枯渇（iDeCoがカバー中、運用のみ）
  ///   Step 3: iDeCo枯渇後（不足分をカバー）
  static PensionResult _applyIdecoAndInvestmentTrustToBase({
    required PensionResult base,
    required IdecoInput idecoInput,
    required InvestmentTrustInput investmentTrustInput,
    required double monthlyLivingExpenses,
    required int targetAge,
    required double occupationalPensionMonthly,
    required double occupationalPensionAnnual,
  }) {
    final idecoFV = idecoInput.futureValue;
    final idecoR = idecoInput.monthlyReturnRate;
    final itFV = investmentTrustInput.futureValue;
    final itR = investmentTrustInput.monthlyReturnRate;
    final publicPensionMonthly = base.basicPensionMonthly + occupationalPensionMonthly;

    final idecoStartAge = idecoInput.pensionStartAge; // 60
    final itStartAge = investmentTrustInput.withdrawalStartAge;
    final publicStartAge = base.pensionStartAge;

    // Phase 2の不足分（公的年金受給開始以降）
    final phase2ShortfallRaw = monthlyLivingExpenses > 0
        ? monthlyLivingExpenses - publicPensionMonthly
        : 0.0;
    final phase2Shortfall = phase2ShortfallRaw > 0 ? phase2ShortfallRaw : 0.0;

    // === iDeCo: 標準2段階モデル（投資信託と独立して計算） ===
    final idecoPrePensionMonths = publicStartAge > idecoStartAge
        ? (publicStartAge - idecoStartAge) * 12
        : 0;

    double idecoExhaustionAge = 0.0;
    bool isIdecoSufficient = true;
    double idecoMonthly = 0.0;

    if (monthlyLivingExpenses > 0 && idecoFV > 0) {
      final idecoRemainingAfterPhase1 = _balanceAfterDrawdown(
          idecoFV, monthlyLivingExpenses, idecoR, idecoPrePensionMonths);

      if (idecoRemainingAfterPhase1 <= 0) {
        // Phase 1b中にiDeCo枯渇
        final months =
            _monthsUntilExhaustion(idecoFV, monthlyLivingExpenses, idecoR);
        idecoExhaustionAge = idecoStartAge + months / 12.0;
        isIdecoSufficient = idecoExhaustionAge >= targetAge;
        idecoMonthly = 0.0;
      } else if (phase2Shortfall > 0) {
        // Phase 2: iDeCoで不足分を補填
        idecoMonthly = phase2Shortfall;
        final months = _monthsUntilExhaustion(
            idecoRemainingAfterPhase1, phase2Shortfall, idecoR);
        idecoExhaustionAge = months == double.infinity
            ? double.infinity
            : publicStartAge.toDouble() + months / 12.0;
        isIdecoSufficient = idecoExhaustionAge >= targetAge;
      }
    }

    // === 投資信託: iDeCoバックアップモデル ===
    double itExhaustionAge = 0.0;
    bool isItSufficient = true;
    double itMonthly = 0.0;

    if (monthlyLivingExpenses > 0 && itFV > 0) {
      double itBalance = itFV;

      // Step 1: IT引出開始 → iDeCo開始(60歳) — ITが生活費をカバー
      if (itStartAge < idecoStartAge) {
        final step1Months = (idecoStartAge - itStartAge) * 12;
        itBalance = _balanceAfterDrawdown(
            itBalance, monthlyLivingExpenses, itR, step1Months);
      }

      if (itBalance <= 0) {
        // Step 1でIT枯渇
        final months =
            _monthsUntilExhaustion(itFV, monthlyLivingExpenses, itR);
        itExhaustionAge = itStartAge + months / 12.0;
        isItSufficient = itExhaustionAge >= targetAge;
      } else if (idecoExhaustionAge == 0.0 ||
          idecoExhaustionAge == double.infinity) {
        // iDeCoが永久に持つ or iDeCoなし → IT補填不要
        isItSufficient = true;
        itMonthly = 0.0;
      } else {
        // iDeCoが有限期間で枯渇 → ITがバックアップ

        // Step 2: iDeCoカバー期間はITが運用のみ
        final compoundStart =
            math.max(idecoStartAge, itStartAge).toDouble();
        if (idecoExhaustionAge > compoundStart) {
          final compoundMonths =
              ((idecoExhaustionAge - compoundStart) * 12).round();
          if (itR > 0 && compoundMonths > 0) {
            itBalance = itBalance *
                math.pow(1 + itR, compoundMonths).toDouble();
          }
        }

        // Step 3: iDeCo枯渇後 → ITが不足分をカバー
        if (idecoExhaustionAge < publicStartAge.toDouble()) {
          // Case A: iDeCoが公的年金受給前に枯渇
          // → ITが年金受給開始まで生活費を全額カバー
          final prePensionMonths =
              ((publicStartAge - idecoExhaustionAge) * 12).round();
          final itBalanceAtIdecoExhaustion = itBalance;
          itBalance = _balanceAfterDrawdown(
              itBalance, monthlyLivingExpenses, itR, prePensionMonths);

          if (itBalance <= 0) {
            // 年金受給前にITも枯渇
            final months = _monthsUntilExhaustion(
                itBalanceAtIdecoExhaustion, monthlyLivingExpenses, itR);
            itExhaustionAge = idecoExhaustionAge + months / 12.0;
            isItSufficient = itExhaustionAge >= targetAge;
            itMonthly = 0.0;
          } else if (phase2Shortfall > 0) {
            // 年金受給後: ITが不足分をカバー
            itMonthly = phase2Shortfall;
            final months =
                _monthsUntilExhaustion(itBalance, phase2Shortfall, itR);
            itExhaustionAge = months == double.infinity
                ? double.infinity
                : publicStartAge.toDouble() + months / 12.0;
            isItSufficient = itExhaustionAge >= targetAge;
          } else {
            isItSufficient = true;
            itMonthly = 0.0;
          }
        } else {
          // Case B: iDeCoが公的年金受給後に枯渇
          // → ITがiDeCo枯渇後に不足分をカバー
          if (phase2Shortfall > 0) {
            itMonthly = phase2Shortfall;
            final months =
                _monthsUntilExhaustion(itBalance, phase2Shortfall, itR);
            itExhaustionAge = months == double.infinity
                ? double.infinity
                : idecoExhaustionAge + months / 12.0;
            isItSufficient = itExhaustionAge >= targetAge;
          } else {
            isItSufficient = true;
            itMonthly = 0.0;
          }
        }
      }
    }

    return PensionResult(
      basicPensionMonthly: base.basicPensionMonthly,
      basicPensionAnnual: base.basicPensionAnnual,
      occupationalPensionMonthly: occupationalPensionMonthly,
      occupationalPensionAnnual: occupationalPensionAnnual,
      idecoMonthly: idecoMonthly,
      idecoAnnual: idecoMonthly * 12,
      monthlyLivingExpenses: monthlyLivingExpenses,
      monthlyShortfall: phase2Shortfall,
      idecoFutureValue: idecoFV,
      idecoExhaustionAge: idecoExhaustionAge,
      isIdecoSufficient: isIdecoSufficient,
      investmentTrustMonthly: itMonthly,
      investmentTrustAnnual: itMonthly * 12,
      investmentTrustFutureValue: itFV,
      investmentTrustExhaustionAge: itExhaustionAge,
      isInvestmentTrustSufficient: isItSufficient,
      targetAge: targetAge,
      totalPensionMonthly: base.basicPensionMonthly +
          occupationalPensionMonthly +
          idecoMonthly +
          itMonthly,
      totalPensionAnnual: base.basicPensionAnnual +
          occupationalPensionAnnual +
          (idecoMonthly + itMonthly) * 12,
      adjustmentRate: base.adjustmentRate,
      pensionStartAge: base.pensionStartAge,
    );
  }

  // ---------------------------------------------------------------------------

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
