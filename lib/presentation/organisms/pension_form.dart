import 'package:flutter/material.dart';

import '../atoms/button.dart';
import '../molecules/age_input_field.dart';
import '../molecules/payment_months_input_field.dart';

/// 年金計算フォーム Organism
/// 
/// Molecules: AgeInputField, PaymentMonthsInputField を組み合わせた
/// 年金計算用のフォーム UI
/// 
/// 責務: UI のみ。計算ロジックは親（Template）に委譲
class PensionForm extends StatefulWidget {
  final Function(int currentAge, int paymentMonths, int occupationalPaymentMonths, int monthlySalary, int bonus, int desiredPensionStartAge)? onSubmit;
  final bool isLoading;
  // フォーム初期値（プロバイダーから受け取る）
  final int? initialAge;
  final int? initialPaymentMonths;
  final int initialOccupationalPaymentMonths;
  final int initialMonthlySalary;
  final int initialBonus;
  final int initialDesiredPensionStartAge;

  const PensionForm({
    super.key,
    this.onSubmit,
    this.isLoading = false,
    this.initialAge,
    this.initialPaymentMonths,
    this.initialOccupationalPaymentMonths = 0,
    this.initialMonthlySalary = 0,
    this.initialBonus = 0,
    this.initialDesiredPensionStartAge = 65,
  });

  @override
  State<PensionForm> createState() => _PensionFormState();
}

class _PensionFormState extends State<PensionForm> {
  late int? _desiredPensionStartAge;
  late int? _age;
  late int? _paymentMonths;
  late int? _occupationalPaymentMonths;
  late int? _monthlySalary;
  late int? _bonus;

  @override
  void initState() {
    super.initState();
    // 初期値をプロップから設定
    _desiredPensionStartAge = widget.initialDesiredPensionStartAge;
    _age = widget.initialAge;
    _paymentMonths = widget.initialPaymentMonths;
    _occupationalPaymentMonths = widget.initialOccupationalPaymentMonths;
    _monthlySalary = widget.initialMonthlySalary;
    _bonus = widget.initialBonus;
  }

  @override
  void didUpdateWidget(PensionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // プロップが変更された場合、ローカル状態を更新
    if (oldWidget.initialAge != widget.initialAge) {
      setState(() => _age = widget.initialAge);
    }
    if (oldWidget.initialPaymentMonths != widget.initialPaymentMonths) {
      setState(() => _paymentMonths = widget.initialPaymentMonths);
    }
    if (oldWidget.initialOccupationalPaymentMonths != widget.initialOccupationalPaymentMonths) {
      setState(() => _occupationalPaymentMonths = widget.initialOccupationalPaymentMonths);
    }
    if (oldWidget.initialMonthlySalary != widget.initialMonthlySalary) {
      setState(() => _monthlySalary = widget.initialMonthlySalary);
    }
    if (oldWidget.initialBonus != widget.initialBonus) {
      setState(() => _bonus = widget.initialBonus);
    }
    if (oldWidget.initialDesiredPensionStartAge != widget.initialDesiredPensionStartAge) {
      setState(() => _desiredPensionStartAge = widget.initialDesiredPensionStartAge);
    }
  }

  void _handleSubmit() {
    if (_age == null || _paymentMonths == null || _occupationalPaymentMonths == null || _monthlySalary == null || _bonus == null || _desiredPensionStartAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('すべてのフィールドを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // null チェック後、local 変数に代入（Dart null safety対応）
    final age = _age!;
    final paymentMonths = _paymentMonths!;
    final occupationalPaymentMonths = _occupationalPaymentMonths!;
    final monthlySalary = _monthlySalary!;
    final bonus = _bonus!;
    final desiredPensionStartAge = _desiredPensionStartAge!;
    // コールバックを呼ぶ（親に処理を委譲）
    widget.onSubmit?.call(age, paymentMonths, occupationalPaymentMonths, monthlySalary, bonus, desiredPensionStartAge);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 受給開始年齢の選択（スライダー）
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '受給開始年齢',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_desiredPensionStartAge}歳',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _desiredPensionStartAge?.toDouble() ?? 65.0,
                    min: 60,
                    max: 75,
                    divisions: 15,
                    onChanged: (value) {
                      setState(() => _desiredPensionStartAge = value.toInt());
                    },
                  ),
                ],
              ),
            ),
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
            const SizedBox(height: 20),
            // 厚生年金加入月数
            TextField(
              decoration: InputDecoration(
                labelText: '厚生年金加入月数',
                hintText: '例: 360（加入していない場合は0）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('月'),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final months = int.tryParse(value);
                if (months != null && months >= 0 && months <= 600) {
                  setState(() => _occupationalPaymentMonths = months);
                }
              },
            ),
            const SizedBox(height: 20),
            // 標準報酬月額
            TextField(
              decoration: InputDecoration(
                labelText: '標準報酬月額（給与）',
                hintText: '例: 300000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('円'),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final salary = int.tryParse(value);
                if (salary != null && salary >= 0) {
                  setState(() => _monthlySalary = salary);
                }
              },
            ),
            const SizedBox(height: 20),
            // 賞与（年額）
            TextField(
              decoration: InputDecoration(
                labelText: '賞与（年額）',
                hintText: '例: 500000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('円'),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final bonus = int.tryParse(value);
                if (bonus != null && bonus >= 0) {
                  setState(() => _bonus = bonus);
                }
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
