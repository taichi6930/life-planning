import 'package:flutter/material.dart';

import '../../application/dtos/pension_by_age_data.dart';

/// 年齢別年金額テーブル Organism
///
/// [PensionByAgeData] リストをデータテーブル形式で表示する。
/// 列: 年齢、基礎年金、厚生年金、iDeCo、投資信託、合計、生活費
class PensionResultTable extends StatelessWidget {
  final List<PensionByAgeData> data;
  final bool showAnnual;

  const PensionResultTable({
    super.key,
    required this.data,
    this.showAnnual = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'データがありません',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }

    final hasOccupational = data.any((d) => d.occupationalPensionMonthly > 0);
    final hasIdeco = data.any((d) => d.idecoMonthly > 0);
    final hasInvestmentTrust = data.any((d) => d.investmentTrustMonthly > 0);
    final hasLivingExpenses = data.any((d) => d.monthlyLivingExpenses > 0);
    final hasIdecoBalance = data.any((d) => d.idecoBalance > 0);
    final hasInvestmentTrustBalance = data.any((d) => d.investmentTrustBalance > 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
        columns: [
          const DataColumn(label: Text('年齢')),
          DataColumn(
            label: Text(showAnnual ? '基礎年金\n(年額)' : '基礎年金\n(月額)'),
            numeric: true,
          ),
          if (hasOccupational)
            DataColumn(
              label: Text(showAnnual ? '厚生年金\n(年額)' : '厚生年金\n(月額)'),
              numeric: true,
            ),
          if (hasIdeco) ...[
            DataColumn(
              label: Text(showAnnual ? 'iDeCo\n(年額)' : 'iDeCo\n(月額)'),
              numeric: true,
            ),
            if (hasIdecoBalance)
              const DataColumn(
                label: Text('iDeCo\n残高'),
                numeric: true,
              ),
            if (hasIdecoBalance)
              const DataColumn(
                label: Text('iDeCo\n運用益'),
                numeric: true,
              ),
          ],
          if (hasInvestmentTrust) ...[
            DataColumn(
              label: Text(showAnnual ? '投資信託\n(年額)' : '投資信託\n(月額)'),
              numeric: true,
            ),
            if (hasInvestmentTrustBalance)
              const DataColumn(
                label: Text('投資信託\n残高'),
                numeric: true,
              ),
            if (hasInvestmentTrustBalance)
              const DataColumn(
                label: Text('投資信託\n運用益'),
                numeric: true,
              ),
          ],
          DataColumn(
            label: Text(showAnnual ? '合計\n(年額)' : '合計\n(月額)'),
            numeric: true,
          ),
          if (hasLivingExpenses)
            DataColumn(
              label: Text(showAnnual ? '生活費\n(年額)' : '生活費\n(月額)'),
              numeric: true,
            ),
          if (hasLivingExpenses)
            DataColumn(
              label: Text(showAnnual ? '過不足\n(年額)' : '過不足\n(月額)'),
              numeric: true,
            ),
        ],
        rows: data.map((d) {
          final basic =
              showAnnual ? d.basicPensionAnnual : d.basicPensionMonthly;
          final occupational = showAnnual
              ? d.occupationalPensionAnnual
              : d.occupationalPensionMonthly;
          final ideco = showAnnual ? d.idecoAnnual : d.idecoMonthly;
          final investmentTrust =
              showAnnual ? d.investmentTrustAnnual : d.investmentTrustMonthly;
          final total = showAnnual ? d.totalAnnual : d.totalMonthly;
          final livingExpenses = showAnnual
              ? d.monthlyLivingExpensesAnnual
              : d.monthlyLivingExpenses;
          final surplus = total - livingExpenses;

          return DataRow(
            cells: [
              DataCell(Text('${d.age}歳')),
              DataCell(Text(_formatCurrency(basic))),
              if (hasOccupational)
                DataCell(Text(_formatCurrency(occupational))),
              if (hasIdeco) ...[
                DataCell(Text(_formatCurrency(ideco))),
                if (hasIdecoBalance)
                  DataCell(Text(_formatCurrency(d.idecoBalance))),
                if (hasIdecoBalance)
                  DataCell(
                    Text(
                      _formatCurrency(d.idecoGain),
                      style: TextStyle(
                        color: d.idecoGain >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
              ],
              if (hasInvestmentTrust) ...[
                DataCell(Text(_formatCurrency(investmentTrust))),
                if (hasInvestmentTrustBalance)
                  DataCell(Text(_formatCurrency(d.investmentTrustBalance))),
                if (hasInvestmentTrustBalance)
                  DataCell(
                    Text(
                      _formatCurrency(d.investmentTrustGain),
                      style: TextStyle(
                        color: d.investmentTrustGain >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ),
              ],
              DataCell(
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (hasLivingExpenses)
                DataCell(Text(_formatCurrency(livingExpenses))),
              if (hasLivingExpenses)
                DataCell(
                  Text(
                    _formatCurrency(surplus),
                    style: TextStyle(
                      color: surplus >= 0 ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value == 0) return '-';
    final intValue = value.round();
    // 3桁区切りのカンマ
    final text = intValue.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return intValue < 0 ? '-¥$buffer' : '¥$buffer';
  }
}
