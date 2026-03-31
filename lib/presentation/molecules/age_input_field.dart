import 'package:flutter/material.dart';

import '../atoms/input_field.dart';

/// 年齢入力フィールド Molecule
///
/// Atoms: InputField を使用した年齢専用入力フィールド
/// バリデーション: 0～120の整数のみ
class AgeInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final Function(int?)? onChanged;
  final TextEditingController? controller;

  const AgeInputField({
    super.key,
    this.label = '年齢',
    this.hintText = '例: 30',
    this.onChanged,
    this.controller,
  });

  @override
  State<AgeInputField> createState() => _AgeInputFieldState();
}

class _AgeInputFieldState extends State<AgeInputField> {
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

      final age = int.tryParse(value);
      if (age == null) {
        _errorText = '整数で入力してください';
        widget.onChanged?.call(null);
      } else if (age < 0 || age > 120) {
        _errorText = '0～120の範囲で入力してください';
        widget.onChanged?.call(null);
      } else {
        _errorText = null;
        widget.onChanged?.call(age);
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
