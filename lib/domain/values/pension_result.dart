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

  /// 合計年金月額（円）
  ///
  /// basicPensionMonthly + occupationalPensionMonthly
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
├─────────────────────────────────────────────┤
│ 合計（月額）: ¥${totalPensionMonthly.toStringAsFixed(0)}  │
│ 合計（年額）: ¥${totalPensionAnnual.toStringAsFixed(0)}  │
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
      totalPensionMonthly,
      totalPensionAnnual,
      adjustmentRate,
      pensionStartAge,
    );
  }
}
