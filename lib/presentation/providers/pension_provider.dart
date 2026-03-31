import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/dtos/pension_by_age_data.dart';
import '../../application/usecases/build_pension_chart_use_case.dart';
import '../../data/pension_local_storage.dart';
import '../../domain/usecases/calculate_pension_use_case.dart';
import '../../domain/values/national_pension_input.dart';
import '../../domain/values/pension_result.dart';

/// copyWith で「値を指定しなかった」と「null を指定した」を区別するための定数
class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

/// 年金計算フォームの状態管理
///
/// 入力値（年齢、納付月数、厚生年金月数、給与、賞与、受給開始年齢）と計算結果を管理する StateNotifier
class PensionFormState {
  final int? currentAge;
  final int? paymentMonths;
  final int occupationalPaymentMonths;
  final int? monthlySalary;
  final int? bonus;
  final int desiredPensionStartAge;
  final int idecoMonthlyContribution;
  final double idecoAnnualReturnRate;
  final int idecoCurrentBalance;
  final int monthlyLivingExpenses;
  final int targetAge;
  final bool isLoading;
  final PensionResult? result;
  final String? error;

  const PensionFormState({
    this.currentAge,
    this.paymentMonths,
    this.occupationalPaymentMonths = 0,
    this.monthlySalary,
    this.bonus,
    this.desiredPensionStartAge = 65,
    this.idecoMonthlyContribution = 0,
    this.idecoAnnualReturnRate = 3.0,
    this.idecoCurrentBalance = 0,
    this.monthlyLivingExpenses = 0,
    this.targetAge = 90,
    this.isLoading = false,
    this.result,
    this.error,
  });

  /// 状態をコピーして新しいインスタンスを作成
  PensionFormState copyWith({
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
    bool? isLoading,
    Object? result = _sentinel,
    Object? error = _sentinel,
  }) {
    return PensionFormState(
      currentAge: currentAge ?? this.currentAge,
      paymentMonths: paymentMonths ?? this.paymentMonths,
      occupationalPaymentMonths: occupationalPaymentMonths ?? this.occupationalPaymentMonths,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      bonus: bonus ?? this.bonus,
      desiredPensionStartAge: desiredPensionStartAge ?? this.desiredPensionStartAge,
      idecoMonthlyContribution: idecoMonthlyContribution ?? this.idecoMonthlyContribution,
      idecoAnnualReturnRate: idecoAnnualReturnRate ?? this.idecoAnnualReturnRate,
      idecoCurrentBalance: idecoCurrentBalance ?? this.idecoCurrentBalance,
      monthlyLivingExpenses: monthlyLivingExpenses ?? this.monthlyLivingExpenses,
      targetAge: targetAge ?? this.targetAge,
      isLoading: isLoading ?? this.isLoading,
      result: identical(result, _sentinel) ? this.result : result as PensionResult?,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

/// フォーム状態を管理する StateNotifier
class PensionFormNotifier extends StateNotifier<PensionFormState> {
  PensionFormNotifier() : super(const PensionFormState());

  /// 年齢を更新
  void setCurrentAge(int age) {
    state = state.copyWith(currentAge: age);
  }

  /// 納付月数を更新
  void setPaymentMonths(int months) {
    state = state.copyWith(paymentMonths: months);
  }

  /// 厚生年金加入月数を更新
  void setOccupationalPaymentMonths(int months) {
    state = state.copyWith(occupationalPaymentMonths: months);
  }

  /// 標準報酬月額（給与）を更新
  void setMonthlySalary(int salary) {
    state = state.copyWith(monthlySalary: salary);
  }

  /// 賞与（年額）を更新
  void setBonus(int bonus) {
    state = state.copyWith(bonus: bonus);
  }

  /// 受給開始年齢を更新
  void setDesiredPensionStartAge(int age) {
    state = state.copyWith(desiredPensionStartAge: age);
  }

  /// iDeCo月額拠出額を更新
  void setIdecoMonthlyContribution(int amount) {
    state = state.copyWith(idecoMonthlyContribution: amount);
  }

  /// iDeCo想定年利回りを更新
  void setIdecoAnnualReturnRate(double rate) {
    state = state.copyWith(idecoAnnualReturnRate: rate);
  }

  /// iDeCo現在の投資残高を更新
  void setIdecoCurrentBalance(int amount) {
    state = state.copyWith(idecoCurrentBalance: amount);
  }

  /// 月額生活費を更新
  void setMonthlyLivingExpenses(int amount) {
    state = state.copyWith(monthlyLivingExpenses: amount);
  }

  /// 想定寿命を更新
  void setTargetAge(int age) {
    state = state.copyWith(targetAge: age);
  }

  /// 年金計算を実行
  ///
  /// ビジネスロジックの選択は CalculatePensionUseCase に委譲。
  /// 計算成功後、フォームデータを localStorage に保存する。
  Future<void> calculatePension() async {
    if (state.currentAge == null || state.paymentMonths == null) {
      state = state.copyWith(error: 'すべてのフィールドを入力してください');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = CalculatePensionUseCase.execute(
        paymentMonths: state.paymentMonths!,
        desiredPensionStartAge: state.desiredPensionStartAge,
        occupationalPaymentMonths: state.occupationalPaymentMonths,
        monthlySalary: state.monthlySalary?.toDouble(),
        bonus: state.bonus?.toDouble(),
        idecoMonthlyContribution: state.idecoMonthlyContribution,
        idecoCurrentAge: state.currentAge!,
        idecoAnnualReturnRate: state.idecoAnnualReturnRate,
        idecoCurrentBalance: state.idecoCurrentBalance,
        monthlyLivingExpenses: state.monthlyLivingExpenses,
        targetAge: state.targetAge,
      );

      state = state.copyWith(
        result: result,
        isLoading: false,
      );

      await PensionStorage.savePensionFormData(
        currentAge: state.currentAge,
        paymentMonths: state.paymentMonths,
        occupationalPaymentMonths: state.occupationalPaymentMonths,
        monthlySalary: state.monthlySalary,
        bonus: state.bonus,
        desiredPensionStartAge: state.desiredPensionStartAge,
        idecoMonthlyContribution: state.idecoMonthlyContribution,
        idecoAnnualReturnRate: state.idecoAnnualReturnRate,
        idecoCurrentBalance: state.idecoCurrentBalance,
        monthlyLivingExpenses: state.monthlyLivingExpenses,
        targetAge: state.targetAge,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'エラーが発生しました: $e',
        isLoading: false,
      );
    }
  }

  /// フォームをリセット
  void reset() {
    state = const PensionFormState();
  }
}

/// フォーム状態管理プロバイダ
final pensionFormNotifierProvider =
    StateNotifierProvider<PensionFormNotifier, PensionFormState>(
  (ref) {
    return PensionFormNotifier();
  },
);

/// 計算済みの基礎年金年額を取得するプロバイダ（生値: 円）
///
/// 文字列整形は呼び出し元の Widget で行う。
final nationalPensionYearlyProvider = Provider<double?>((ref) {
  return ref.watch(pensionFormNotifierProvider).result?.basicPensionAnnual;
});

/// 計算済みの基礎年金月額を取得するプロバイダ（生値: 円）
///
/// 文字列整形は呼び出し元の Widget で行う。
final nationalPensionMonthlyProvider = Provider<double?>((ref) {
  return ref.watch(pensionFormNotifierProvider).result?.basicPensionMonthly;
});

/// 納付率を取得するプロバイダ
final contributionRateProvider = Provider<double?>((ref) {
  final state = ref.watch(pensionFormNotifierProvider);
  if (state.paymentMonths == null) return null;
  return state.paymentMonths! / NationalPensionInput.fullContributionMonths;
});

/// 年齢別年金額グラフデータプロバイダ
///
/// 60歳から100歳までの人生における年金額を表示する。
/// グラフデータの組み立てロジックは [BuildPensionChartUseCase] に委譲。
final pensionByAgeChartProvider = Provider<List<PensionByAgeData>?>((ref) {
  final formState = ref.watch(pensionFormNotifierProvider);
  final result = formState.result;

  if (result == null) return null;

  return BuildPensionChartUseCase.execute(
    result: result,
    publicPensionStartAge: formState.desiredPensionStartAge,
  );
});
