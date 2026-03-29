import 'package:flutter/material.dart';

import '../atoms/input_field.dart';

/// 納付月数入力フィールド Molecule
/// 
/// Atoms: InputField を使用した納付月数専用入力フィールド
/// バリデーション: 0～480の整数のみ（40年分を想定）
class PaymentMonthsInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final Function(int?)? onChanged;
  final TextEditingController? controller;
  final int maxMonths;

  const PaymentMonthsInputField({
    super.key,
    this.label = '年金納付月数',
    this.hintText = '例: 360',
    this.onChanged,
    this.controller,
    this.maxMonths = 480,
  });

  @override
  State<PaymentMonthsInputField> createState() =>
      _PaymentMonthsInputFieldState();
}

class _PaymentMonthsInputFieldState extends State<PaymentMonthsInputField> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validateAndUpdate(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = null;
        widget.onChanged?.call(null);
        return;
      }

      final months = int.tryParse(value);
      if (months == null) {
        _errorText = '整数で入力してください';
        widget.onChanged?.call(null);
      } else if (months < 0 || months > widget.maxMonths) {
        _errorText = '0～${widget.maxMonths}の範囲で入力してください';
        widget.onChanged?.call(null);
      } else {
        _errorText = null;
        widget.onChanged?.call(months);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InputField(
      label: widget.label,
      hintText: widget.hintText,
      errorText: _errorText,
      keyboardType: TextInputType.number,
      controller: _controller,
      onChanged: _validateAndUpdate,
    );
  }
}
