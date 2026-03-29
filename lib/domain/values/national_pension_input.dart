/// 国民年金（基礎年金）計算入力パラメータ
/// 
/// 日本の国民年金制度に基づいて、基礎年金額を計算するための入力データを定義。
/// 国民年金は、日本に住む20歳以上60歳未満のすべての国民が加入する強制加入制度。
/// 
/// 【参考資料】
/// - 日本年金機構「国民年金」
///   https://www.nenkin.go.jp/service/kokumin-nenkin/kokumin-nenkin.html
/// - 厚生労働省「2024年度の年金額改定について」
///   https://www.mhlw.go.jp/steshingi/nenkin/
/// 
/// 【基本額について】
/// 国民年金の基本額（満額）は、保険料納付期間が480月（40年間）の場合に受給できる
/// 基礎年金額の基準です。毎年度、物価スライドに基づいて改定されます。
/// 
/// 【年度別基本年金額（月額）】
/// - 2024年度：¥68,000
/// - 2025年度：¥69,308（前年度比 +1,308円、1.9%引き上げ）
/// - 2026年度：未発表（見込み中）
/// 
/// ※ 参考：厚生労働省「令和7年度の年金額改定について」
///   https://www.mhlw.go.jp/content/12600000/001436802.pdf
/// 
/// 実際の受給額は以下の計算式によります：
/// ```
/// 基礎年金額（月額）= 基本月額 × (納付月数 / 480)
/// 基礎年金額（年額）= 基本月額 × 12 × (納付月数 / 480)
/// ```
/// 
/// 【納付月数について】
/// - フル納付: 480月（40年） → 基本額の100%受給可能
/// - 部分納付: 納付月数 < 480月 → 基本額に (納付月数/480) を乗算した額を受給
/// - 免除期間: 保険料納付が困難な場合、全額・3/4・半額・1/4免除の制度あり
/// - 学生納付特例: 在学中の納付猶予制度あり（納付月に直接カウントされず、追納待機中）
/// 
/// 【受給開始年齢】
/// 通常は65歳から受給開始（厚生労働省が推奨）
/// ただし、60歳～64歳での早期受給や、66歳以降の繰り下げ受給も制度あり
/// 
/// 【対象者】
/// - 国民年金加入者
/// - 厚生年金加入者（独立して受給）
/// - 船員保険加入者
class NationalPensionInput {
  /// 2025年度（令和7年度）国民年金基本年金月額
  /// 
  /// 参考：厚生労働省公式発表「令和7年度の年金額改定について」
  /// 2024年度(¥68,000)から1.9%の物価スライド改定で引き上げ
  /// https://www.mhlw.go.jp/content/12600000/001436802.pdf
  /// 
  /// 【年度別基本年金月額の推移】
  /// - 2024年度: ¥68,000
  /// - 2025年度: ¥69,308（+1,308円、1.9%引き上げ）
  /// - 2026年度: 未発表（見込み中）
  /// 
  /// 毎年度4月にスライド改定されるため、年度ごとに値を更新する必要あり
  /// 最新値は常に厚生労働省の公式発表を確認すること
  static const double basicPensionMonthlyAmount = 69308.0;

  /// 年金法で定められた標準的な受給開始年齢（2024年現在）
  /// 
  /// 2023年4月の法改正により、今後段階的に65歳に統一予定
  /// （現在の制度では生年月日によって異なる場合あり）
  static const int pensionStartAge = 65;

  /// 国民年金の完全納付期間（40年間 = 480ヶ月）
  /// 
  /// 日本の国民年金制度では、加入期間の上限が40年と定められている
  /// これは20歳から60歳までの期間に相当する
  /// 
  /// 480月フル納付の場合のみ、基本額の100%を受給できる
  static const int fullContributionMonths = 480;

  /// 保険料を全額納付した月数（0月以上）
  /// 
  /// 完全な保険料納付期間をカウント
  final int fullContribution;

  /// 全額免除期間の月数（免除時、1/2 にカウント）
  /// 
  /// 使用場面: 失業・法人破産・大災害など、経済的能力を完全に失った場合
  /// 例：失業保険受給中に免除申請、事業倒産による無収入期間
  final int fullExempt;

  /// 3/4免除期間の月数（免除時、5/8 にカウント）
  /// 
  /// 使用場面: 一定の経済的困窮状況
  final int threeQuarterExempt;

  /// 半額免除期間の月数（免除時、3/4 にカウント）
  /// 
  /// 使用場面: 軽度の経済的困窮状況
  final int halfExempt;

  /// 1/4免除期間の月数（免除時、7/8 にカウント）
  /// 
  /// 使用場面: 最小限の経済的困窮状況
  final int quarterExempt;

  /// 学生納付特例期間の月数（納付月にカウントされない、追納待機中）
  /// 
  /// 使用場面: 学生期間中の納付猶予
  /// 特徴：
  /// - 在学中は保険料納付を猶予される
  /// - 本フィールドで指定した月数は、effectiveContributionMonths に含まれない
  /// - 卒業後に「追納」（過去の保険料を遡及納付）することで、納付月数に算入可能
  /// - 将来の拡張: 追納済み月数を管理する別フィールドを追加予定
  final int studentDeferment;

  /// 免除期間の有無（計算上の調整が必要かどうか）
  /// 
  /// true の場合: 保険料免除期間を含む特別な計算が必要
  /// false の場合: 納付月数のみで計算可能
  /// 
  /// 注意: 本フィールドは冗長であり、他のフィールドで免除月数が 0 でなければ
  /// true となる。レガシー互換性またはUI表示用に保持。
  final bool hasPaymentSuspension;

  /// 希望する年金受給開始年齢（ユーザー指定）
  /// 
  /// 有効範囲: 60～75歳
  /// 
  /// 【制度】
  /// - 繰上げ受給（60～64歳）: 月0.4%減額（受給期間が長い分を調整）
  /// - 標準受給（65歳）: 減額なし
  /// - 繰下げ受給（66～75歳）: 月0.7%増額（受給期間が短い分を調整）
  /// 
  /// 【計算例】
  /// - 60歳受給（5年早期）: 100% - (0.4% × 60月) = 76%
  /// - 70歳受給（5年繰下）: 100% + (0.7% × 60月) = 142%
  /// 
  /// この値に基づいて調整率（adjustmentRate）が計算される
  final int desiredPensionStartAge;

  NationalPensionInput({
    required this.fullContribution,
    this.fullExempt = 0,
    this.threeQuarterExempt = 0,
    this.halfExempt = 0,
    this.quarterExempt = 0,
    this.studentDeferment = 0,
    required this.hasPaymentSuspension,
    required this.desiredPensionStartAge,
  });

  /// 入力値の妥当性チェック
  /// 
  /// 検証項目:
  /// 1. 全フィールドが非負: fullContribution >= 0（免除フィールドはデフォルト0）
  /// 2. 有効納付月数の合計: effectiveContributionMonths が 0 ～ 480月以内
  /// 3. desiredPensionStartAge: 60歳以上75歳以下
  /// 
  /// 戻り値: true = 有効, false = 不正な値
  bool isValid() {
    final effective = effectiveContributionMonths;
    return fullContribution >= 0 &&
        effective >= 0 &&
        effective <= fullContributionMonths &&
        desiredPensionStartAge >= 60 &&
        desiredPensionStartAge <= 75;
  }

  /// 全ての免除期間を考慮した有効納付月数を計算
  /// 
  /// 計算式:
  /// = fullContribution + 
  ///   (fullExempt × 1/2) +
  ///   (threeQuarterExempt × 5/8) +
  ///   (halfExempt × 3/4) +
  ///   (quarterExempt × 7/8)
  /// 
  /// 免除期間はその種別に応じた比率で納付月数としてカウントされる
  /// 
  /// 戻り値: 有効納付月数（小数点以下も含む）
  double get effectiveContributionMonths {
    return fullContribution +
        (fullExempt * 1 / 2) +
        (threeQuarterExempt * 5 / 8) +
        (halfExempt * 3 / 4) +
        (quarterExempt * 7 / 8);
  }

  /// 受給開始の遅延・早期受給に基づく調整率を計算
  /// 
  /// 戻り値: 0.76～1.42 の範囲の倍率
  /// 
  /// 【計算式】
  /// - 繰上げ受給（60～64歳）: 1.0 - (0.004 × (65 - desiredPensionStartAge) × 12)
  /// - 標準受給（65歳）: 1.0
  /// - 繰下げ受給（66～75歳）: 1.0 + (0.007 × (desiredPensionStartAge - 65) × 12)
  /// 
  /// 【例】
  /// - 60歳受給: 1.0 - (0.004 × 5 × 12) = 1.0 - 0.24 = 0.76 (76%)
  /// - 70歳受給: 1.0 + (0.007 × 5 × 12) = 1.0 + 0.42 = 1.42 (142%)
  double getPensionAdjustmentRate() {
    const double earlyReductionPerMonth = 0.004; // 繰上げ月0.4%減
    const double delayIncreasePerMonth = 0.007;  // 繰下げ月0.7%増

    if (desiredPensionStartAge < pensionStartAge) {
      // 繰上げ受給
      final months = (pensionStartAge - desiredPensionStartAge) * 12;
      return 1.0 - (earlyReductionPerMonth * months);
    } else if (desiredPensionStartAge > pensionStartAge) {
      // 繰下げ受給
      final months = (desiredPensionStartAge - pensionStartAge) * 12;
      return 1.0 + (delayIncreasePerMonth * months);
    } else {
      // 標準受給（65歳）
      return 1.0;
    }
  }

  /// 現在の基礎年金基本月額を取得
  /// 
  /// 戻り値: 月額（¥）
  /// 
  /// 本来は外部データベースから年度情報を取得すべきだが、
  /// MVP段階では固定値を返す。
  /// 
  /// 今後の改善:
  /// - 年度情報を外部から取得（厚生労働省API等）
  /// - 物価スライド情報を含める
  /// - 過去年度の基本額履歴を管理
  static double getCurrentBasicPensionAmount() {
    return basicPensionMonthlyAmount;
  }

  /// 現在の基礎年金基本年額を取得（月額から計算）
  /// 
  /// 戻り値: 年額（¥）
  /// 
  /// 計算式: basicPensionMonthlyAmount × 12
  /// 
  /// 月額から動的に計算するため、月額の値を変更すれば
  /// 年額も自動的に更新されます。
  static double getCurrentBasicPensionAnnualAmount() {
    return basicPensionMonthlyAmount * 12;
  }
}
