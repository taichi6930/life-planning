import 'package:flutter/material.dart';

/// 基本的なテキスト入力フィールド
/// 
/// 数値入力や通常の入力フィールドの基盤となる Atom
class InputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? errorText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;

  const InputField({
    Key? key,
    required this.label,
    this.hintText,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.controller,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
