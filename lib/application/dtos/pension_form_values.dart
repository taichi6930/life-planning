/// 年金計算フォームの入力値をグループ化するDTO
///
/// PensionForm の onSubmit / onFieldChanged コールバックで使用。
/// 16個の位置引数を1つのオブジェクトにまとめ、可読性を向上させる。
class PensionFormValues {
  final int currentAge;
  final int paymentMonths;
  final int occupationalPaymentMonths;
  final int monthlySalary;
  final int bonus;
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

  const PensionFormValues({
    required this.currentAge,
    required this.paymentMonths,
    required this.occupationalPaymentMonths,
    required this.monthlySalary,
    required this.bonus,
    required this.desiredPensionStartAge,
    required this.idecoMonthlyContribution,
    required this.idecoAnnualReturnRate,
    required this.idecoCurrentBalance,
    required this.monthlyLivingExpenses,
    required this.targetAge,
    required this.investmentTrustMonthlyContribution,
    required this.investmentTrustCurrentAge,
    required this.investmentTrustAnnualReturnRate,
    required this.investmentTrustWithdrawalStartAge,
    required this.investmentTrustCurrentBalance,
  });
}
