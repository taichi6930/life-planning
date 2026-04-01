import 'dart:math' as math;

import '../../domain/values/pension_result.dart';
import '../dtos/pension_by_age_data.dart';

/// グラフ用年齢別年金データを構築するユースケース
///
/// [PensionResult]（ドメイン計算結果）を受け取り、
/// 指定開始年齢から100歳までの各年齢の年金額を [PensionByAgeData] リストとして返す。
///
/// 2段階モデル（iDeCo・投資信託ともに同様のロジック）:
///   【Phase 1】各引出開始年齢 〜 公的年金受給開始前
///     - iDeCo/投資信託で生活費を全額賄う
///     - 受給開始年齢から逆方向に埋める（隙間は若い方に出る）
///     - 基礎年金・厚生年金は0円
///   【Phase 2】公的年金受給開始 〜 100歳
///     - 基礎年金・厚生年金を表示
///     - iDeCo/投資信託は不足分補填額を100歳から逆方向に埋める
///
/// テスト: test/application/usecases/build_pension_chart_use_case_test.dart
class BuildPensionChartUseCase {
  /// グラフデータを構築する
  ///
  /// [result]                          ドメイン計算結果
  /// [publicPensionStartAge]           公的年金の受給開始年齢（60〜75）
  /// [investmentTrustWithdrawalStartAge] 投資信託の引出開始年齢（30〜75、デフォルト60）
  /// [idecoCurrentAge]                  iDeCo現在年齢（iDeCoの拠出期間計算用）
  /// [idecoMonthlyContribution]         iDeCo月額拠出額（円）
  /// [idecoAnnualReturnRate]            iDeCo年利回り（％）
  /// [idecoCurrentBalance]              iDeCo現在残高（円）
  /// [investmentTrustMonthlyContribution] 投資信託月額拠出額（円）
  /// [investmentTrustCurrentAge]        投資信託現在年齢
  /// [investmentTrustAnnualReturnRate]  投資信託年利回り（％）
  /// [investmentTrustCurrentBalance]    投資信託現在残高（円）
  ///
  /// Returns [List<PensionByAgeData>] startAgeから100歳までの年齢別年金データ
  static List<PensionByAgeData> execute({
    required PensionResult result,
    required int publicPensionStartAge,
    int investmentTrustWithdrawalStartAge = 60,
    int idecoCurrentAge = 30,
    int idecoMonthlyContribution = 0,
    double idecoAnnualReturnRate = 3.0,
    int idecoCurrentBalance = 0,
    int investmentTrustMonthlyContribution = 0,
    int investmentTrustCurrentAge = 30,
    double investmentTrustAnnualReturnRate = 5.0,
    int investmentTrustCurrentBalance = 0,
  }) {
    final chartData = <PensionByAgeData>[];

    // 投資信託がある場合、引出開始年齢が60歳未満ならそこからグラフ開始
    final bool hasInvestmentTrust = result.investmentTrustFutureValue > 0;
    final startAge = hasInvestmentTrust && investmentTrustWithdrawalStartAge < 60
        ? investmentTrustWithdrawalStartAge
        : 60;

    // === Phase 1: カバー年数を前方シミュレーションで計算し、逆方向に配置 ===
    int idecoPhase1Count = 0;
    int itPhase1Count = 0;
    for (int a = startAge; a < publicPensionStartAge; a++) {
      final bool iExh =
          result.idecoExhaustionAge > 0 && a >= result.idecoExhaustionAge;
      final bool itExh =
          result.investmentTrustExhaustionAge > 0 &&
          a >= result.investmentTrustExhaustionAge;
      if (!iExh && result.idecoFutureValue > 0 && a >= 60) {
        idecoPhase1Count++;
      } else if (!itExh && hasInvestmentTrust && a >= investmentTrustWithdrawalStartAge) {
        itPhase1Count++;
      }
    }
    // iDeCo: 受給開始年齢から逆方向
    final int idecoP1Start = publicPensionStartAge - idecoPhase1Count;
    // IT: iDeCoの手前から逆方向
    final int itP1Start = idecoP1Start - itPhase1Count;

    // === Phase 2: 100歳から逆方向にカバー範囲を計算 ===
    const int maxAge = 100;
    final int phase2Length = maxAge - publicPensionStartAge;

    // iDeCo Phase 2 カバー年数
    double idecoPhase2Years = 0;
    if (result.idecoFutureValue > 0 && result.idecoMonthly > 0) {
      final ex = result.idecoExhaustionAge;
      if (ex == double.infinity || ex == 0) {
        // 枯渇しない → Phase 2全期間カバー
        idecoPhase2Years = phase2Length.toDouble();
      } else if (ex > publicPensionStartAge) {
        idecoPhase2Years = math.min(
          ex - publicPensionStartAge,
          phase2Length.toDouble(),
        );
      }
    }
    // iDeCo カバー開始年齢（100歳から逆算）
    final double idecoCoverageStart = maxAge - idecoPhase2Years;

    // 投資信託 Phase 2 カバー年数
    double itPhase2Years = 0;
    if (hasInvestmentTrust && result.investmentTrustMonthly > 0) {
      if (result.idecoMonthly > 0 &&
          result.idecoExhaustionAge > 0 &&
          result.idecoExhaustionAge != double.infinity) {
        // 複合モデル: iDeCo枯渇後にITがカバー
        final ex = result.investmentTrustExhaustionAge;
        if (ex == double.infinity || ex == 0) {
          itPhase2Years = math.max(
            idecoCoverageStart - publicPensionStartAge, 0.0);
        } else if (ex > result.idecoExhaustionAge) {
          itPhase2Years = ex - result.idecoExhaustionAge;
        }
      } else {
        // IT単独: Phase 2をカバー
        final ex = result.investmentTrustExhaustionAge;
        if (ex == double.infinity || ex == 0) {
          itPhase2Years = phase2Length.toDouble();
        } else if (ex > publicPensionStartAge) {
          itPhase2Years = math.min(
            ex - publicPensionStartAge,
            phase2Length.toDouble(),
          );
        }
      }
    }
    // IT カバー開始年齢（iDeCoの手前から逆算）
    final double itCoverageStart = idecoCoverageStart - itPhase2Years;

    for (int age = startAge; age <= maxAge; age++) {
      double basicPension = 0.0;
      double occupationalPension = 0.0;
      double idecoPension = 0.0;
      double investmentTrustPension = 0.0;

      if (age < publicPensionStartAge) {
        // Phase 1: 受給開始年齢から逆方向に埋める
        // iDeCo: idecoP1Start 〜 publicPensionStartAge
        if (age >= idecoP1Start && result.idecoFutureValue > 0) {
          idecoPension = result.monthlyLivingExpenses > 0
              ? result.monthlyLivingExpenses
              : 0.0;
        } else if (age >= itP1Start && age < idecoP1Start &&
            hasInvestmentTrust) {
          // 投資信託: iDeCoの手前を埋める
          investmentTrustPension = result.monthlyLivingExpenses > 0
              ? result.monthlyLivingExpenses
              : 0.0;
        }
      } else {
        // Phase 2: 100歳から逆方向に埋める
        basicPension = result.basicPensionMonthly;
        occupationalPension = result.occupationalPensionMonthly;

        // iDeCo: idecoCoverageStart 〜 100歳
        if (age >= idecoCoverageStart && result.idecoMonthly > 0) {
          idecoPension = result.idecoMonthly;
        }
        // 投資信託: itCoverageStart 〜 idecoCoverageStart（iDeCoと重複しない）
        if (age >= itCoverageStart && idecoPension == 0.0 &&
            result.investmentTrustMonthly > 0) {
          investmentTrustPension = result.investmentTrustMonthly;
        }
      }

      // iDeCoの残高と運用益を計算
      final (idecoBalance, idecoGain) = _calculateBalanceAndGain(
        age: age,
        currentAge: idecoCurrentAge,
        currentBalance: idecoCurrentBalance.toDouble(),
        monthlyContribution: idecoMonthlyContribution.toDouble(),
        annualReturnRate: idecoAnnualReturnRate,
        withdrawalStartAge: 60,
        monthlyWithdrawal: idecoPension * 12, // 年間引出額
      );

      // 投資信託の残高と運用益を計算
      final (itBalance, itGain) = _calculateBalanceAndGain(
        age: age,
        currentAge: investmentTrustCurrentAge,
        currentBalance: investmentTrustCurrentBalance.toDouble(),
        monthlyContribution: investmentTrustMonthlyContribution.toDouble(),
        annualReturnRate: investmentTrustAnnualReturnRate,
        withdrawalStartAge: investmentTrustWithdrawalStartAge,
        monthlyWithdrawal: investmentTrustPension * 12, // 年間引出額
      );

      chartData.add(
        PensionByAgeData(
          age: age,
          basicPensionMonthly: basicPension,
          occupationalPensionMonthly: occupationalPension,
          idecoMonthly: idecoPension,
          investmentTrustMonthly: investmentTrustPension,
          monthlyLivingExpenses: result.monthlyLivingExpenses,
          idecoBalance: idecoBalance,
          investmentTrustBalance: itBalance,
          idecoGain: idecoGain,
          investmentTrustGain: itGain,
        ),
      );
    }

    return chartData;
  }

  static (double balance, double gain) _calculateBalanceAndGain({
    required int age,
    required int currentAge,
    required double currentBalance,
    required double monthlyContribution,
    required double annualReturnRate,
    required int withdrawalStartAge,
    required double monthlyWithdrawal,
  }) {
    if (age < currentAge) {
      return (0.0, 0.0);
    }

    double balance = currentBalance;
    final monthlyReturnRate = (math.pow(1 + annualReturnRate / 100, 1.0 / 12) as double) - 1;

    // 現在年齢から指定年齢まで毎年シミュレート
    for (int y = currentAge; y < age; y++) {
      // その年の開始時の残高
      final yearStartBalance = balance;

      // 年間拠出額（引出開始年齢前のみ）
      final annualContribution = y < withdrawalStartAge
          ? monthlyContribution * 12
          : 0.0;

      // 運用益を計算
      final balanceAfterContribution = yearStartBalance + annualContribution;
      final newBalance =
          balanceAfterContribution * (math.pow(1 + monthlyReturnRate, 12) as double);

      // 年間引出
      final annualWithdrawal = y >= withdrawalStartAge ? monthlyWithdrawal : 0.0;
      balance = (newBalance - annualWithdrawal).clamp(0.0, double.infinity);
    }

    // 当該年の運用益を計算（前年との差分 - 拠出額 + 引出額）
    final yearStartBalance = balance;
    final annualContribution =
        age < withdrawalStartAge ? monthlyContribution * 12 : 0.0;
    final balanceAfterContribution = yearStartBalance + annualContribution;
    final newBalance =
        balanceAfterContribution * (math.pow(1 + monthlyReturnRate, 12) as double);
    final annualWithdrawal = age >= withdrawalStartAge ? monthlyWithdrawal : 0.0;
    final finalBalance = (newBalance - annualWithdrawal).clamp(0.0, double.infinity);
    final gain = finalBalance - yearStartBalance - annualContribution + annualWithdrawal;

    return (finalBalance, gain);
  }
}
