import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../molecules/pension_age_chart.dart';
import '../molecules/result_card.dart';
import '../providers/pension_provider.dart';

/// 計算結果表示 Organism
///
/// Riverpod プロバイダを直接 watch し、計算結果を自律的に描画する。
/// 親から結果値を props として受け取らず、provider の変更に反応する。
///
/// Molecules: ResultCard、PensionAgeChart を使用
class PensionResultDisplay extends ConsumerWidget {
  final bool isLoading;

  const PensionResultDisplay({
    super.key,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(pensionByAgeChartProvider);
    final formState = ref.watch(pensionFormNotifierProvider);
    final result = formState.result;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (result == null) {
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

    // 表示用の文字列整形（Widget 層で実施）
    final hasOccupationalPension = result.occupationalPensionMonthly > 0;
    final hasIdecoPension = result.idecoMonthly > 0;
    final hasShortfallAnalysis = result.monthlyLivingExpenses > 0 && result.idecoFutureValue > 0;
    final rate = ref.watch(contributionRateProvider);
    final rateText = rate != null ? '${(rate * 100).toStringAsFixed(1)}%' : '-';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PensionAgeChart(
              data: chartData,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),
            ResultCard(
              title: '基礎年金計算結果',
              results: {
                '年額': '¥${result.basicPensionAnnual.toStringAsFixed(0)}',
                '月額': '¥${result.basicPensionMonthly.toStringAsFixed(0)}',
              },
              units: const {
                '年額': '円',
                '月額': '円',
              },
              isHighlight: !hasOccupationalPension,
            ),
            if (hasOccupationalPension) ...[
              const SizedBox(height: 16),
              ResultCard(
                title: '厚生年金計算結果',
                results: {
                  '年額': '¥${result.occupationalPensionAnnual.toStringAsFixed(0)}',
                  '月額': '¥${result.occupationalPensionMonthly.toStringAsFixed(0)}',
                },
                units: const {
                  '年額': '円',
                  '月額': '円',
                },
              ),
            ],
            if (hasIdecoPension) ...[
              const SizedBox(height: 16),
              ResultCard(
                title: 'iDeCo 不足分補填',
                results: {
                  'iDeCo積立額': '¥${result.idecoFutureValue.toStringAsFixed(0)}',
                  '月額引出額': '¥${result.idecoMonthly.toStringAsFixed(0)}',
                },
                units: const {
                  'iDeCo積立額': '円',
                  '月額引出額': '円',
                },
              ),
            ],
            if (hasShortfallAnalysis) ...[
              const SizedBox(height: 16),
              ResultCard(
                title: '生活費充足判定',
                results: {
                  '月額生活費': '¥${result.monthlyLivingExpenses.toStringAsFixed(0)}',
                  '公的年金月額': '¥${result.publicPensionMonthly.toStringAsFixed(0)}',
                  '月額不足分': '¥${result.monthlyShortfall.toStringAsFixed(0)}',
                  'iDeCo枯渇年齢': result.idecoExhaustionAge.isInfinite ? '生涯枯渇なし' : '${result.idecoExhaustionAge.toStringAsFixed(1)}歳',
                  '想定寿命': '${result.targetAge}歳',
                  '判定': result.isIdecoSufficient ? '✅ 足りる' : '❌ 足りない',
                },
                units: const {
                  '月額生活費': '円',
                  '公的年金月額': '円',
                  '月額不足分': '円',
                },
                isHighlight: true,
              ),
            ],
            if (hasOccupationalPension || hasIdecoPension) ...[
              const SizedBox(height: 16),
              ResultCard(
                title: '合計年金額',
                results: {
                  '年額': '¥${result.totalPensionAnnual.toStringAsFixed(0)}',
                  '月額': '¥${result.totalPensionMonthly.toStringAsFixed(0)}',
                },
                units: const {
                  '年額': '円',
                  '月額': '円',
                },
                isHighlight: true,
              ),
            ],
            const SizedBox(height: 16),
            ResultCard(
              title: '計算条件',
              results: {
                '現在の年齢': '${formState.currentAge ?? '-'}歳',
                '年金納付月数': '${formState.paymentMonths ?? '-'}ヶ月',
                '厚生年金加入月数': '${formState.occupationalPaymentMonths}ヶ月',
                '受給開始年齢': '${formState.desiredPensionStartAge}歳',
              },
            ),
            const SizedBox(height: 16),
            ResultCard(
              title: '納付状況',
              results: {
                '納付率': rateText,
              },
            ),
          ],
        ),
      ),
    );
  }
}

