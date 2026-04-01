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

  /// 投資信託月額（円）
  final double investmentTrustMonthly;

  /// 月額生活費（円）
  final double monthlyLivingExpenses;

  /// iDeCo現在残高（円）
  final double idecoBalance;

  /// 投資信託現在残高（円）
  final double investmentTrustBalance;

  /// 当該年のiDeCo運用益（円）
  final double idecoGain;

  /// 当該年の投資信託運用益（円）
  final double investmentTrustGain;

  const PensionByAgeData({
    required this.age,
    required this.basicPensionMonthly,
    required this.occupationalPensionMonthly,
    this.idecoMonthly = 0.0,
    this.investmentTrustMonthly = 0.0,
    this.monthlyLivingExpenses = 0.0,
    this.idecoBalance = 0.0,
    this.investmentTrustBalance = 0.0,
    this.idecoGain = 0.0,
    this.investmentTrustGain = 0.0,
  });

  /// 合計年金月額（基礎年金 + 厚生年金 + iDeCo + 投資信託）
  double get totalMonthly => basicPensionMonthly + occupationalPensionMonthly + idecoMonthly + investmentTrustMonthly;

  /// 基礎年金年額（円）
  double get basicPensionAnnual => basicPensionMonthly * 12;

  /// 厚生年金年額（円）
  double get occupationalPensionAnnual => occupationalPensionMonthly * 12;

  /// iDeCo年額（円）
  double get idecoAnnual => idecoMonthly * 12;

  /// 投資信託年額（円）
  double get investmentTrustAnnual => investmentTrustMonthly * 12;

  /// 合計年金年額（円）
  double get totalAnnual => totalMonthly * 12;

  /// 年間生活費（円）
  double get monthlyLivingExpensesAnnual => monthlyLivingExpenses * 12;
}
