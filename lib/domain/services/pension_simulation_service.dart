import 'package:life_planning/application/dtos/pension_by_age_data.dart';
import 'package:life_planning/domain/values/pension_result.dart';

import 'pension_age_calculator.dart';

/// 現在年齢～100歳までの年金シミュレーションを行うドメインサービス
///
/// 月次シミュレーション駆動モデル：
///   - 事前積立（現在年齢→表示開始年齢）: 拠出のみ、引出なし
///   - メインループ（表示開始年齢→100歳）:
///     - 60歳以降: D = max(0, 生活費 - 基礎年金 - 厚生年金) を計算
///     - iDeCoで不足分を優先カバー
///     - 投資信託でiDeCoでカバーできない分を補填
///     - 残高0なら自動的に引出0（シミュレーション側で処理）
///
/// 使用例:
/// ```dart
/// final chart = PensionSimulationService.simulateFromCurrentAgeToMaxAge(
///   result: pensionResult,
///   publicPensionStartAge: 65,
///   idecoCurrentAge: 50,
///   idecoCurrentBalance: 5000000,
///   idecoMonthlyContribution: 23000,
///   idecoAnnualReturnRate: 3.0,
///   investmentTrustCurrentAge: 50,
///   investmentTrustCurrentBalance: 3000000,
///   investmentTrustMonthlyContribution: 50000,
///   investmentTrustAnnualReturnRate: 5.0,
///   investmentTrustWithdrawalStartAge: 50,
/// );
/// ```
class PensionSimulationService {
  static const int maxAge = 100;

  /// 現在年齢から100歳までのシミュレーションを実行し、PensionByAgeData配列を返す
  static List<PensionByAgeData> simulateFromCurrentAgeToMaxAge({
    required PensionResult result,
    required int publicPensionStartAge,
    required int idecoCurrentAge,
    required double idecoCurrentBalance,
    required int idecoMonthlyContribution,
    required double idecoAnnualReturnRate,
    required int investmentTrustCurrentAge,
    required double investmentTrustCurrentBalance,
    required int investmentTrustMonthlyContribution,
    required double investmentTrustAnnualReturnRate,
    required int investmentTrustWithdrawalStartAge,
  }) {
    final chartData = <PensionByAgeData>[];

    // 投資信託がある場合、引出開始年齢が60歳未満ならそこからグラフ開始
    final bool hasInvestmentTrust = result.investmentTrustFutureValue > 0;
    final startAge = hasInvestmentTrust && investmentTrustWithdrawalStartAge < 60
        ? investmentTrustWithdrawalStartAge
        : 60;

    // ─── 事前積立: currentAge → startAge（拠出のみ、引出なし）───
    double idecoPrevBalance = idecoCurrentBalance;
    for (int preAge = idecoCurrentAge; preAge < startAge; preAge++) {
      final isContribAge = preAge <= 65;
      final preResult = PensionAgeCalculator.simulateYear(
        currentBalance: idecoPrevBalance,
        monthlyContribution: isContribAge ? idecoMonthlyContribution.toDouble() : 0.0,
        annualReturnRate: idecoAnnualReturnRate,
        monthlyWithdrawal: 0.0,
      );
      idecoPrevBalance = preResult.balance;
    }

    double itPrevBalance = investmentTrustCurrentBalance;
    for (int preAge = investmentTrustCurrentAge; preAge < startAge; preAge++) {
      final preResult = PensionAgeCalculator.simulateYear(
        currentBalance: itPrevBalance,
        monthlyContribution: investmentTrustMonthlyContribution.toDouble(),
        annualReturnRate: investmentTrustAnnualReturnRate,
        monthlyWithdrawal: 0.0,
      );
      itPrevBalance = preResult.balance;
    }

    // ─── メインループ: startAge → 100歳 ───
    for (int age = startAge; age <= maxAge; age++) {
      // 基礎年金・厚生年金（公的年金受給開始年齢以降のみ）
      final basicPension = age >= publicPensionStartAge
          ? result.basicPensionMonthly
          : 0.0;
      final occupationalPension = age >= publicPensionStartAge
          ? result.occupationalPensionMonthly
          : 0.0;

      // 生活費の不足分 D = max(0, 生活費 - 基礎年金 - 厚生年金)
      double shortfall = 0.0;
      if (result.monthlyLivingExpenses > 0) {
        if (age >= 60) {
          // 60歳以降: 公的年金を差し引いた不足分
          shortfall = (result.monthlyLivingExpenses - basicPension - occupationalPension)
              .clamp(0.0, double.infinity);
        } else if (age >= investmentTrustWithdrawalStartAge && hasInvestmentTrust) {
          // 60歳前でも投資信託の引出開始年齢以降は生活費全額が不足分
          shortfall = result.monthlyLivingExpenses;
        }
      }

      // ─── iDeCo 1年分シミュレーション ───
      final idecoContrib = age <= 65 ? idecoMonthlyContribution.toDouble() : 0.0;
      // iDeCoの引出は60歳以降のみ（60歳前は拠出のみ）
      final idecoDesiredWithdrawal = age >= 60 ? shortfall : 0.0;

      final idecoResult = PensionAgeCalculator.simulateYear(
        currentBalance: idecoPrevBalance,
        monthlyContribution: idecoContrib,
        annualReturnRate: idecoAnnualReturnRate,
        monthlyWithdrawal: idecoDesiredWithdrawal,
      );
      idecoPrevBalance = idecoResult.balance;
      final idecoActualMonthly = idecoResult.totalWithdrawal / 12;

      // ─── 投資信託 1年分シミュレーション ───
      final itContrib = investmentTrustMonthlyContribution.toDouble();
      // 投資信託の引出: iDeCoでカバーできなかった残りの不足分
      double itDesiredWithdrawal = 0.0;
      if (age >= investmentTrustWithdrawalStartAge) {
        if (age >= 60) {
          // 60歳以降: iDeCoでカバーできなかった分
          itDesiredWithdrawal = (shortfall - idecoActualMonthly)
              .clamp(0.0, double.infinity);
        } else {
          // 60歳前: 投資信託が単独で生活費カバー
          itDesiredWithdrawal = shortfall;
        }
      }

      final itResult = PensionAgeCalculator.simulateYear(
        currentBalance: itPrevBalance,
        monthlyContribution: itContrib,
        annualReturnRate: investmentTrustAnnualReturnRate,
        monthlyWithdrawal: itDesiredWithdrawal,
      );
      itPrevBalance = itResult.balance;
      final itActualMonthly = itResult.totalWithdrawal / 12;

      chartData.add(
        PensionByAgeData(
          age: age,
          basicPensionMonthly: basicPension,
          occupationalPensionMonthly: occupationalPension,
          idecoMonthly: idecoActualMonthly,
          investmentTrustMonthly: itActualMonthly,
          monthlyLivingExpenses: result.monthlyLivingExpenses,
          idecoBalance: idecoResult.balance,
          investmentTrustBalance: itResult.balance,
          idecoGain: idecoResult.gain,
          investmentTrustGain: itResult.gain,
        ),
      );
    }

    return chartData;
  }
}
