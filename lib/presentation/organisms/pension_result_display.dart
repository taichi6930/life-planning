import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../molecules/pension_age_chart.dart';
import '../molecules/result_card.dart';
import '../providers/pension_provider.dart';

/// 計算結果表示 Organism
/// 
/// Molecules: ResultCard、PensionAgeChart を使用して、計算結果を表示
class PensionResultDisplay extends ConsumerWidget {
  final String? nationalPensionYearly;
  final String? nationalPensionMonthly;
  final double? contributionRate;
  final bool isLoading;

  const PensionResultDisplay({
    super.key,
    this.nationalPensionYearly,
    this.nationalPensionMonthly,
    this.contributionRate,
    this.isLoading = false,
  });

  bool get _hasResults =>
      nationalPensionYearly != null ||
      nationalPensionMonthly != null ||
      contributionRate != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(pensionByAgeChartProvider);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'フォームを入力して「計算する」ボタンを押してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResultCard(
              title: '基礎年金計算結果',
              results: {
                '年額': nationalPensionYearly ?? '-',
                '月額': nationalPensionMonthly ?? '-',
              },
              units: const {
                '年額': '円',
                '月額': '円',
              },
              isHighlight: true,
            ),
            const SizedBox(height: 16),
            ResultCard(
              title: '納付状況',
              results: {
                '納付率': contributionRate != null
                    ? '${(contributionRate! * 100).toStringAsFixed(1)}%'
                    : '-',
              },
            ),
            const SizedBox(height: 24),
            // グラフを追加
            PensionAgeChart(
              data: chartData,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
