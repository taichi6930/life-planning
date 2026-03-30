/// 年齢別年金額データ DTO
///
/// 60歳から100歳までの各年齢における年金額を保持する。
/// presentation 層のグラフ表示（PensionAgeChart）に使用する。
///
/// データフロー:
///   PensionResult (domain) → pensionByAgeChartProvider (provider) → PensionByAgeData (DTO) → PensionAgeChart (molecule)
class PensionByAgeData {
  final int age;

  /// 基礎年金月額（円）
  final double basicPensionMonthly;

  /// 厚生年金月額（円）
  final double occupationalPensionMonthly;

  const PensionByAgeData({
    required this.age,
    required this.basicPensionMonthly,
    required this.occupationalPensionMonthly,
  });

  /// 合計年金月額（基礎年金 + 厚生年金）
  double get totalMonthly => basicPensionMonthly + occupationalPensionMonthly;
}
