import 'package:shared_preferences/shared_preferences.dart';

/// 年金計算フォームのデータをlocalStorageに管理するユーティリティ
class PensionStorage {
  static const String _keyCurrentAge = 'pension_current_age';
  static const String _keyPaymentMonths = 'pension_payment_months';
  static const String _keyOccupationalPaymentMonths = 'pension_occupational_payment_months';
  static const String _keyMonthlySalary = 'pension_monthly_salary';
  static const String _keyBonus = 'pension_bonus';
  static const String _keyDesiredPensionStartAge = 'pension_desired_pension_start_age';

  /// フォーム入力値をlocalStorageに保存
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
      await prefs.setInt(_keyOccupationalPaymentMonths, occupationalPaymentMonths);
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

  /// localStorageからフォーム入力値を取得
  static Future<PensionFormDataMap> loadPensionFormData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return PensionFormDataMap(
      currentAge: prefs.getInt(_keyCurrentAge),
      paymentMonths: prefs.getInt(_keyPaymentMonths),
      occupationalPaymentMonths: prefs.getInt(_keyOccupationalPaymentMonths),
      monthlySalary: prefs.getInt(_keyMonthlySalary),
      bonus: prefs.getInt(_keyBonus),
      desiredPensionStartAge: prefs.getInt(_keyDesiredPensionStartAge) ?? 65,
    );
  }

  /// localStorageをクリア
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

/// localStorageから読み込んだフォームデータを管理するクラス
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
