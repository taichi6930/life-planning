import 'package:shared_preferences/shared_preferences.dart';

/// 年金計算フォームのデータを localStorage に永続化するクラス
///
/// 責務: SharedPreferences を使ったフォーム入力値の読み書き。
/// ビジネスロジックや UI 状態管理は行わない。
///
/// 配置理由: localStorage はインフラストラクチャ関心事のため data/ 層に配置。
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

  /// フォーム入力値を localStorage に保存
  static Future<void> savePensionFormData({
    int? currentAge,
    int? paymentMonths,
    int? occupationalPaymentMonths,
    int? monthlySalary,
    int? bonus,
    int? desiredPensionStartAge,
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
  }
}

/// localStorage から読み込んだフォームデータのスナップショット
class PensionFormDataMap {
  final int? currentAge;
  final int? paymentMonths;
  final int? occupationalPaymentMonths;
  final int? monthlySalary;
  final int? bonus;
  final int desiredPensionStartAge;

  PensionFormDataMap({
    this.currentAge,
    this.paymentMonths,
    this.occupationalPaymentMonths,
    this.monthlySalary,
    this.bonus,
    this.desiredPensionStartAge = 65,
  });
}
