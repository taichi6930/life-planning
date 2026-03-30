import '../../domain/values/pension_result.dart';
import '../dtos/pension_by_age_data.dart';

/// グラフ用年齢別年金データを構築するユースケース
///
/// [PensionResult]（ドメイン計算結果）を受け取り、
/// 60歳から100歳までの各年齢の年金額を [PensionByAgeData] リストとして返す。
///
/// 2段階iDeCoモデルを反映:
///   【Phase 1】iDeCo受給開始(60歳) 〜 公的年金受給開始前
///     - iDeCoのみで生活費を全額賄う（idecoMonthly = monthlyLivingExpenses）
///     - 基礎年金・厚生年金は0円
///   【Phase 2】公的年金受給開始 〜
///     - 基礎年金・厚生年金を表示
///     - iDeCoは不足分補填額（result.idecoMonthly）を枯渇年齢まで表示
///
/// テスト: test/application/usecases/build_pension_chart_use_case_test.dart
class BuildPensionChartUseCase {
  /// グラフデータを構築する
  ///
  /// [result]               ドメイン計算結果
  /// [publicPensionStartAge] 公的年金の受給開始年齢（60〜75）
  ///
  /// Returns [List<PensionByAgeData>] 60歳から100歳までの年齢別年金データ（計41件）
  static List<PensionByAgeData> execute({
    required PensionResult result,
    required int publicPensionStartAge,
  }) {
    final chartData = <PensionByAgeData>[];

    const startAge = 60;
    for (int age = startAge; age <= 100; age++) {
      double basicPension = 0.0;
      double occupationalPension = 0.0;
      double idecoPension = 0.0;

      final bool idecoExhausted =
          result.idecoExhaustionAge > 0 && age >= result.idecoExhaustionAge;

      if (age < publicPensionStartAge) {
        // Phase 1: 公的年金受給開始前 → iDeCoのみで生活費を全額賄う
        if (!idecoExhausted && result.idecoFutureValue > 0) {
          idecoPension = result.monthlyLivingExpenses > 0
              ? result.monthlyLivingExpenses
              : 0.0;
        }
      } else {
        // Phase 2: 公的年金受給開始以降
        basicPension = result.basicPensionMonthly;
        occupationalPension = result.occupationalPensionMonthly;
        // iDeCoは不足分補填額を枯渇年齢まで表示
        if (!idecoExhausted && result.idecoMonthly > 0) {
          idecoPension = result.idecoMonthly;
        }
      }

      chartData.add(
        PensionByAgeData(
          age: age,
          basicPensionMonthly: basicPension,
          occupationalPensionMonthly: occupationalPension,
          idecoMonthly: idecoPension,
          monthlyLivingExpenses: result.monthlyLivingExpenses,
        ),
      );
    }

    return chartData;
  }
}
