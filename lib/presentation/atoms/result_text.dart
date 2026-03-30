import 'package:flutter/material.dart';

/// 計算結果を表示するテキスト Atom
/// 
/// 数値結果を適切なフォーマットで表示
class ResultText extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final ResultTextSize size;
  final bool isHighlight;

  const ResultText({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.size = ResultTextSize.medium,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColorWithOpacity(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: _buildValueStyle(context),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _buildValueStyle(BuildContext context) {
    switch (size) {
      case ResultTextSize.small:
        return Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
      case ResultTextSize.medium:
        return Theme.of(context).textTheme.headlineSmall ??
            const TextStyle(fontSize: 20);
      case ResultTextSize.large:
        return Theme.of(context).textTheme.headlineMedium ??
            const TextStyle(fontSize: 28);
    }
  }
  Color? _getBackgroundColorWithOpacity(BuildContext context) {
    return isHighlight
        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
        : Colors.transparent;
  }}

enum ResultTextSize {
  small,
  medium,
  large,
}
