import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../organisms/pension_form.dart';
import '../organisms/pension_result_display.dart';
import '../providers/pension_provider.dart';

/// 年金計算ページのテンプレート
/// 
/// フォーム入力と結果表示を組み合わせたレイアウト
class PensionFormTemplate extends ConsumerWidget {
  final String title;

  const PensionFormTemplate({
    Key? key,
    this.title = '年金計算',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: Text(title),
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
              onSubmit: (age, months) {
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
        appBar: TabBar(
          tabs: const [
            Tab(text: 'フォーム'),
            Tab(text: '結果'),
          ],
        ),
        body: TabBarView(
          children: [
            // フォームタブ
            PensionForm(
              isLoading: formState.isLoading,
              onSubmit: (age, months) {
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
