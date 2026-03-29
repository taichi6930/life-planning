import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../organisms/pension_form.dart';
import '../organisms/pension_result_display.dart';
import '../providers/pension_provider.dart';
import '../utils/pension_storage.dart';

/// 年金計算ページのテンプレート
/// 
/// フォーム入力と結果表示を組み合わせたレイアウト
class PensionFormTemplate extends ConsumerStatefulWidget {
  final String title;

  const PensionFormTemplate({
    super.key,
    this.title = '年金計算',
  });

  @override
  ConsumerState<PensionFormTemplate> createState() => _PensionFormTemplateState();
}

class _PensionFormTemplateState extends ConsumerState<PensionFormTemplate> {
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// localStorageから保存されたデータを読み込んで復元
  Future<void> _loadSavedData() async {
    final savedData = await PensionStorage.loadPensionFormData();
    
    if (!mounted) return;
    
    final notifier = ref.read(pensionFormNotifierProvider.notifier);
    
    if (savedData.currentAge != null) {
      notifier.setCurrentAge(savedData.currentAge!);
    }
    if (savedData.paymentMonths != null) {
      notifier.setPaymentMonths(savedData.paymentMonths!);
    }
    if (savedData.occupationalPaymentMonths != null) {
      notifier.setOccupationalPaymentMonths(savedData.occupationalPaymentMonths!);
    }
    if (savedData.monthlySalary != null) {
      notifier.setMonthlySalary(savedData.monthlySalary!);
    }
    if (savedData.bonus != null) {
      notifier.setBonus(savedData.bonus!);
    }
    notifier.setDesiredPensionStartAge(savedData.desiredPensionStartAge);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(pensionFormNotifierProvider);
    final yearlyPension = ref.watch(nationalPensionYearlyProvider);
    final monthlyPension = ref.watch(nationalPensionMonthlyProvider);
    final rate = ref.watch(contributionRateProvider);

    // 画面幅に応じてレイアウトを切り替え（レスポンシブ対応）
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 900;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            elevation: 0,
          ),
          body: isWideScreen
              ? _buildWideLayout(ref, formState, yearlyPension, monthlyPension, rate)
              : _buildNarrowLayout(ref, formState, yearlyPension, monthlyPension, rate),
        );
      },
    );
  }

  /// 広い画面用レイアウト（横並び）
  Widget _buildWideLayout(
    WidgetRef ref,
    PensionFormState formState,
    String? yearlyPension,
    String? monthlyPension,
    double? rate,
  ) {
    return Row(
      children: [
        // 左側：フォーム
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: PensionForm(
              isLoading: formState.isLoading,
              initialAge: formState.currentAge,
              initialPaymentMonths: formState.paymentMonths,
              initialOccupationalPaymentMonths: formState.occupationalPaymentMonths,
              initialMonthlySalary: formState.monthlySalary ?? 0,
              initialBonus: formState.bonus ?? 0,
              initialDesiredPensionStartAge: formState.desiredPensionStartAge,
              onSubmit: (currentAge, paymentMonths, occupationalPaymentMonths, monthlySalary, bonus, desiredPensionStartAge) {
                // Template で計算を管理
                ref.read(pensionFormNotifierProvider.notifier).setCurrentAge(currentAge);
                ref.read(pensionFormNotifierProvider.notifier).setPaymentMonths(paymentMonths);
                ref.read(pensionFormNotifierProvider.notifier).setOccupationalPaymentMonths(occupationalPaymentMonths);
                ref.read(pensionFormNotifierProvider.notifier).setMonthlySalary(monthlySalary);
                ref.read(pensionFormNotifierProvider.notifier).setBonus(bonus);
                ref.read(pensionFormNotifierProvider.notifier).setDesiredPensionStartAge(desiredPensionStartAge);
                ref.read(pensionFormNotifierProvider.notifier).calculatePension();
              },
            ),
          ),
        ),
        // 右側：結果表示
        Expanded(
          child: PensionResultDisplay(
            nationalPensionYearly: yearlyPension,
            nationalPensionMonthly: monthlyPension,
            contributionRate: rate,
            isLoading: formState.isLoading,
          ),
        ),
      ],
    );
  }

  /// 狭い画面用レイアウト（縦並び、タブ）
  Widget _buildNarrowLayout(
    WidgetRef ref,
    PensionFormState formState,
    String? yearlyPension,
    String? monthlyPension,
    double? rate,
  ) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(text: 'フォーム'),
            Tab(text: '結果'),
          ],
        ),
        body: TabBarView(
          children: [
            // フォームタブ
            PensionForm(
              isLoading: formState.isLoading,
              initialAge: formState.currentAge,
              initialPaymentMonths: formState.paymentMonths,
              initialOccupationalPaymentMonths: formState.occupationalPaymentMonths,
              initialMonthlySalary: formState.monthlySalary ?? 0,
              initialBonus: formState.bonus ?? 0,
              initialDesiredPensionStartAge: formState.desiredPensionStartAge,
              onSubmit: (currentAge, paymentMonths, occupationalPaymentMonths, monthlySalary, bonus, desiredPensionStartAge) {
                // Template で計算を管理
                ref.read(pensionFormNotifierProvider.notifier).setCurrentAge(currentAge);
                ref.read(pensionFormNotifierProvider.notifier).setPaymentMonths(paymentMonths);
                ref.read(pensionFormNotifierProvider.notifier).setOccupationalPaymentMonths(occupationalPaymentMonths);
                ref.read(pensionFormNotifierProvider.notifier).setMonthlySalary(monthlySalary);
                ref.read(pensionFormNotifierProvider.notifier).setBonus(bonus);
                ref.read(pensionFormNotifierProvider.notifier).setDesiredPensionStartAge(desiredPensionStartAge);
                ref.read(pensionFormNotifierProvider.notifier).calculatePension();
              },
            ),
            // 結果タブ
            PensionResultDisplay(
              nationalPensionYearly: yearlyPension,
              nationalPensionMonthly: monthlyPension,
              contributionRate: rate,
              isLoading: formState.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
