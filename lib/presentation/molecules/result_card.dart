import 'package:flutter/material.dart';

import '../atoms/result_text.dart';

/// 計算結果カード Molecule
/// 
/// Atoms: ResultText を複数使用して、年金計算結果を表示
class ResultCard extends StatelessWidget {
  final String title;
  final Map<String, String> results;
  final Map<String, String>? units;
  final bool isHighlight;

  const ResultCard({
    super.key,
    required this.title,
    required this.results,
    this.units,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isHighlight ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlight
            ? BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...results.entries.map((entry) {
              final unit = units?[entry.key];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ResultText(
                  label: entry.key,
                  value: entry.value,
                  unit: unit,
                  isHighlight: isHighlight,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
