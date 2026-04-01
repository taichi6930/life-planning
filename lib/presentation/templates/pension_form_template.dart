import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/dtos/pension_by_age_data.dart';
import '../../application/dtos/pension_form_values.dart';
import '../../data/pension_local_storage.dart';
import '../../domain/values/ideco_input.dart';
import '../../domain/values/occupational_pension_input.dart';
import '../organisms/pension_form.dart';
import '../organisms/pension_result_display.dart';
import '../pages/pension_table_page.dart';
import '../providers/pension_provider.dart';

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
    notifier.setIdecoMonthlyContribution(savedData.idecoMonthlyContribution);
    notifier.setIdecoAnnualReturnRate(savedData.idecoAnnualReturnRate);
    notifier.setIdecoCurrentBalance(savedData.idecoCurrentBalance);
    notifier.setMonthlyLivingExpenses(savedData.monthlyLivingExpenses);
    notifier.setTargetAge(savedData.targetAge);
    notifier.setInvestmentTrustMonthlyContribution(savedData.investmentTrustMonthlyContribution);
    notifier.setInvestmentTrustCurrentAge(savedData.investmentTrustCurrentAge);
    notifier.setInvestmentTrustAnnualReturnRate(savedData.investmentTrustAnnualReturnRate);
    notifier.setInvestmentTrustWithdrawalStartAge(savedData.investmentTrustWithdrawalStartAge);
    notifier.setInvestmentTrustCurrentBalance(savedData.investmentTrustCurrentBalance);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(pensionFormNotifierProvider);
    final chartData = ref.watch(pensionByAgeChartProvider);
    final contributionRate = ref.watch(contributionRateProvider);

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
              ? _buildWideLayout(ref, formState, chartData, contributionRate)
              : _buildNarrowLayout(ref, formState, chartData, contributionRate),
        );
      },
    );
  }

  /// 広い画面用レイアウト（横並び）
  Widget _buildWideLayout(
    WidgetRef ref,
    PensionFormState formState,
    List<PensionByAgeData>? chartData,
    double? contributionRate,
  ) {
    return Row(
      children: [
        // 左側：フォーム
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _buildForm(ref, formState),
          ),
        ),
        // 右側：結果表示
        Expanded(
          child: SingleChildScrollView(
            child: _buildResult(formState, chartData, contributionRate),
          ),
        ),
      ],
    );
  }

  /// 狭い画面用レイアウト（縦並び、タブ）
  Widget _buildNarrowLayout(
    WidgetRef ref,
    PensionFormState formState,
    List<PensionByAgeData>? chartData,
    double? contributionRate,
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
            // フォームタブ（フォーム + 結果プレビュー）
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildForm(ref, formState),
                  // 結果表示（フォーム下）
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildResult(formState, chartData, contributionRate),
                  ),
                ],
              ),
            ),
            // 結果タブ（詳細表示用）
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildResult(formState, chartData, contributionRate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// フォーム値を Provider に反映して計算を実行
  void _updateAndCalculate(PensionFormValues values) {
    final notifier = ref.read(pensionFormNotifierProvider.notifier);
    notifier.setCurrentAge(values.currentAge);
    notifier.setPaymentMonths(values.paymentMonths);
    notifier.setOccupationalPaymentMonths(values.occupationalPaymentMonths);
    notifier.setMonthlySalary(values.monthlySalary);
    notifier.setBonus(values.bonus);
    notifier.setDesiredPensionStartAge(values.desiredPensionStartAge);
    notifier.setIdecoMonthlyContribution(values.idecoMonthlyContribution);
    notifier.setIdecoAnnualReturnRate(values.idecoAnnualReturnRate);
    notifier.setIdecoCurrentBalance(values.idecoCurrentBalance);
    notifier.setMonthlyLivingExpenses(values.monthlyLivingExpenses);
    notifier.setTargetAge(values.targetAge);
    notifier.setInvestmentTrustMonthlyContribution(values.investmentTrustMonthlyContribution);
    notifier.setInvestmentTrustCurrentAge(values.investmentTrustCurrentAge);
    notifier.setInvestmentTrustAnnualReturnRate(values.investmentTrustAnnualReturnRate);
    notifier.setInvestmentTrustWithdrawalStartAge(values.investmentTrustWithdrawalStartAge);
    notifier.setInvestmentTrustCurrentBalance(values.investmentTrustCurrentBalance);
    notifier.calculatePension();
  }

  /// 結果表示 Widgetを構築する
  ///
  /// provider 由来のデータを Temple が受け取り、PensionResultDisplay に渡す。
  Widget _buildResult(
    PensionFormState formState,
    List<PensionByAgeData>? chartData,
    double? contributionRate,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PensionResultDisplay(
          isLoading: formState.isLoading,
          result: formState.result,
          chartData: chartData,
          contributionRate: contributionRate,
          currentAge: formState.currentAge,
          paymentMonths: formState.paymentMonths,
          occupationalPaymentMonths: formState.occupationalPaymentMonths,
          desiredPensionStartAge: formState.desiredPensionStartAge,
        ),
        if (formState.result != null && chartData != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PensionTablePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.table_chart),
                label: const Text('テーブルで詳細を見る'),
              ),
            ),
          ),
      ],
    );
  }

  /// 入力フォーム Widget
  ///
  /// 共通化。素直にプロバイダに値を渡す。
  Widget _buildForm(WidgetRef ref, PensionFormState formState) {
    return PensionForm(
      isLoading: formState.isLoading,
      initialAge: formState.currentAge ?? 30,
      initialPaymentMonths: formState.paymentMonths ?? 480,
      initialOccupationalPaymentMonths: formState.occupationalPaymentMonths,
      initialMonthlySalary: formState.monthlySalary ?? 0,
      initialBonus: formState.bonus ?? 0,
      initialDesiredPensionStartAge: formState.desiredPensionStartAge,
      initialIdecoMonthlyContribution: formState.idecoMonthlyContribution,
      initialIdecoAnnualReturnRate: formState.idecoAnnualReturnRate,
      initialIdecoCurrentBalance: formState.idecoCurrentBalance,
      initialMonthlyLivingExpenses: formState.monthlyLivingExpenses,
      initialTargetAge: formState.targetAge,
      initialInvestmentTrustMonthlyContribution: formState.investmentTrustMonthlyContribution,
      initialInvestmentTrustCurrentAge: formState.investmentTrustCurrentAge,
      initialInvestmentTrustAnnualReturnRate: formState.investmentTrustAnnualReturnRate,
      initialInvestmentTrustWithdrawalStartAge: formState.investmentTrustWithdrawalStartAge,
      initialInvestmentTrustCurrentBalance: formState.investmentTrustCurrentBalance,
      onSubmit: _updateAndCalculate,
      onFieldChanged: _updateAndCalculate,
      maxOccupationalPaymentMonths: OccupationalPensionInput.maxEnrollmentMonths,
      maxIdecoMonthlyContribution: IdecoInput.maxMonthlyContributionSelfEmployed,
    );
  }
}
