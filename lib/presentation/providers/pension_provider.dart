import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/pension_calculation_service.dart';
import '../../domain/values/national_pension_input.dart';
import '../../domain/values/occupational_pension_input.dart';
import '../../domain/values/pension_result.dart';
import '../utils/pension_storage.dart';

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
    bool? isLoading,
    PensionResult? result,
    String? error,
  }) {
    return PensionFormState(
      currentAge: currentAge ?? this.currentAge,
      paymentMonths: paymentMonths ?? this.paymentMonths,
      occupationalPaymentMonths: occupationalPaymentMonths ?? this.occupationalPaymentMonths,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      bonus: bonus ?? this.bonus,
      desiredPensionStartAge: desiredPensionStartAge ?? this.desiredPensionStartAge,
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
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

  /// 年金計算を実行
  Future<void> calculatePension() async {
    if (state.currentAge == null || state.paymentMonths == null) {
      state = state.copyWith(error: 'すべてのフィールドを入力してください');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 厨生年金の有無によって計算を分別
      PensionResult result;

      if (state.occupationalPaymentMonths > 0 && state.monthlySalary != null && state.bonus != null) {
        // 厨生年金がある場合、厨生年金を計算
        final occupationalInput = OccupationalPensionInput(
          enrollmentMonths: state.occupationalPaymentMonths,
          averageMonthlyReward: state.monthlySalary!.toDouble(),
          averageBonusReward: state.bonus!.toDouble(),
          desiredPensionStartAge: state.desiredPensionStartAge,
        );
        result = PensionCalculationService.calculateOccupationalPension(occupationalInput);
      } else {
        // 基礎年金のみ計算
        final nationalInput = NationalPensionInput(
          fullContribution: state.paymentMonths!,
          hasPaymentSuspension: false,
          desiredPensionStartAge: state.desiredPensionStartAge,
        );
        result = PensionCalculationService.calculateNationalPension(nationalInput);
      }

      state = state.copyWith(
        result: result,
        isLoading: false,
      );
      
      // localStorageにForm データを保存
      await PensionStorage.savePensionFormData(
        currentAge: state.currentAge,
        paymentMonths: state.paymentMonths,
        occupationalPaymentMonths: state.occupationalPaymentMonths,
        monthlySalary: state.monthlySalary,
        bonus: state.bonus,
        desiredPensionStartAge: state.desiredPensionStartAge,
      );
      
      // 宅StorageにFormデータを保存
      await PensionStorage.savePensionFormData(
        currentAge: state.currentAge,
        paymentMonths: state.paymentMonths,
        occupationalPaymentMonths: state.occupationalPaymentMonths,
        monthlySalary: state.monthlySalary,
        bonus: state.bonus,
        desiredPensionStartAge: state.desiredPensionStartAge,
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

/// 計算済みの年単位の基礎年金を取得するプロバイダ
final nationalPensionYearlyProvider = Provider<String?>((ref) {
  final result = ref.watch(pensionFormNotifierProvider).result;
  if (result == null) return null;
  return '¥${result.basicPensionAnnual.toStringAsFixed(0)}';
});

/// 計算済みの月単位の基礎年金を取得するプロバイダ
final nationalPensionMonthlyProvider = Provider<String?>((ref) {
  final result = ref.watch(pensionFormNotifierProvider).result;
  if (result == null) return null;
  return '¥${result.basicPensionMonthly.toStringAsFixed(0)}';
});

/// 納付率を取得するプロバイダ
final contributionRateProvider = Provider<double?>((ref) {
  final state = ref.watch(pensionFormNotifierProvider);
  if (state.paymentMonths == null) return null;
  return state.paymentMonths! / 480.0;
});

/// グラフ用：年齢別年金額データ
/// 60歳から100歳までの受給開始年齢別に月額年金を計算
class PensionByAgeData {
  final int age;
  final double basicPensionMonthly;
  final double occupationalPensionMonthly;

  PensionByAgeData({
    required this.age,
    required this.basicPensionMonthly,
    required this.occupationalPensionMonthly,
  });

  double get totalMonthly => basicPensionMonthly + occupationalPensionMonthly;
}

/// 年齢別年金額グラフデータプロバイダ
/// 
/// 60歳から100歳までの人生における年金額を表示
/// 受給開始年齢前は0円、受給開始年齢以降は実際の年金額を表示
final pensionByAgeChartProvider = Provider<List<PensionByAgeData>?>((ref) {
  final formState = ref.watch(pensionFormNotifierProvider);
  final result = formState.result;
  
  if (result == null) return null;

  final chartData = <PensionByAgeData>[];
  
  // 60歳から100歳まで表示
  final startAge = 60;
  final startAgeOfPension = formState.desiredPensionStartAge;
  
  for (int age = startAge; age <= 100; age++) {
    double basicPension = 0.0;
    double occupationalPension = 0.0;
    
    // 受給開始年齢以降のみ年金を表示
    if (age >= startAgeOfPension) {
      basicPension = result.basicPensionMonthly;
      occupationalPension = result.occupationalPensionMonthly ?? 0.0;
    }

    chartData.add(
      PensionByAgeData(
        age: age,
        basicPensionMonthly: basicPension,
        occupationalPensionMonthly: occupationalPension,
      ),
    );
  }

  return chartData;
});
