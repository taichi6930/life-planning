import 'package:flutter/material.dart';

import '../atoms/button.dart';
import '../molecules/age_input_field.dart';
import '../molecules/payment_months_input_field.dart';

/// 年金計算フォーム Organism
/// 
/// Molecules: AgeInputField, PaymentMonthsInputField を組み合わせた
/// 年金計算用のフォーム UI
class PensionForm extends StatefulWidget {
  final Function(int? age, int? paymentMonths)? onSubmit;
  final bool isLoading;

  const PensionForm({
    super.key,
    this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<PensionForm> createState() => _PensionFormState();
}

class _PensionFormState extends State<PensionForm> {
  int? _age;
  int? _paymentMonths;

  void _handleSubmit() {
    if (_age == null || _paymentMonths == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('すべてのフィールドを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    widget.onSubmit?.call(_age, _paymentMonths);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AgeInputField(
              label: '現在の年齢',
              hintText: '例: 35',
              onChanged: (age) {
                setState(() => _age = age);
              },
            ),
            const SizedBox(height: 20),
            PaymentMonthsInputField(
              label: '年金納付月数',
              hintText: '例: 360',
              onChanged: (months) {
                setState(() => _paymentMonths = months);
              },
            ),
            const SizedBox(height: 32),
            Button(
              label: '計算する',
              onPressed: _handleSubmit,
              isLoading: widget.isLoading,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}
