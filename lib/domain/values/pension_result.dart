/// 年金計算結果を保持する値オブジェクト
///
/// 基礎年金、厚生年金、およびそれらの組み合わせの計算結果を保持する。
/// 月額・年額の両方の形式で提供する。
class PensionResult {
  /// 基礎年金月額（円）
  ///
  /// 国民年金から受け取る月額。
  /// 調整率（繰上げ/繰下げ）を反映済み。
  final double basicPensionMonthly;

  /// 基礎年金年額（円）
  ///
  /// basicPensionMonthly × 12
  final double basicPensionAnnual;

  /// 厚生年金月額（円）
  ///
  /// 報酬比例部分と加給年金の合計。
  /// 調整率（繰上げ/繰下げ）を反映済み。
  final double occupationalPensionMonthly;

  /// 厚生年金年額（円）
  ///
  /// occupationalPensionMonthly × 12
  final double occupationalPensionAnnual;

  /// iDeCo月額（円）
  ///
  /// iDeCoからの月額引出額。不足分補填モデルでは、
  /// 生活費 - 公的年金 の不足分に相当する。
  /// 加入なし or 不足分なしの場合は0.0
  final double idecoMonthly;

  /// iDeCo年額（円）
  ///
  /// idecoMonthly × 12
  final double idecoAnnual;

  /// 月額生活費（円）
  ///
  /// ユーザーが想定する毎月の生活費。
  /// 不足分の計算に使用。入力がない場合は0.0
  final double monthlyLivingExpenses;

  /// 月額不足分（円）
  ///
  /// 生活費から公的年金（基礎+厚生）を引いた不足額。
  /// 正の値: 年金では生活費を賄えない（iDeCoで補填が必要）
  /// 0以下: 年金だけで生活費を賄える
  final double monthlyShortfall;

  /// iDeCo積立将来価値（円）
  ///
  /// 拠出終了時点での積立総額（複利運用後）
  final double idecoFutureValue;

  /// iDeCo枯渇年齢
  ///
  /// iDeCoの積立金が底をつく年齢（小数点あり）。
  /// 不足分がない場合や iDeCo なしの場合は0.0
  final double idecoExhaustionAge;

  /// 想定寿命（歳）
  ///
  /// iDeCoの充足判定に使用するターゲット年齢。デフォルト90歳
  final int targetAge;

  /// iDeCo充足判定
  ///
  /// iDeCoの積立金が想定寿命まで持つかどうか。
  /// true: 枯渇年齢 >= 想定寿命（足りる）
  /// false: 枯渇年齢 < 想定寿命（足りない）
  final bool isIdecoSufficient;

  /// 合計年金月額（円）
  ///
  /// basicPensionMonthly + occupationalPensionMonthly + idecoMonthly
  final double totalPensionMonthly;

  /// 合計年金年額（円）
  ///
  /// totalPensionMonthly × 12
  final double totalPensionAnnual;

  /// 調整率（繰上げ/繰下げによる増減）
  ///
  /// 0.76 ～ 1.84 の範囲で、基本額に対する倍率
  /// - 60歳受給（繰上げ）: 0.76倍
  /// - 65歳受給（標準）: 1.0倍
  /// - 75歳受給（繰下げ最大）: 1.84倍
  final double adjustmentRate;

  /// 受給開始年齢
  final int pensionStartAge;

  PensionResult({
    required this.basicPensionMonthly,
    required this.basicPensionAnnual,
    required this.occupationalPensionMonthly,
    required this.occupationalPensionAnnual,
    this.idecoMonthly = 0.0,
    this.idecoAnnual = 0.0,
    this.monthlyLivingExpenses = 0.0,
    this.monthlyShortfall = 0.0,
    this.idecoFutureValue = 0.0,
    this.idecoExhaustionAge = 0.0,
    this.targetAge = 90,
    this.isIdecoSufficient = true,
    required this.totalPensionMonthly,
    required this.totalPensionAnnual,
    required this.adjustmentRate,
    required this.pensionStartAge,
  });

  /// 見やすくフォーマットされた文字列表現
  ///
  /// 日本円の通貨形式と、繰上げ/繰下げの状態を含む。
  @override
  String toString() {
    final adjustmentLabel = adjustmentRate < 1.0 ? '繰上げ' : adjustmentRate > 1.0 ? '繰下げ' : '標準';
    final adjustmentPercent = ((adjustmentRate - 1.0) * 100).toStringAsFixed(1);
    final shortfallLabel = monthlyShortfall > 0 ? '不足' : '余裕';
    final sufficientLabel = isIdecoSufficient ? '足りる' : '足りない';
    
    return '''
┌─────────────────────────────────────────────┐
│     年金受給額シミュレーション結果             │
├─────────────────────────────────────────────┤
│ 受給開始年齢: $pensionStartAge歳             │
│ 調整率: $adjustmentLabel ($adjustmentPercent%)     │
├─────────────────────────────────────────────┤
│ 基礎年金（月額）: ¥${basicPensionMonthly.toStringAsFixed(0)}  │
│ 基礎年金（年額）: ¥${basicPensionAnnual.toStringAsFixed(0)}  │
│                                             │
│ 厚生年金（月額）: ¥${occupationalPensionMonthly.toStringAsFixed(0)}  │
│ 厚生年金（年額）: ¥${occupationalPensionAnnual.toStringAsFixed(0)}  │
│                                             │
│ iDeCo（月額）: ¥${idecoMonthly.toStringAsFixed(0)}  │
│ iDeCo（年額）: ¥${idecoAnnual.toStringAsFixed(0)}  │
├─────────────────────────────────────────────┤
│ 合計（月額）: ¥${totalPensionMonthly.toStringAsFixed(0)}  │
│ 合計（年額）: ¥${totalPensionAnnual.toStringAsFixed(0)}  │
├─────────────────────────────────────────────┤
│ 月額生活費: ¥${monthlyLivingExpenses.toStringAsFixed(0)}  │
│ 月額$shortfallLabel: ¥${monthlyShortfall.abs().toStringAsFixed(0)}  │
│ iDeCo積立額: ¥${idecoFutureValue.toStringAsFixed(0)}  │
│ iDeCo枯渇年齢: ${idecoExhaustionAge.toStringAsFixed(1)}歳  │
│ 想定寿命: $targetAge歳                       │
│ 判定: $sufficientLabel                       │
└─────────────────────────────────────────────┘
''';
  }

  /// デバッグ用の詳細な文字列表現
  String toDebugString() {
    return '''PensionResult(
  basicPensionMonthly: $basicPensionMonthly,
  basicPensionAnnual: $basicPensionAnnual,
  occupationalPensionMonthly: $occupationalPensionMonthly,
  occupationalPensionAnnual: $occupationalPensionAnnual,
  idecoMonthly: $idecoMonthly,
  idecoAnnual: $idecoAnnual,
  monthlyLivingExpenses: $monthlyLivingExpenses,
  monthlyShortfall: $monthlyShortfall,
  idecoFutureValue: $idecoFutureValue,
  idecoExhaustionAge: $idecoExhaustionAge,
  targetAge: $targetAge,
  isIdecoSufficient: $isIdecoSufficient,
  totalPensionMonthly: $totalPensionMonthly,
  totalPensionAnnual: $totalPensionAnnual,
  adjustmentRate: $adjustmentRate,
  pensionStartAge: $pensionStartAge,
)''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PensionResult &&
        other.basicPensionMonthly == basicPensionMonthly &&
        other.basicPensionAnnual == basicPensionAnnual &&
        other.occupationalPensionMonthly == occupationalPensionMonthly &&
        other.occupationalPensionAnnual == occupationalPensionAnnual &&
        other.idecoMonthly == idecoMonthly &&
        other.idecoAnnual == idecoAnnual &&
        other.monthlyLivingExpenses == monthlyLivingExpenses &&
        other.monthlyShortfall == monthlyShortfall &&
        other.idecoFutureValue == idecoFutureValue &&
        other.idecoExhaustionAge == idecoExhaustionAge &&
        other.targetAge == targetAge &&
        other.isIdecoSufficient == isIdecoSufficient &&
        other.totalPensionMonthly == totalPensionMonthly &&
        other.totalPensionAnnual == totalPensionAnnual &&
        other.adjustmentRate == adjustmentRate &&
        other.pensionStartAge == pensionStartAge;
  }

  @override
  int get hashCode {
    return Object.hash(
      basicPensionMonthly,
      basicPensionAnnual,
      occupationalPensionMonthly,
      occupationalPensionAnnual,
      idecoMonthly,
      idecoAnnual,
      monthlyLivingExpenses,
      monthlyShortfall,
      idecoFutureValue,
      idecoExhaustionAge,
      targetAge,
      isIdecoSufficient,
      totalPensionMonthly,
      totalPensionAnnual,
      adjustmentRate,
      pensionStartAge,
    );
  }
}
