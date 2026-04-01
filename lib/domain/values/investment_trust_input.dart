import 'dart:math' as math;

extension _Pow on double {
  double pow(int exponent) => math.pow(this, exponent).toDouble();
}

/// 投資信託（積立投資）計算入力パラメータ
///
/// 投資信託は、証券会社や銀行を通じて購入できる運用商品。
/// 多くの投資家から資金を集め、株式・債券などへ分散投資する。
///
/// iDeCo と異なり、年齢制限がなく自由な積立・引出が可能。
/// NISA口座（新NISA）や特定口座を通じて非課税メリットを活用できる。
///
/// 【参考資料】
/// - 金融庁「新しいNISA」
///   https://www.fsa.go.jp/policy/nisa2/about/index.html
/// - 投資信託協会
///   https://www.toushin.or.jp/
///
/// 【iDeCoとの主な違い】
/// - 年齢制限なし（iDeCoは加入20〜70歳、受給60歳〜）
/// - 引出開始年齢に制限なし（60歳未満でも引出可能）
/// - 原則として引出しにペナルティなし
/// - 運用益：NISA口座なら非課税、特定口座なら20.315%課税
///
/// 【積立計算式】
/// 月々拠出額を複利運用したときの将来価値（FV）を以下の式で計算：
///   FV = PMT × ((1 + r_m)^n - 1) / r_m
/// ここで:
///   PMT: 月額拠出額（円）
///   r_m: 月利（= 年利回り / 12）
///   n  : 拠出月数
///
/// 【引出フェーズの計算】
/// 引出開始後、残高を運用しながら毎月引き出す「定率引出モデル」を採用。
/// 枯渇月数 n = -ln(1 - PV·r/W) / ln(1+r)  [r > 0]
/// 枯渇月数 n = PV / W                       [r = 0]
///
/// 【不足分補填モデル（2段階）】
/// Phase 1（引出開始〜公的年金受給開始）:
///   - 月額全生活費を投資信託から引き出す
/// Phase 2（公的年金受給開始〜想定寿命）:
///   - 月額不足分（生活費 - 公的年金）を投資信託から補填する
///
/// ※ 60歳未満でも引出開始を設定可能（早期リタイア・セミリタイア対応）
class InvestmentTrustInput {
  /// デフォルトの引出開始年齢（60歳）
  ///
  /// 公的年金受給開始の標準年齢に合わせたデフォルト値。
  /// ユーザーが早期引出を希望する場合は変更可能。
  static const int defaultWithdrawalStartAge = 60;

  /// 月額拠出額（円）
  ///
  /// 積立投資の月々の購入金額。
  /// 有効範囲: 1円以上
  final int monthlyContribution;

  /// 加入者の現在年齢（拠出開始年齢）
  ///
  /// 有効範囲: 0歳以上
  final int currentAge;

  /// 拠出終了年齢
  ///
  /// 積立を停止する年齢。デフォルトは引出開始年齢。
  /// 有効範囲: currentAge より大きい値
  final int contributionEndAge;

  /// 想定年利回り（%）
  ///
  /// 複利計算に使用する年間の期待収益率。
  /// 例: 5.0 → 年利5.0%
  ///
  /// 【目安】
  /// - 元本保証型（定期預金）: 0.01%〜0.5%
  /// - 債券中心: 1.0%〜2.0%
  /// - バランス型（株式50%）: 3.0%〜5.0%
  /// - 株式中心（全世界・S&P500等）: 5.0%〜8.0%
  ///
  /// 有効範囲: 0.0%以上20.0%以下
  final double expectedAnnualReturnRate;

  /// 引出開始年齢
  ///
  /// 積立金を取り崩し始める年齢。iDeCoと異なり60歳未満でも設定可能。
  /// デフォルトは60歳（公的年金受給開始の標準年齢に合わせる）。
  /// 有効範囲: 0歳以上
  final int withdrawalStartAge;

  /// 現在の投資残高（既に積み立てた金額、円）
  ///
  /// 既存の投資信託残高。この残高も拠出期間中に複利運用される。
  /// デフォルトは0（新規開始）。
  final int currentBalance;

  const InvestmentTrustInput({
    required this.monthlyContribution,
    required this.currentAge,
    int? contributionEndAge,
    this.expectedAnnualReturnRate = 5.0,
    this.withdrawalStartAge = defaultWithdrawalStartAge,
    this.currentBalance = 0,
  }) : contributionEndAge = contributionEndAge ?? withdrawalStartAge;

  /// 拠出月数（currentAge から拠出終了年齢まで）
  ///
  /// 実効的な拠出終了年齢 = min(withdrawalStartAge, contributionEndAge) を使用する。
  ///
  /// 例: 現在30歳, 引出開始60歳 → 360ヶ月
  /// 例: 現在30歳, 拠出終了50歳, 引出開始60歳 → 240ヶ月（50歳で積立停止）
  int get contributionMonths {
    final effectiveEndAge = withdrawalStartAge < contributionEndAge
        ? withdrawalStartAge
        : contributionEndAge;
    if (effectiveEndAge <= currentAge) return 0;
    return (effectiveEndAge - currentAge) * 12;
  }

  /// 月利（年利回りを12で割った値）
  ///
  /// 例: 年利5.0% → 月利0.4167% ≈ 0.004167
  double get monthlyReturnRate => expectedAnnualReturnRate / 100.0 / 12.0;

  /// 引出開始時点での将来価値（FV）を計算
  ///
  /// 拠出期間中の複利運用 + 拠出終了〜引出開始間のギャップ期間の複利運用を含む。
  ///
  /// 【Step 1】拠出期間の将来価値:
  ///   FV_contrib = currentBalance × (1 + r_m)^n + PMT × ((1 + r_m)^n - 1) / r_m
  ///
  /// 【Step 2】ギャップ期間（拠出終了〜引出開始）の複利運用:
  ///   FV = FV_contrib × (1 + r_m)^gapMonths
  ///
  /// 例: 30歳開始、45歳拠出終了、60歳引出開始の場合
  ///   → 30〜45歳の拠出期間でFV_contribを計算
  ///   → 45〜60歳の15年間（180ヶ月）は拠出なしで運用継続
  ///
  /// 利回り0%の場合は単純積算:
  ///   FV = currentBalance + PMT × n
  double get futureValue {
    final n = contributionMonths;
    final pmt = monthlyContribution.toDouble();
    final r = monthlyReturnRate;
    final balance = currentBalance.toDouble();

    if (r == 0.0) {
      return balance + pmt * n;
    }

    // Step 1: 拠出期間中のFV
    final compoundFactor = (1 + r).pow(n);
    final fvAtContributionEnd =
        balance * compoundFactor + pmt * (compoundFactor - 1) / r;

    // Step 2: 拠出終了〜引出開始のギャップ期間の複利運用
    final effectiveEndAge = withdrawalStartAge < contributionEndAge
        ? withdrawalStartAge
        : contributionEndAge;
    final gapMonths = (withdrawalStartAge - effectiveEndAge) * 12;
    if (gapMonths > 0) {
      return fvAtContributionEnd * (1 + r).pow(gapMonths);
    }

    return fvAtContributionEnd;
  }

  /// 入力値の妥当性を検証する
  ///
  /// Returns true if all values are within valid ranges, false otherwise.
  bool isValid() {
    if (monthlyContribution <= 0) return false;
    if (currentBalance < 0) return false;
    if (currentAge < 0) return false;
    if (contributionEndAge <= currentAge) return false;
    if (withdrawalStartAge < 0) return false;
    if (expectedAnnualReturnRate < 0.0 || expectedAnnualReturnRate > 20.0) {
      return false;
    }
    return true;
  }
}
