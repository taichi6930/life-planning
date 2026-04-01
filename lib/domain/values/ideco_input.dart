/// iDeCo（個人型確定拠出年金）計算入力パラメータ
///
/// iDeCoは、公的年金に上乗せして積み立てる私的年金制度。
/// 加入者が自ら毎月の掛金を積み立て、60歳以降に受け取る。
/// 掛金は全額所得控除の対象となり、節税効果が高い。
///
/// 【参考資料】
/// - iDeCo公式サイト（国民年金基金連合会）
///   https://www.ideco-koushiki.jp/
/// - 厚生労働省「iDeCo（個人型確定拠出年金）の概要」
///   https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/nenkin/kyoshutsu/ideco.html
///
/// 【掛金上限額（月額）】※2025年改正（2026年12月1日施行予定）後の値
/// iDeCoの掛金上限は加入者の職業・加入状況によって異なる：
/// - 自営業者等（第1号被保険者）: 月額 75,000円（旧68,000円 → 2026/12/1改正予定）
/// - 企業年金なし会社員（第2号・第3号被保険者）: 月額 62,000円（旧23,000円 → 2026/12/1改正予定）
/// - 企業年金あり会社員（企業年金との合算上限）: 月額 62,000円（旧55,000円 → 2026/12/1改正予定）
///   - iDeCoの拠出上限 = 62,000円 − 企業年金掛金相当額
/// 参照: 厚生労働省「2025年の制度改正」
///   https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/nenkin/nenkin/kyoshutsu/2025kaisei.html
///
/// 【受給可能年齢】
/// - 60歳以降に受け取り可能（通算加入者等期間が10年以上の場合）
/// - 最大75歳まで受給開始を繰り下げ可能（2022年改正）
/// - 一時金受取（退職所得控除）または年金受取（公的年金等控除）を選択
///
/// 【積立計算式】
/// 月々拠出額を複利運用したときの将来価値（FV）を以下の式で計算：
///   FV = PMT × ((1 + r_m)^n - 1) / r_m
/// ここで:
///   PMT: 月額拠出額（円）
///   r_m: 月利（= 年利回り / 12）
///   n  : 拠出月数
///
/// 【年金受取月額の算出】
///   月額受取 = FV / (受取期間（月数）)
///
/// ※ 本実装では元本保証型（想定利回り0%）と積極運用型の両方をサポート
class IdecoInput {
  /// iDeCoの加入可能な最大掛金月額（自営業者等、第1号被保険者）
  ///
  /// 国民年金基金または付加保険料との合算で月額75,000円が上限
  /// 2025年改正（2026年12月1日施行予定）: 68,000円 → 75,000円
  static const int maxMonthlyContributionSelfEmployed = 75000;

  /// iDeCoの加入可能な最大掛金月額（企業年金なし会社員・専業主婦等）
  ///
  /// 第2号被保険者（企業年金なし）・第3号被保険者共通
  /// 2025年改正（2026年12月1日施行予定）: 23,000円 → 62,000円
  static const int maxMonthlyContributionEmployee = 62000;

  /// iDeCoの加入可能な最大掛金月額（企業型DCのみに加入している会社員）
  ///
  /// 企業型DCの事業主掛金と合算して月額62,000円が上限（旧5.5万円）
  /// iDeCoの拠出上限 = 62,000円 − 企業型DC事業主掛金額
  /// 2025年改正（2026年12月1日施行予定）: 合算上限 55,000円 → 62,000円
  static const int maxMonthlyContributionEmployeeWithDCOnly = 62000;

  /// iDeCoの加入可能な最大掛金月額（DB・企業型DC併用の会社員 / 公務員等）
  ///
  /// 2024年12月1日改正: 1.2万円 → 2万円に引上げ
  /// 2025年改正（2026年12月1日施行予定）: 合算上限 55,000円 → 62,000円
  /// iDeCoの拠出上限 = 62,000円 − (企業型DC事業主掛金額 + DB等掛金相当額)
  static const int maxMonthlyContributionWithDBOrPublic = 62000;

  /// iDeCoに加入できる最小年齢（20歳）
  static const int minJoinAge = 20;

  /// iDeCoの拠出終了年齢（2026年12月1日改正予定で70歳まで延長）
  ///
  /// 2025年改正（2026年12月1日施行予定）: 65歳 → 70歳
  /// 働き方にかかわらず、70歳になるまでiDeCoに加入し老後の資産形成が可能になる
  static const int maxContributionEndAge = 70;

  /// iDeCoの受給開始最低年齢（60歳）
  static const int minPensionReceiptAge = 60;

  /// iDeCoの受給開始最大年齢（75歳、2022年改正）
  static const int maxPensionReceiptAge = 75;

  /// 月額拠出額（円）
  ///
  /// 掛金の最低額は月額 5,000円（1,000円単位で設定可能）
  /// 有効範囲: 5,000円以上、職業種別の上限以下
  final int monthlyContribution;

  /// 加入者の現在年齢（拠出開始年齢）
  ///
  /// 有効範囲: 20歳以上65歳未満
  final int currentAge;

  /// 拠出終了年齢
  ///
  /// 原則として65歳誕生日の前月まで拠出可能
  /// 有効範囲: currentAge より大きく、maxContributionEndAge 以下
  final int contributionEndAge;

  /// 想定年利回り（%）
  ///
  /// 複利計算に使用する年間の期待収益率
  /// 例: 3.0 → 年利3.0%
  ///
  /// 【目安】
  /// - 元本保証型（定期預金・保険）: 0.01%〜0.5%
  /// - 債券中心: 1.0%〜2.0%
  /// - バランス型: 2.0%〜4.0%
  /// - 株式中心: 4.0%〜7.0%
  ///
  /// 有効範囲: 0.0%以上20.0%以下
  final double expectedAnnualReturnRate;

  /// 受給開始年齢
  ///
  /// デフォルトは65歳（基礎年金・厚生年金と揃える）
  /// 有効範囲: 60歳以上75歳以下
  final int pensionStartAge;

  /// 現在の投資残高（既に積み立てた金額、円）
  ///
  /// iDeCoに既に積み立てている場合の残高。
  /// この残高も拠出期間中に複利運用される。
  /// デフォルトは0（新規加入）。
  final int currentBalance;

  const IdecoInput({
    required this.monthlyContribution,
    required this.currentAge,
    this.contributionEndAge = maxContributionEndAge,
    this.expectedAnnualReturnRate = 3.0,
    this.pensionStartAge = minPensionReceiptAge,
    this.currentBalance = 0,
  });

  /// 拠出月数（currentAge から受給開始年齢まで）
  ///
  /// iDeCoは受給開始と同時に拠出が終わるため、
  /// 実効的な拠出終了年齢 = min(pensionStartAge, contributionEndAge) を使用する。
  ///
  /// 例: 現在30歳, 受給開始60歳 → 360ヶ月
  /// 例: 現在30歳, 受給開始70歳（繰り下げ）, 上限70歳 → 480ヶ月
  /// 例: 既に受給開始年齢を超えている場合 → 0ヶ月（残高のみ）
  int get contributionMonths {
    final effectiveEndAge = pensionStartAge < contributionEndAge
        ? pensionStartAge
        : contributionEndAge;
    if (effectiveEndAge <= currentAge) return 0;
    return (effectiveEndAge - currentAge) * 12;
  }

  /// 月利（年利回りを12で割った値）
  ///
  /// 例: 年利3.0% → 月利0.25% = 0.0025
  double get monthlyReturnRate => expectedAnnualReturnRate / 100.0 / 12.0;

  /// 受給開始時点での将来価値（FV）を計算
  ///
  /// 拠出期間中の複利運用 + 拠出終了〜受給開始間のギャップ期間の複利運用を含む。
  ///
  /// 【Step 1】拠出期間の将来価値:
  ///   FV_contrib = currentBalance × (1 + r_m)^n + PMT × ((1 + r_m)^n - 1) / r_m
  ///
  /// 【Step 2】ギャップ期間（拠出終了〜受給開始）の複利運用:
  ///   FV = FV_contrib × (1 + r_m)^gapMonths
  ///
  /// 例: 30歳開始、60歳拠出終了、65歳受給開始の場合
  ///   → 30〜60歳の拠出期間でFV_contribを計算
  ///   → 60〜65歳の5年間（60ヶ月）は拠出なしで運用継続
  ///
  /// 利回り0%（元本保証型）の場合は単純積算:
  ///   FV = currentBalance + PMT × n
  double get futureValue {
    final n = contributionMonths;
    final pmt = monthlyContribution.toDouble();
    final r = monthlyReturnRate;
    final balance = currentBalance.toDouble();

    if (r == 0.0) {
      // 元本保証型（利回り0%）
      return balance + pmt * n;
    }

    // Step 1: 拠出期間中のFV
    final compoundFactor = (1 + r).pow(n);
    final fvAtContributionEnd =
        balance * compoundFactor + pmt * (compoundFactor - 1) / r;

    // Step 2: 拠出終了〜受給開始のギャップ期間の複利運用
    final effectiveEndAge = pensionStartAge < contributionEndAge
        ? pensionStartAge
        : contributionEndAge;
    final gapMonths = (pensionStartAge - effectiveEndAge) * 12;
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
    if (currentAge < minJoinAge || currentAge >= maxContributionEndAge) {
      return false;
    }
    if (contributionEndAge <= currentAge ||
        contributionEndAge > maxContributionEndAge) {
      return false;
    }
    if (expectedAnnualReturnRate < 0.0 || expectedAnnualReturnRate > 20.0) {
      return false;
    }
    if (pensionStartAge < minPensionReceiptAge ||
        pensionStartAge > maxPensionReceiptAge) {
      return false;
    }
    return true;
  }
}

/// [double] に累乗計算を追加する拡張メソッド
extension _DoublePow on double {
  double pow(int exponent) {
    if (exponent == 0) return 1.0;
    double result = 1.0;
    double base = this;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
