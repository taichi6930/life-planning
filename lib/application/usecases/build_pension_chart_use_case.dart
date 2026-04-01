import 'package:life_planning/domain/services/pension_simulation_service.dart';

import '../../domain/values/pension_result.dart';
import '../dtos/pension_by_age_data.dart';

/// グラフ用年齢別年金データを構築するユースケース
///
/// ドメイン層の [PensionSimulationService] に計算を委譲し、
/// [PensionResult]（ドメイン計算結果）から現在年齢～100歳までの
/// シミュレーション結果を [PensionByAgeData] リストとして返す。
///
/// 計算モデル（月次シミュレーション駆動）:
///   - 現在年齢から表示開始年齢まで: 拠出のみ（引出なし）
///   - 60歳以降: D = max(0, 生活費 - 基礎年金 - 厚生年金) を引出
///   - iDeCoが不足分を優先カバー、残りを投資信託がカバー
///   - 残高0なら引出0（シミュレーションが自動的に処理）
///
/// テスト: test/application/usecases/build_pension_chart_use_case_test.dart
class BuildPensionChartUseCase {
  /// グラフデータを構築する
  ///
  /// ドメイン層の [PensionSimulationService.simulateFromCurrentAgeToMaxAge]
  /// に入力値を委譲し、現在年齢～100歳までのシミュレーション結果を返す。
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
    return PensionSimulationService.simulateFromCurrentAgeToMaxAge(
      result: result,
      publicPensionStartAge: publicPensionStartAge,
      idecoCurrentAge: idecoCurrentAge,
      idecoCurrentBalance: idecoCurrentBalance.toDouble(),
      idecoMonthlyContribution: idecoMonthlyContribution,
      idecoAnnualReturnRate: idecoAnnualReturnRate,
      investmentTrustCurrentAge: investmentTrustCurrentAge,
      investmentTrustCurrentBalance: investmentTrustCurrentBalance.toDouble(),
      investmentTrustMonthlyContribution: investmentTrustMonthlyContribution,
      investmentTrustAnnualReturnRate: investmentTrustAnnualReturnRate,
      investmentTrustWithdrawalStartAge: investmentTrustWithdrawalStartAge,
    );
  }
}

