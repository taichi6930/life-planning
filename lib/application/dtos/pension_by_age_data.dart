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

  /// iDeCo月額（円）
  final double idecoMonthly;

  /// 月額生活費（円）
  final double monthlyLivingExpenses;

  const PensionByAgeData({
    required this.age,
    required this.basicPensionMonthly,
    required this.occupationalPensionMonthly,
    this.idecoMonthly = 0.0,
    this.monthlyLivingExpenses = 0.0,
  });

  /// 合計年金月額（基礎年金 + 厚生年金 + iDeCo）
  double get totalMonthly => basicPensionMonthly + occupationalPensionMonthly + idecoMonthly;
}
