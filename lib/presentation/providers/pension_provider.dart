import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/pension_calculation_service.dart';
import '../../domain/values/national_pension_input.dart';
import '../../domain/values/pension_result.dart';

/// 年金計算フォームの状態管理
/// 
/// 入力値（年齢、納付月数）と計算結果を管理する StateNotifier
class PensionFormState {
  final int? currentAge;
  final int? paymentMonths;
  final bool isLoading;
  final PensionResult? result;
  final String? error;

  const PensionFormState({
    this.currentAge,
    this.paymentMonths,
    this.isLoading = false,
    this.result,
    this.error,
  });

  /// 状態をコピーして新しいインスタンスを作成
  PensionFormState copyWith({
    int? currentAge,
    int? paymentMonths,
    bool? isLoading,
    PensionResult? result,
    String? error,
  }) {
    return PensionFormState(
      currentAge: currentAge ?? this.currentAge,
      paymentMonths: paymentMonths ?? this.paymentMonths,
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

  /// 年金計算を実行
  Future<void> calculatePension() async {
    if (state.currentAge == null || state.paymentMonths == null) {
      state = state.copyWith(error: 'すべてのフィールドを入力してください');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // NationalPensionInput を作成
      final input = NationalPensionInput(
        fullContribution: state.paymentMonths!,
        hasPaymentSuspension: false,
        desiredPensionStartAge: 65,
      );

      // 計算を実行
      final result = PensionCalculationService.calculateNationalPension(input);

      state = state.copyWith(
        result: result,
        isLoading: false,
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
