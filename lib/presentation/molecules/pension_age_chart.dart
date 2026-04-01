import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:life_planning/application/dtos/pension_by_age_data.dart';

/// 年齢別年金額の積み重ねた棒グラフ Molecule
///
/// 60歳から75歳までの受給開始年齢別に、基礎年金と厚生年金を
/// 積み重ねた棒グラフを表示
class PensionAgeChart extends StatelessWidget {
  final List<PensionByAgeData>? data;
  final bool isLoading;

  const PensionAgeChart({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (data == null || data!.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'グラフを表示するために計算してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // グラフの最大値を計算（生活費も考慮、余裕を持たせて120%）
    final hasLivingExpenses = data!.any((d) => d.monthlyLivingExpenses > 0);
    final maxPension = data!.map((d) => d.totalAnnual).reduce((a, b) => a > b ? a : b);
    final maxLiving = hasLivingExpenses
        ? data!.map((d) => d.monthlyLivingExpensesAnnual).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final maxValue = (maxPension > maxLiving ? maxPension : maxLiving) * 1.2;
    final livingExpensesAnnual = hasLivingExpenses ? data!.first.monthlyLivingExpensesAnnual : 0.0;

    // BarChart のデータ作成（積み上げ棒グラフ）
    final barGroups = data!.map((d) {
      final ageIndex = data!.indexOf(d);
      final basicAnnual = d.basicPensionAnnual;
      final occupationalAnnual = d.occupationalPensionAnnual;
      final idecoAnnual = d.idecoAnnual;
      final investmentTrustAnnual = d.investmentTrustAnnual;
      final totalAnnual = d.totalAnnual;
      final base2 = basicAnnual + occupationalAnnual;
      final base3 = base2 + idecoAnnual;
      return BarChartGroupData(
        x: ageIndex,
        barRods: [
          BarChartRodData(
            toY: totalAnnual,
            color: Colors.blue,
            width: 12, // さらに狭くしてギュッと詰める
            borderRadius: const BorderRadius.all(Radius.circular(4)), // 角を丸くして滑らかに
            rodStackItems: [
              BarChartRodStackItem(0, basicAnnual, Colors.blue),
              BarChartRodStackItem(basicAnnual, base2, Colors.orange),
              BarChartRodStackItem(base2, base3, Colors.green),
              if (investmentTrustAnnual > 0)
                BarChartRodStackItem(base3, base3 + investmentTrustAnnual, Colors.deepPurple),
            ],
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '生涯年金額の推移（年額）',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${data!.first.age}歳からの年金額を表示します（受給開始年齢前は0円）',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                groupsSpace: 2, // バー間のスペースを狭くしてギュッと詰める
                alignment: BarChartAlignment.spaceEvenly,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (hasLivingExpenses)
                      HorizontalLine(
                        y: livingExpensesAnnual,
                        color: Colors.red,
                        strokeWidth: 2,
                        dashArray: [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (line) => '生活費 ¥${(livingExpensesAnnual / 10000).toStringAsFixed(0)}万',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    // coverage:ignore-start
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final age = data![groupIndex].age;
                      final d = data![groupIndex];
                      
                      var tooltipText = '$age歳\n基礎年金: ¥${d.basicPensionAnnual.toStringAsFixed(0)}\n厚生年金: ¥${d.occupationalPensionAnnual.toStringAsFixed(0)}';
                      if (d.idecoMonthly > 0) {
                        tooltipText += '\niDeCo: ¥${d.idecoAnnual.toStringAsFixed(0)}';
                      }
                      if (d.investmentTrustMonthly > 0) {
                        tooltipText += '\n投資信託: ¥${d.investmentTrustAnnual.toStringAsFixed(0)}';
                      }
                      tooltipText += '\n合計: ¥${d.totalAnnual.toStringAsFixed(0)}';
                      
                      return BarTooltipItem(
                        tooltipText,
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                    // coverage:ignore-end
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data!.length) {
                          return const Text('');
                        }
                        final age = data![index].age;
                        // 5年刻みで表示
                        if (age % 5 == 0) {
                          return Text(
                            '$age',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text('0', style: TextStyle(fontSize: 10));
                        }
                        if (value == meta.max) {
                          return Text(
                            '¥${(value / 10000).toStringAsFixed(0)}万',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 60,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 5,
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // レジェンド
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(Colors.blue, '基礎年金'),
              _buildLegendItem(Colors.orange, '厚生年金'),
              _buildLegendItem(Colors.green, 'iDeCo'),
              _buildLegendItem(Colors.deepPurple, '投資信託'),
              if (hasLivingExpenses)
                _buildLegendItem(Colors.red, '生活費'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '※ グラフは各年齢で受給開始した場合の年額を表示します',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// レジェンド項目ウィジェット
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
