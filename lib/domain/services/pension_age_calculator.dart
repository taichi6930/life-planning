import 'dart:math' as math;

/// 年齢別の資産残高をシミュレーションするドメインサービス
///
/// 月単位で計算し、1年分（12ヶ月）の結果を返す。
///
/// 計算モデル（月単位）:
///   60歳前:
///     1. 残高 + 拠出額 B
///     2. 残高 × (1 + 月利)
///   60歳以降:
///     1. 残高 + 拠出額 B
///     2. 残高 - 必要額 D（残高を超える場合は残高分のみ引出）
///     3. 残高 × (1 + 月利)
///
/// テスト: test/domain/services/pension_age_calculator_simulation_test.dart
class PensionAgeCalculator {
  /// 1年分（12ヶ月）の月次シミュレーション
  ///
  /// 毎月の計算順序:
  ///   1. 残高 + 拠出額
  ///   2. 残高 - 引出額（残高を超える場合は残高分のみ引出）
  ///   3. 残高 × (1 + 月利)
  ///
  /// [currentBalance]          年初残高（円）
  /// [monthlyContribution]     月額拠出（円）
  /// [annualReturnRate]        年利回り（%）例: 3.0
  /// [monthlyWithdrawal]       月額引出（円）（生活費の不足分など）
  ///
  /// Returns ({double balance, double gain, double totalWithdrawal})
  ///   - balance: 年末残高（円）
  ///   - gain: 年間運用益（円）
  ///   - totalWithdrawal: 年間実際引出額（円）
  static ({double balance, double gain, double totalWithdrawal}) simulateYear({
    required double currentBalance,
    required double monthlyContribution,
    required double annualReturnRate,
    required double monthlyWithdrawal,
  }) {
    final monthlyRate =
        (math.pow(1 + annualReturnRate / 100, 1.0 / 12) as double) - 1;
    double balance = currentBalance;
    final yearStartBalance = balance;
    double totalContribution = 0;
    double totalActualWithdrawal = 0;

    for (int month = 0; month < 12; month++) {
      // 1. 拠出
      balance += monthlyContribution;
      totalContribution += monthlyContribution;

      // 2. 引出（残高を超えない）
      final actualWithdrawal =
          math.min(math.max(balance, 0.0), monthlyWithdrawal);
      balance -= actualWithdrawal;
      totalActualWithdrawal += actualWithdrawal;

      // 3. 運用（利回り）
      balance *= (1 + monthlyRate);
    }

    // 浮動小数点誤差で微小マイナスになる場合のケア
    balance = math.max(0.0, balance);

    // 運用益 = 年末残高 - 年初残高 - 年間拠出 + 年間引出
    final gain =
        balance - yearStartBalance - totalContribution + totalActualWithdrawal;

    return (
      balance: balance,
      gain: gain,
      totalWithdrawal: totalActualWithdrawal,
    );
  }
}
