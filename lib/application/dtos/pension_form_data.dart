/// localStorage から読み込んだフォームデータのスナップショット DTO
///
/// [PensionStorage.loadPensionFormData] の戻り値として使用する。
/// data 層（I/O）と presentation 層の間を仲介するアプリケーション層の DTO。
///
/// 配置理由:
///   フォームデータのスナップショットはアプリケーション層の関心事。
///   data 層は I/O（SharedPreferences の読み書き）のみ担い、
///   その結果を表すデータ構造はこの application/dtos/ に配置する。
///
/// 参照元:
///   - [data/pension_local_storage.dart] の [PensionStorage.loadPensionFormData]
///   - [presentation/templates/pension_form_template.dart]
class PensionFormDataMap {
  final int? currentAge;
  final int? paymentMonths;
  final int? occupationalPaymentMonths;
  final int? monthlySalary;
  final int? bonus;
  final int desiredPensionStartAge;
  final int idecoMonthlyContribution;
  final double idecoAnnualReturnRate;
  final int idecoCurrentBalance;
  final int monthlyLivingExpenses;
  final int targetAge;
  final int investmentTrustMonthlyContribution;
  final int investmentTrustCurrentAge;
  final double investmentTrustAnnualReturnRate;
  final int investmentTrustWithdrawalStartAge;
  final int investmentTrustCurrentBalance;

  PensionFormDataMap({
    this.currentAge,
    this.paymentMonths,
    this.occupationalPaymentMonths,
    this.monthlySalary,
    this.bonus,
    this.desiredPensionStartAge = 65,
    this.idecoMonthlyContribution = 0,
    this.idecoAnnualReturnRate = 3.0,
    this.idecoCurrentBalance = 0,
    this.monthlyLivingExpenses = 0,
    this.targetAge = 100,
    this.investmentTrustMonthlyContribution = 0,
    this.investmentTrustCurrentAge = 30,
    this.investmentTrustAnnualReturnRate = 5.0,
    this.investmentTrustWithdrawalStartAge = 60,
    this.investmentTrustCurrentBalance = 0,
  });
}
