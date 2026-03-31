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
  final Function(int currentAge, int paymentMonths, int occupationalPaymentMonths, int monthlySalary, int bonus, int desiredPensionStartAge, int idecoMonthlyContribution, double idecoAnnualReturnRate, int idecoCurrentBalance, int monthlyLivingExpenses, int targetAge)? onSubmit;
  final Function(int currentAge, int paymentMonths, int occupationalPaymentMonths, int monthlySalary, int bonus, int desiredPensionStartAge, int idecoMonthlyContribution, double idecoAnnualReturnRate, int idecoCurrentBalance, int monthlyLivingExpenses, int targetAge)? onFieldChanged;  // 自動計算用
  final bool isLoading;
  // フォーム初期値（プロバイダーから受け取る）
  final int? initialAge;
  final int? initialPaymentMonths;
  final int initialOccupationalPaymentMonths;
  final int initialMonthlySalary;
  final int initialBonus;
  final int initialDesiredPensionStartAge;
  final int initialIdecoMonthlyContribution;
  final double initialIdecoAnnualReturnRate;
  final int initialIdecoCurrentBalance;
  final int initialMonthlyLivingExpenses;
  final int initialTargetAge;

  /// 厚生年金加入月数の上限（ドメイン定数を外から渡す）
  final int maxOccupationalPaymentMonths;

  /// iDeCo月額拠出上限（自営業、ドメイン定数を外から渡す）
  final int maxIdecoMonthlyContribution;

  const PensionForm({
    super.key,
    this.onSubmit,
    this.onFieldChanged,
    this.isLoading = false,
    this.initialAge,
    this.initialPaymentMonths,
    this.initialOccupationalPaymentMonths = 0,
    this.initialMonthlySalary = 0,
    this.initialBonus = 0,
    this.initialDesiredPensionStartAge = 65,
    this.initialIdecoMonthlyContribution = 0,
    this.initialIdecoAnnualReturnRate = 3.0,
    this.initialIdecoCurrentBalance = 0,
    this.initialMonthlyLivingExpenses = 0,
    this.initialTargetAge = 90,
    this.maxOccupationalPaymentMonths = 600,
    this.maxIdecoMonthlyContribution = 75000,
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
  late int _idecoMonthlyContribution;
  late double _idecoAnnualReturnRate;
  late int _idecoCurrentBalance;
  late int _monthlyLivingExpenses;
  late int _targetAge;

  // TextEditingControllers for initial values display
  late TextEditingController _ageController;
  late TextEditingController _paymentMonthsController;
  late TextEditingController _occupationalPaymentMonthsController;
  late TextEditingController _monthlySalaryController;
  late TextEditingController _bonusController;
  late TextEditingController _idecoContributionController;
  late TextEditingController _idecoCurrentBalanceController;
  late TextEditingController _livingExpensesController;

  /// テキスト付きでコントローラーを生成し、カーソルを末尾に配置
  TextEditingController _createController(String text) {
    return TextEditingController(text: text)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
  }

  /// コントローラーのテキストを更新し、カーソルを末尾に配置
  void _updateController(TextEditingController controller, String text) {
    controller.text = text;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

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
    _idecoMonthlyContribution = widget.initialIdecoMonthlyContribution;
    _idecoAnnualReturnRate = widget.initialIdecoAnnualReturnRate;
    _idecoCurrentBalance = widget.initialIdecoCurrentBalance;
    _monthlyLivingExpenses = widget.initialMonthlyLivingExpenses;
    _targetAge = widget.initialTargetAge;
    
    // Initialize controllers with default values and cursor at end
    _ageController = _createController((widget.initialAge ?? 30).toString());
    _paymentMonthsController = _createController((widget.initialPaymentMonths ?? 480).toString());
    _occupationalPaymentMonthsController = _createController(widget.initialOccupationalPaymentMonths.toString());
    _monthlySalaryController = _createController(widget.initialMonthlySalary.toString());
    _bonusController = _createController(widget.initialBonus.toString());
    _idecoContributionController = _createController(widget.initialIdecoMonthlyContribution.toString());
    _idecoCurrentBalanceController = _createController(widget.initialIdecoCurrentBalance.toString());
    _livingExpensesController = _createController(widget.initialMonthlyLivingExpenses.toString());
    
    // 初期値で自動計算を実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyFieldChange();
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _paymentMonthsController.dispose();
    _occupationalPaymentMonthsController.dispose();
    _monthlySalaryController.dispose();
    _bonusController.dispose();
    _idecoContributionController.dispose();
    _idecoCurrentBalanceController.dispose();
    _livingExpensesController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PensionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // プロップが変更された場合、ローカル状態とコントローラーを更新
    if (oldWidget.initialAge != widget.initialAge) {
      setState(() {
        _age = widget.initialAge;
        _updateController(_ageController, (widget.initialAge ?? 30).toString());
      });
    }
    if (oldWidget.initialPaymentMonths != widget.initialPaymentMonths) {
      setState(() {
        _paymentMonths = widget.initialPaymentMonths;
        _updateController(_paymentMonthsController, (widget.initialPaymentMonths ?? 480).toString());
      });
    }
    if (oldWidget.initialOccupationalPaymentMonths !=
        widget.initialOccupationalPaymentMonths) {
      setState(() {
        _occupationalPaymentMonths = widget.initialOccupationalPaymentMonths;
        _updateController(_occupationalPaymentMonthsController, widget.initialOccupationalPaymentMonths.toString());
      });
    }
    if (oldWidget.initialMonthlySalary != widget.initialMonthlySalary) {
      setState(() {
        _monthlySalary = widget.initialMonthlySalary;
        _updateController(_monthlySalaryController, widget.initialMonthlySalary.toString());
      });
    }
    if (oldWidget.initialBonus != widget.initialBonus) {
      setState(() {
        _bonus = widget.initialBonus;
        _updateController(_bonusController, widget.initialBonus.toString());
      });
    }
    if (oldWidget.initialDesiredPensionStartAge !=
        widget.initialDesiredPensionStartAge) {
      setState(() => _desiredPensionStartAge = widget.initialDesiredPensionStartAge);
    }
    if (oldWidget.initialIdecoMonthlyContribution != widget.initialIdecoMonthlyContribution) {
      setState(() {
        _idecoMonthlyContribution = widget.initialIdecoMonthlyContribution;
        _updateController(_idecoContributionController, widget.initialIdecoMonthlyContribution.toString());
      });
    }
    if (oldWidget.initialIdecoCurrentBalance != widget.initialIdecoCurrentBalance) {
      setState(() {
        _idecoCurrentBalance = widget.initialIdecoCurrentBalance;
        _updateController(_idecoCurrentBalanceController, widget.initialIdecoCurrentBalance.toString());
      });
    }
    if (oldWidget.initialIdecoAnnualReturnRate != widget.initialIdecoAnnualReturnRate) {
      setState(() => _idecoAnnualReturnRate = widget.initialIdecoAnnualReturnRate);
    }
    if (oldWidget.initialMonthlyLivingExpenses != widget.initialMonthlyLivingExpenses) {
      setState(() {
        _monthlyLivingExpenses = widget.initialMonthlyLivingExpenses;
        _updateController(_livingExpensesController, widget.initialMonthlyLivingExpenses.toString());
      });
    }
    if (oldWidget.initialTargetAge != widget.initialTargetAge) {
      setState(() => _targetAge = widget.initialTargetAge);
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
    widget.onSubmit?.call(age, paymentMonths, occupationalPaymentMonths, monthlySalary, bonus, desiredPensionStartAge, _idecoMonthlyContribution, _idecoAnnualReturnRate, _idecoCurrentBalance, _monthlyLivingExpenses, _targetAge);
  }

  /// フィールド値が変更されたときに親に通知
  void _notifyFieldChange() {
    // 最低限、重要な5つのフィールドが揃っていれば計算を実行する
    // デフォルト値があるため、通常は常に揃っている
    if (_age != null && 
        _paymentMonths != null && 
        _occupationalPaymentMonths != null && 
        _monthlySalary != null && 
        _bonus != null && 
        _desiredPensionStartAge != null) {
      widget.onFieldChanged?.call(
        _age!,
        _paymentMonths!,
        _occupationalPaymentMonths!,
        _monthlySalary!,
        _bonus!,
        _desiredPensionStartAge!,
        _idecoMonthlyContribution,
        _idecoAnnualReturnRate,
        _idecoCurrentBalance,
        _monthlyLivingExpenses,
        _targetAge,
      );
    }
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
                        '$_desiredPensionStartAge歳',
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
                      setState(() {
                        _desiredPensionStartAge = value.toInt();
                        _notifyFieldChange();
                      });
                    },
                  ),
                ],
              ),
            ),
            AgeInputField(
              label: '現在の年齢',
              hintText: '例: 35',
              controller: _ageController,
              onChanged: (age) {
                setState(() {
                  _age = age;
                  _notifyFieldChange();
                });
              },
            ),
            const SizedBox(height: 20),
            PaymentMonthsInputField(
              label: '年金納付月数',
              hintText: '例: 360',
              controller: _paymentMonthsController,
              onChanged: (months) {
                setState(() {
                  _paymentMonths = months;
                  _notifyFieldChange();
                });
              },
            ),
            const SizedBox(height: 20),
            // 厚生年金加入月数
            TextField(
              controller: _occupationalPaymentMonthsController,
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
                if (months != null && months >= 0 && months <= widget.maxOccupationalPaymentMonths) {
                  setState(() {
                    _occupationalPaymentMonths = months;
                    _notifyFieldChange();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // 標準報酬月額
            TextField(
              controller: _monthlySalaryController,
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
                  setState(() {
                    _monthlySalary = salary;
                    _notifyFieldChange();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // 賞与（年額）
            TextField(
              controller: _bonusController,
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
                  setState(() {
                    _bonus = bonus;
                    _notifyFieldChange();
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            // === iDeCo セクション ===
            Divider(color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'iDeCo（個人型確定拠出年金）',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            // iDeCo 月額拠出額
            TextField(
              controller: _idecoContributionController,
              decoration: InputDecoration(
                labelText: 'iDeCo 月額拠出額',
                hintText: '例: 23000（加入しない場合は0）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('円'),
                helperText: '上限: 自営業75,000円 / 会社員62,000円（2026年12月改正予定）',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null && amount >= 0 && amount <= widget.maxIdecoMonthlyContribution) {
                  setState(() {
                    _idecoMonthlyContribution = amount;
                    _notifyFieldChange();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // iDeCo 現在の投資残高
            TextField(
              controller: _idecoCurrentBalanceController,
              decoration: InputDecoration(
                labelText: 'iDeCo 現在の投資残高',
                hintText: '例: 1000000（新規加入の場合は0）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('円'),
                helperText: '既にiDeCoで積み立てている場合の現在残高',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null && amount >= 0) {
                  setState(() {
                    _idecoCurrentBalance = amount;
                    _notifyFieldChange();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // iDeCo 想定利回りスライダー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'iDeCo 想定利回り',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${_idecoAnnualReturnRate.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _idecoAnnualReturnRate,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      _idecoAnnualReturnRate = double.parse(value.toStringAsFixed(1));
                      _notifyFieldChange();
                    });
                  },
                ),
                Text(
                  '0%: 元本保証型 / 3%: バランス型 / 5%以上: 株式中心',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 月額生活費
            TextField(
              controller: _livingExpensesController,
              decoration: InputDecoration(
                labelText: '月額生活費（老後の想定）',
                hintText: '例: 250000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('円'),
                helperText: '年金で賄えない分をiDeCoで補填します',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null && amount >= 0) {
                  setState(() {
                    _monthlyLivingExpenses = amount;
                    _notifyFieldChange();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // 想定寿命スライダー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '想定寿命',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$_targetAge歳',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _targetAge.toDouble(),
                  min: 75,
                  max: 100,
                  divisions: 25,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      _targetAge = value.toInt();
                      _notifyFieldChange();
                    });
                  },
                ),
                Text(
                  'iDeCoの積立金がこの年齢まで持つか判定します',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
