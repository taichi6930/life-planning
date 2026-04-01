import '../../data/pension_local_storage.dart';

/// フォーム入力値をlocalStorageに保存するユースケース
///
/// data層（PensionStorage）への保存処理をapplication層で仲介する。
/// presentation層はこのユースケースを経由してdata層にアクセスする。
class SavePensionFormUseCase {
  static Future<void> execute({
    int? currentAge,
    int? paymentMonths,
    int? occupationalPaymentMonths,
    int? monthlySalary,
    int? bonus,
    int? desiredPensionStartAge,
    int? idecoMonthlyContribution,
    double? idecoAnnualReturnRate,
    int? idecoCurrentBalance,
    int? monthlyLivingExpenses,
    int? targetAge,
    int? investmentTrustMonthlyContribution,
    int? investmentTrustCurrentAge,
    double? investmentTrustAnnualReturnRate,
    int? investmentTrustWithdrawalStartAge,
    int? investmentTrustCurrentBalance,
  }) {
    return PensionStorage.savePensionFormData(
      currentAge: currentAge,
      paymentMonths: paymentMonths,
      occupationalPaymentMonths: occupationalPaymentMonths,
      monthlySalary: monthlySalary,
      bonus: bonus,
      desiredPensionStartAge: desiredPensionStartAge,
      idecoMonthlyContribution: idecoMonthlyContribution,
      idecoAnnualReturnRate: idecoAnnualReturnRate,
      idecoCurrentBalance: idecoCurrentBalance,
      monthlyLivingExpenses: monthlyLivingExpenses,
      targetAge: targetAge,
      investmentTrustMonthlyContribution: investmentTrustMonthlyContribution,
      investmentTrustCurrentAge: investmentTrustCurrentAge,
      investmentTrustAnnualReturnRate: investmentTrustAnnualReturnRate,
      investmentTrustWithdrawalStartAge: investmentTrustWithdrawalStartAge,
      investmentTrustCurrentBalance: investmentTrustCurrentBalance,
    );
  }
}
