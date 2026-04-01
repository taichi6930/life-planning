import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../organisms/pension_result_table.dart';
import '../providers/pension_provider.dart';

/// 年齢別年金額テーブルページのテンプレート
///
/// プロバイダからグラフデータ（PensionByAgeData リスト）を取得し、
/// テーブル形式で表示する。月額/年額の切り替えトグルを持つ。
class PensionTableTemplate extends ConsumerStatefulWidget {
  const PensionTableTemplate({super.key});

  @override
  ConsumerState<PensionTableTemplate> createState() =>
      _PensionTableTemplateState();
}

class _PensionTableTemplateState extends ConsumerState<PensionTableTemplate> {
  bool _showAnnual = false;

  @override
  Widget build(BuildContext context) {
    final chartData = ref.watch(pensionByAgeChartProvider);
    final formState = ref.watch(pensionFormNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('年齢別年金額テーブル'),
      ),
      body: Column(
        children: [
          // 月額/年額切り替え
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('表示単位:'),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('月額')),
                    ButtonSegment(value: true, label: Text('年額')),
                  ],
                  selected: {_showAnnual},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _showAnnual = selected.first;
                    });
                  },
                ),
                const Spacer(),
                if (formState.result != null)
                  Text(
                    '受給開始: ${formState.desiredPensionStartAge}歳',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // テーブル本体
          Expanded(
            child: chartData == null || chartData.isEmpty
                ? Center(
                    child: Text(
                      '計算結果がありません。\nフォームで計算を実行してください。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  )
                : SingleChildScrollView(
                    child: PensionResultTable(
                      data: chartData,
                      showAnnual: _showAnnual,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
