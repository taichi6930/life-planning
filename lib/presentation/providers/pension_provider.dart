import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/dtos/pension_by_age_data.dart';
import '../../data/pension_local_storage.dart';
import '../../domain/usecases/calculate_pension_use_case.dart';
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
  return state.paymentMonths! / 480.0;
});

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
  const startAge = 60;
  final startAgeOfPension = formState.desiredPensionStartAge;
  
  for (int age = startAge; age <= 100; age++) {
    double basicPension = 0.0;
    double occupationalPension = 0.0;
    
    // 受給開始年齢以降のみ年金を表示
    if (age >= startAgeOfPension) {
      basicPension = result.basicPensionMonthly;
      occupationalPension = result.occupationalPensionMonthly;
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
