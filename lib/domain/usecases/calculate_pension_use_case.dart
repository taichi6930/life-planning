import '../services/pension_calculation_service.dart';
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
  ///
  /// Returns [PensionResult]
  static PensionResult execute({
    required int paymentMonths,
    required int desiredPensionStartAge,
    int occupationalPaymentMonths = 0,
    double? monthlySalary,
    double? bonus,
  }) {
    final nationalInput = NationalPensionInput(
      fullContribution: paymentMonths,
      hasPaymentSuspension: false,
      desiredPensionStartAge: desiredPensionStartAge,
    );

    if (occupationalPaymentMonths > 0 &&
        monthlySalary != null &&
        bonus != null) {
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
