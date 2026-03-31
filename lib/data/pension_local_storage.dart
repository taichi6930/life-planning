import 'package:shared_preferences/shared_preferences.dart';

import '../application/dtos/pension_form_data.dart';

/// 年金計算フォームのデータを localStorage に永続化するクラス
///
/// 責務: SharedPreferences を使ったフォーム入力値の読み書き（I/Oのみ）。
/// ビジネスロジック・UI 状態管理・DTOの定義は行わない。
///
/// 配置理由: localStorage はインフラストラクチャ関心事のため data/ 層に配置。
/// 返却する [PensionFormDataMap] は application/dtos/ で定義。
/// presentation 層から直接操作せず、providers 経由で利用する。
class PensionStorage {
  static const String _keyCurrentAge = 'pension_current_age';
  static const String _keyPaymentMonths = 'pension_payment_months';
  static const String _keyOccupationalPaymentMonths =
      'pension_occupational_payment_months';
  static const String _keyMonthlySalary = 'pension_monthly_salary';
  static const String _keyBonus = 'pension_bonus';
  static const String _keyDesiredPensionStartAge =
      'pension_desired_pension_start_age';
  static const String _keyIdecoMonthlyContribution =
      'pension_ideco_monthly_contribution';
  static const String _keyIdecoAnnualReturnRate =
      'pension_ideco_annual_return_rate';
  static const String _keyIdecoCurrentBalance =
      'pension_ideco_current_balance';
  static const String _keyMonthlyLivingExpenses =
      'pension_monthly_living_expenses';
  static const String _keyTargetAge = 'pension_target_age';

  /// フォーム入力値を localStorage に保存
  static Future<void> savePensionFormData({
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
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (currentAge != null) {
      await prefs.setInt(_keyCurrentAge, currentAge);
    }
    if (paymentMonths != null) {
      await prefs.setInt(_keyPaymentMonths, paymentMonths);
    }
    if (occupationalPaymentMonths != null) {
      await prefs.setInt(
          _keyOccupationalPaymentMonths, occupationalPaymentMonths);
    }
    if (monthlySalary != null) {
      await prefs.setInt(_keyMonthlySalary, monthlySalary);
    }
    if (bonus != null) {
      await prefs.setInt(_keyBonus, bonus);
    }
    if (desiredPensionStartAge != null) {
      await prefs.setInt(_keyDesiredPensionStartAge, desiredPensionStartAge);
    }
    if (idecoMonthlyContribution != null) {
      await prefs.setInt(_keyIdecoMonthlyContribution, idecoMonthlyContribution);
    }
    if (idecoAnnualReturnRate != null) {
      await prefs.setDouble(_keyIdecoAnnualReturnRate, idecoAnnualReturnRate);
    }
    if (idecoCurrentBalance != null) {
      await prefs.setInt(_keyIdecoCurrentBalance, idecoCurrentBalance);
    }
    if (monthlyLivingExpenses != null) {
      await prefs.setInt(_keyMonthlyLivingExpenses, monthlyLivingExpenses);
    }
    if (targetAge != null) {
      await prefs.setInt(_keyTargetAge, targetAge);
    }
  }

  /// localStorage からフォーム入力値を取得
  static Future<PensionFormDataMap> loadPensionFormData() async {
    final prefs = await SharedPreferences.getInstance();

    return PensionFormDataMap(
      currentAge: prefs.getInt(_keyCurrentAge),
      paymentMonths: prefs.getInt(_keyPaymentMonths),
      occupationalPaymentMonths:
          prefs.getInt(_keyOccupationalPaymentMonths),
      monthlySalary: prefs.getInt(_keyMonthlySalary),
      bonus: prefs.getInt(_keyBonus),
      desiredPensionStartAge:
          prefs.getInt(_keyDesiredPensionStartAge) ?? 65,
      idecoMonthlyContribution: prefs.getInt(_keyIdecoMonthlyContribution) ?? 0,
      idecoAnnualReturnRate:
          prefs.getDouble(_keyIdecoAnnualReturnRate) ?? 3.0,
      idecoCurrentBalance:
          prefs.getInt(_keyIdecoCurrentBalance) ?? 0,
      monthlyLivingExpenses:
          prefs.getInt(_keyMonthlyLivingExpenses) ?? 0,
      targetAge:
          prefs.getInt(_keyTargetAge) ?? 90,
    );
  }

  /// localStorage をクリア
  static Future<void> clearPensionFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentAge);
    await prefs.remove(_keyPaymentMonths);
    await prefs.remove(_keyOccupationalPaymentMonths);
    await prefs.remove(_keyMonthlySalary);
    await prefs.remove(_keyBonus);
    await prefs.remove(_keyDesiredPensionStartAge);
    await prefs.remove(_keyIdecoMonthlyContribution);
    await prefs.remove(_keyIdecoAnnualReturnRate);
    await prefs.remove(_keyIdecoCurrentBalance);
    await prefs.remove(_keyMonthlyLivingExpenses);
    await prefs.remove(_keyTargetAge);
  }
}
