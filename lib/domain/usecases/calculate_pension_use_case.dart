import '../services/pension_calculation_service.dart';
import '../values/ideco_input.dart';
import '../values/investment_trust_input.dart';
import '../values/national_pension_input.dart';
import '../values/occupational_pension_input.dart';
import '../values/pension_result.dart';

/// 年金計算ユースケース
///
/// 入力パラメータに基づいて「基礎年金のみ」または「基礎年金＋厚生年金」を
/// 判断し、適切な計算メソッドを呼び出す。
///
/// このクラスが担う責務:
/// - 計算モードの選択（基礎年金のみ / 基礎＋厚生）
/// - ドメインサービスへの入力値オブジェクトの組み立て
/// - PensionCalculationService の呼び出し
///
/// このクラスが担わない責務:
/// - UI状態管理（PensionFormNotifier が担当）
/// - 永続化（PensionLocalStorage が担当）
///
/// テスト: test/domain/usecases/calculate_pension_use_case_test.dart
class CalculatePensionUseCase {
  /// 年金計算を実行する
  ///
  /// [paymentMonths] 国民年金の納付月数（1〜480）
  /// [desiredPensionStartAge] 受給開始年齢（60〜75）
  /// [occupationalPaymentMonths] 厚生年金加入月数（0の場合は基礎年金のみ）
  /// [monthlySalary] 標準報酬月額（厚生年金がある場合のみ有効）
  /// [bonus] 年間賞与（厚生年金がある場合のみ有効）
  /// [idecoMonthlyContribution] iDeCo月額拠出額（0の場合はiDeCo計算なし）
  /// [idecoCurrentAge] iDeCo加入者の現在年齢
  /// [idecoAnnualReturnRate] iDeCo想定年利回り（%）
  /// [idecoCurrentBalance] iDeCo現在の投資残高（円）
  /// [investmentTrustMonthlyContribution] 投資信託月額積立額（0の場合は投資信託計算なし）
  /// [investmentTrustCurrentAge] 投資信託加入者の現在年齢
  /// [investmentTrustAnnualReturnRate] 投資信託想定年利回り（%）
  /// [investmentTrustWithdrawalStartAge] 投資信託引出開始年齢
  /// [investmentTrustCurrentBalance] 投資信託現在の残高（円）
  /// [monthlyLivingExpenses] 月額生活費（円）
  /// [targetAge] 想定寿命（歳）
  ///
  /// Returns [PensionResult]
  static PensionResult execute({
    required int paymentMonths,
    required int desiredPensionStartAge,
    int occupationalPaymentMonths = 0,
    double? monthlySalary,
    double? bonus,
    int idecoMonthlyContribution = 0,
    int idecoCurrentAge = 30,
    double idecoAnnualReturnRate = 3.0,
    int idecoCurrentBalance = 0,
    int investmentTrustMonthlyContribution = 0,
    int investmentTrustCurrentAge = 30,
    double investmentTrustAnnualReturnRate = 5.0,
    int investmentTrustWithdrawalStartAge = InvestmentTrustInput.defaultWithdrawalStartAge,
    int investmentTrustCurrentBalance = 0,
    int monthlyLivingExpenses = 0,
    int targetAge = 100,
  }) {
    final nationalInput = NationalPensionInput(
      fullContribution: paymentMonths,
      hasPaymentSuspension: false,
      desiredPensionStartAge: desiredPensionStartAge,
    );

    final hasOccupational = occupationalPaymentMonths > 0 &&
        monthlySalary != null &&
        bonus != null;

    // iDeCoは60歳（minPensionReceiptAge）から受給開始が前提なので、
    // 現役拠出中（currentAge < 60）または既存残高がある場合にiDeCo計算を実行する
    final hasIdeco = idecoCurrentAge >= IdecoInput.minJoinAge &&
        (idecoMonthlyContribution > 0 &&
                idecoCurrentAge < IdecoInput.minPensionReceiptAge ||
            idecoCurrentBalance > 0);

    // 投資信託は年齢制限なし。拠出額 > 0 または既存残高がある場合に計算を実行する
    final hasInvestmentTrust = investmentTrustCurrentAge >= 0 &&
        (investmentTrustMonthlyContribution > 0 || investmentTrustCurrentBalance > 0);

    if (hasIdeco && hasInvestmentTrust) {
      final idecoInput = IdecoInput(
        monthlyContribution: idecoMonthlyContribution,
        currentAge: idecoCurrentAge,
        expectedAnnualReturnRate: idecoAnnualReturnRate,
        currentBalance: idecoCurrentBalance,
      );

      final itInput = InvestmentTrustInput(
        monthlyContribution: investmentTrustMonthlyContribution > 0
            ? investmentTrustMonthlyContribution
            : 1,
        currentAge: investmentTrustCurrentAge,
        withdrawalStartAge: investmentTrustWithdrawalStartAge,
        contributionEndAge: investmentTrustWithdrawalStartAge,
        expectedAnnualReturnRate: investmentTrustAnnualReturnRate,
        currentBalance: investmentTrustCurrentBalance,
      );

      if (hasOccupational) {
        final occupationalInput = OccupationalPensionInput(
          enrollmentMonths: occupationalPaymentMonths,
          averageMonthlyReward: monthlySalary,
          averageBonusReward: bonus,
          desiredPensionStartAge: desiredPensionStartAge,
        );
        return PensionCalculationService
            .calculateCombinedPensionWithIdecoAndInvestmentTrust(
          nationalInput,
          occupationalInput,
          idecoInput,
          itInput,
          monthlyLivingExpenses: monthlyLivingExpenses.toDouble(),
          targetAge: targetAge,
        );
      } else {
        return PensionCalculationService
            .calculateNationalPensionWithIdecoAndInvestmentTrust(
          nationalInput,
          idecoInput,
          itInput,
          monthlyLivingExpenses: monthlyLivingExpenses.toDouble(),
          targetAge: targetAge,
        );
      }
    }

    if (hasIdeco) {
      final idecoInput = IdecoInput(
        monthlyContribution: idecoMonthlyContribution,
        currentAge: idecoCurrentAge,
        expectedAnnualReturnRate: idecoAnnualReturnRate,
        // pensionStartAge はデフォルト（minPensionReceiptAge = 60歳）を使用
        // 公的年金受給開始年齢（desiredPensionStartAge）とは独立して
        // iDeCoは常に60歳から受給開始とする
        currentBalance: idecoCurrentBalance,
      );

      if (hasOccupational) {
        final occupationalInput = OccupationalPensionInput(
          enrollmentMonths: occupationalPaymentMonths,
          averageMonthlyReward: monthlySalary,
          averageBonusReward: bonus,
          desiredPensionStartAge: desiredPensionStartAge,
        );
        return PensionCalculationService.calculateCombinedPensionWithIdeco(
          nationalInput,
          occupationalInput,
          idecoInput,
          monthlyLivingExpenses: monthlyLivingExpenses.toDouble(),
          targetAge: targetAge,
        );
      } else {
        return PensionCalculationService.calculateNationalPensionWithIdeco(
          nationalInput,
          idecoInput,
          monthlyLivingExpenses: monthlyLivingExpenses.toDouble(),
          targetAge: targetAge,
        );
      }
    }

    if (hasInvestmentTrust) {
      final itInput = InvestmentTrustInput(
        monthlyContribution: investmentTrustMonthlyContribution > 0
            ? investmentTrustMonthlyContribution
            : 1, // 残高のみの場合でもコンストラクタ要件を満たすため最小値
        currentAge: investmentTrustCurrentAge,
        withdrawalStartAge: investmentTrustWithdrawalStartAge,
        contributionEndAge: investmentTrustWithdrawalStartAge,
        expectedAnnualReturnRate: investmentTrustAnnualReturnRate,
        currentBalance: investmentTrustCurrentBalance,
      );

      if (hasOccupational) {
        final occupationalInput = OccupationalPensionInput(
          enrollmentMonths: occupationalPaymentMonths,
          averageMonthlyReward: monthlySalary,
          averageBonusReward: bonus,
          desiredPensionStartAge: desiredPensionStartAge,
        );
        return PensionCalculationService.calculateCombinedPensionWithInvestmentTrust(
          nationalInput,
          occupationalInput,
          itInput,
          monthlyLivingExpenses: monthlyLivingExpenses.toDouble(),
          targetAge: targetAge,
        );
      } else {
        return PensionCalculationService.calculateNationalPensionWithInvestmentTrust(
          nationalInput,
          itInput,
          monthlyLivingExpenses: monthlyLivingExpenses.toDouble(),
          targetAge: targetAge,
        );
      }
    }

    if (hasOccupational) {
      final occupationalInput = OccupationalPensionInput(
        enrollmentMonths: occupationalPaymentMonths,
        averageMonthlyReward: monthlySalary,
        averageBonusReward: bonus,
        desiredPensionStartAge: desiredPensionStartAge,
      );
      return PensionCalculationService.calculateCombinedPension(
        nationalInput,
        occupationalInput,
      );
    } else {
      return PensionCalculationService.calculateNationalPension(nationalInput);
    }
  }
}
