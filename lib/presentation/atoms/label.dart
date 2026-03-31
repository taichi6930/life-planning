import 'package:flutter/material.dart';

/// テキストラベル Atom
///
/// 異なるサイズと色をサポート
class Label extends StatelessWidget {
  final String text;
  final LabelSize size;
  final LabelColor color;
  final TextAlign textAlign;
  final int? maxLines;

  const Label(
    this.text, {
    super.key,
    this.size = LabelSize.medium,
    this.color = LabelColor.primary,
    this.textAlign = TextAlign.left,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: _buildTextStyle(context),
    );
  }

  TextStyle _buildTextStyle(BuildContext context) {
    final baseStyle = _getBaseStyle(context);
    final textColor = _getColor(context);
    return baseStyle.copyWith(color: textColor);
  }

  TextStyle _getBaseStyle(BuildContext context) {
    switch (size) {
      case LabelSize.small:
        return Theme.of(context).textTheme.labelSmall ?? const TextStyle();
      case LabelSize.medium:
        return Theme.of(context).textTheme.labelMedium ?? const TextStyle();
      case LabelSize.large:
        return Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    }
  }

  Color _getColor(BuildContext context) {
    switch (color) {
      case LabelColor.primary:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
      case LabelColor.secondary:
        return Colors.grey[600] ?? Colors.grey;
      case LabelColor.error:
        return Colors.red;
      case LabelColor.success:
        return Colors.green;
    }
  }
}

enum LabelSize {
  small,
  medium,
  large,
}

enum LabelColor {
  primary,
  secondary,
  error,
  success,
}
